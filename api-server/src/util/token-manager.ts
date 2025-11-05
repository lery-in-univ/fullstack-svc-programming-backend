import jwt from 'jsonwebtoken';
import { BadRequestException, ConsoleLogger, Injectable } from '@nestjs/common';

import { appConfig } from 'src/config/app.config';

@Injectable()
export class TokenManager {
  private readonly jwtSecret: string;
  private readonly logger = new ConsoleLogger(TokenManager.name);

  constructor() {
    this.jwtSecret = appConfig.jwtSecret;
  }

  create<T extends object>(payload: T): string {
    return jwt.sign(payload, this.jwtSecret, { expiresIn: '1d' });
  }

  verify<T extends object>(token: string): T {
    try {
      return jwt.verify(token, this.jwtSecret) as T;
    } catch (e) {
      const message = e instanceof Error ? e.stack : 'Unknown';
      this.logger.error('토큰 검증 중 에러가 발생했습니다.', message);
      throw new BadRequestException('Token verification failed');
    }
  }
}
