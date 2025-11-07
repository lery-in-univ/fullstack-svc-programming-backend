import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  OnModuleDestroy,
} from '@nestjs/common';
import Redis from 'ioredis';
import { ulid } from 'ulid';
import { CreateSessionResponseDto } from './dto/create-session-response.dto';

interface SessionData {
  userId: string;
  containerId?: string;
  createdAt: string;
}

@Injectable()
export class LanguageServerService implements OnModuleDestroy {
  private readonly redis: Redis;
  private readonly SESSION_TTL = 60;

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
}
