import jwt from 'jsonwebtoken';
import { Injectable } from '@nestjs/common';

import { appConfig } from 'src/config/app.config';

type TokenPayload = {
  userId: string;
};

@Injectable()
export class TokenManager {
  private readonly jwtSecret: string;

  constructor() {
    this.jwtSecret = appConfig.jwtSecret;
  }

  create(userId: string): string {
    const payload: TokenPayload = { userId };
    return jwt.sign(payload, this.jwtSecret, { expiresIn: '1d' });
  }

  verify(token: string): TokenPayload {
    return jwt.verify(token, this.jwtSecret) as TokenPayload;
  }
}
