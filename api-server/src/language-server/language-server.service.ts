import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  OnModuleDestroy,
} from '@nestjs/common';
import Redis from 'ioredis';
import { ulid } from 'ulid';
import { promises as fs } from 'fs';
import { join } from 'path';
import { CreateSessionResponseDto } from './dto/create-session-response.dto';

interface SessionData {
  userId: string;
  containerId?: string;
  containerName?: string;
  createdAt: string;
  lastActivity?: string;
  uploadedFiles?: string[];
  workspaceRoot?: string;
}

@Injectable()
export class LanguageServerService implements OnModuleDestroy {
  private readonly redis: Redis;
  private readonly SESSION_TTL = 600;

  constructor() {
    this.redis = new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379', 10),
    });
  }

  async onModuleDestroy() {
    await this.redis.quit();
  }

  async createSession(userId: string): Promise<CreateSessionResponseDto> {
    const sessionId = ulid();
    const sessionData: SessionData = {
      userId,
      createdAt: new Date().toISOString(),
      workspaceRoot: `/lsp-files/${sessionId}`,
    };

    await this.redis.setex(
      `lsp:session:${sessionId}`,
      this.SESSION_TTL,
      JSON.stringify(sessionData),
    );

    return { sessionId };
  }

  async renewSession(sessionId: string, userId: string): Promise<void> {
    const key = `lsp:session:${sessionId}`;
    const data = await this.redis.get(key);

    if (!data) {
      throw new NotFoundException('Session not found');
    }

    const sessionData = JSON.parse(data) as SessionData;

    if (sessionData.userId !== userId) {
      throw new ForbiddenException('Session does not belong to user');
    }

    await this.redis.expire(key, this.SESSION_TTL);
  }

  async getSession(sessionId: string): Promise<SessionData | null> {
    const data = await this.redis.get(`lsp:session:${sessionId}`);
    return data ? (JSON.parse(data) as SessionData) : null;
  }

  async updateSessionContainer(
    sessionId: string,
    containerId: string,
  ): Promise<void> {
    const key = `lsp:session:${sessionId}`;
    const data = await this.redis.get(key);

    if (!data) {
      return;
    }

    const sessionData = JSON.parse(data) as SessionData;
    sessionData.containerId = containerId;

    const ttl = await this.redis.ttl(key);
    if (ttl > 0) {
      await this.redis.setex(key, ttl, JSON.stringify(sessionData));
    }
  }

  async getContainerId(sessionId: string): Promise<string | null> {
    const sessionData = await this.getSession(sessionId);
    return sessionData?.containerId || null;
  }

  async validateSessionOwnership(
    sessionId: string,
    userId: string,
  ): Promise<boolean> {
    const sessionData = await this.getSession(sessionId);
    return sessionData?.userId === userId;
  }

  async updateLastActivity(sessionId: string): Promise<void> {
    const key = `lsp:session:${sessionId}`;
    const data = await this.redis.get(key);

    if (!data) {
      return;
    }

    const sessionData = JSON.parse(data) as SessionData;
    sessionData.lastActivity = new Date().toISOString();

    await this.redis.setex(key, this.SESSION_TTL, JSON.stringify(sessionData));
  }

  async uploadFile(
    sessionId: string,
    userId: string,
    file: Express.Multer.File,
  ): Promise<{ filePath: string; originalName: string }> {
    // Validate session ownership
    const sessionData = await this.getSession(sessionId);
    if (!sessionData) {
      throw new NotFoundException('Session not found');
    }
    if (sessionData.userId !== userId) {
      throw new ForbiddenException('Session does not belong to user');
    }

    // Create session-specific directory
    const basePath = process.env.LSP_FILES_PATH || '/lsp-files';
    const sessionDir = join(basePath, sessionId);
    await fs.mkdir(sessionDir, { recursive: true });

    // Save file with sanitized name
    const sanitizedName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    const fullPath = join(sessionDir, sanitizedName);
    await fs.writeFile(fullPath, file.buffer);

    // Track uploaded file in session data
    const key = `lsp:session:${sessionId}`;
    const uploadedFiles = sessionData.uploadedFiles || [];
    if (!uploadedFiles.includes(sanitizedName)) {
      uploadedFiles.push(sanitizedName);
    }
    sessionData.uploadedFiles = uploadedFiles;

    const ttl = await this.redis.ttl(key);
    if (ttl > 0) {
      await this.redis.setex(key, ttl, JSON.stringify(sessionData));
    }

    // Return container-local path
    return {
      filePath: `/workspace/${sanitizedName}`,
      originalName: file.originalname,
    };
  }
}
