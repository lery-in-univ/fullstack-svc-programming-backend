import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UnauthorizedException } from '@nestjs/common';
import Docker from 'dockerode';
import { LanguageServerService } from './language-server.service';
import { TokenManager } from '../util/token-manager';
import type { Requester } from '../auth/requester.decorator';

interface ClientSession {
  sessionId: string;
  userId: string;
  stream: any;
}

@WebSocketGateway({ cors: true, namespace: '/lsp' })
export class LanguageServerGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(LanguageServerGateway.name);
  private readonly docker: Docker;
  private readonly clientSessions = new Map<string, ClientSession>();

  constructor(
    private readonly languageServerService: LanguageServerService,
    private readonly tokenManager: TokenManager,
  ) {
    this.docker = new Docker({ socketPath: '/var/run/docker.sock' });
  }

  handleConnection(client: Socket) {
    try {
      const token: string =
        client.handshake.auth.token ?? client.handshake.headers.authorization;

      if (!token) {
        throw new UnauthorizedException('No token provided');
      }

      const tokenString = token.replace('Bearer ', '');
      const payload = this.tokenManager.verify<Requester>(tokenString);

      client.data.userId = payload.userId;
      this.logger.log(
        `Client connected: ${client.id}, userId: ${payload.userId}`,
      );
    } catch (error) {
      this.logger.error('Connection authentication failed', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const session = this.clientSessions.get(client.id);
    if (session?.stream) {
      session.stream.destroy();
    }
    this.clientSessions.delete(client.id);
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('lsp-connect')
  async handleLSPConnect(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    try {
      const { sessionId } = payload;
      const userId: string = client.data.userId;

      const isOwner = await this.languageServerService.validateSessionOwnership(
        sessionId,
        userId,
      );
      if (!isOwner) {
        client.emit('lsp-error', {
          error: 'Session not found or access denied',
          code: 403,
        });
        return;
      }

      const containerId =
        await this.languageServerService.getContainerId(sessionId);
      if (!containerId) {
        client.emit('lsp-error', { error: 'Container not ready', code: 404 });
        return;
      }

      const container = this.docker.getContainer(containerId);
      const stream = await container.attach({
        stream: true,
        stdin: true,
        stdout: true,
        stderr: true,
        hijack: true,
      });

      this.clientSessions.set(client.id, {
        sessionId,
        userId,
        stream,
      });

      stream.on('data', (chunk: Buffer) => {
        const message = this.demuxDockerStream(chunk);
        if (message) {
          client.emit('lsp-message', { message });
        }
      });

      stream.on('error', (error) => {
        this.logger.error(`Stream error for session ${sessionId}`, error);
        client.emit('lsp-error', { error: 'Stream error', code: 500 });
      });

      stream.on('end', () => {
        this.logger.log(`Stream ended for session ${sessionId}`);
        client.emit('lsp-disconnected', { reason: 'Container stopped' });
      });

      await this.languageServerService.updateLastActivity(sessionId);

      client.emit('lsp-connected', { success: true, sessionId });
      this.logger.log(
        `LSP connected: client ${client.id}, session ${sessionId}`,
      );
    } catch (error) {
      this.logger.error('Failed to connect to LSP', error);
      client.emit('lsp-error', { error: 'Failed to connect', code: 500 });
    }
  }

  @SubscribeMessage('lsp-message')
  async handleLSPMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { message: string },
  ) {
    try {
      const session = this.clientSessions.get(client.id);
      if (!session?.stream) {
        client.emit('lsp-error', { error: 'Not connected', code: 400 });
        return;
      }

      session.stream.write(payload.message);
      await this.languageServerService.updateLastActivity(session.sessionId);
    } catch (error) {
      this.logger.error('Failed to send message to LSP', error);
      client.emit('lsp-error', { error: 'Failed to send message', code: 500 });
    }
  }

  private demuxDockerStream(chunk: Buffer): string | null {
    if (chunk.length < 8) {
      return chunk.toString();
    }

    const header = chunk.readUInt8(0);
    if (header > 2) {
      return chunk.toString();
    }

    const size = chunk.readUInt32BE(4);
    const payload = chunk.slice(8, 8 + size);
    return payload.toString();
  }
}
