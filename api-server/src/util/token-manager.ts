import jwt from 'jsonwebtoken';
import { Injectable } from '@nestjs/common';

import { appConfig } from 'src/config/app.config';

@Injectable()
export class TokenManager {
  private readonly jwtSecret: string;

  constructor() {
    this.jwtSecret = appConfig.jwtSecret;
  }

  create<T extends object>(payload: T): string {
    return jwt.sign(payload, this.jwtSecret, { expiresIn: '1d' });
  }

  verify<T extends object>(token: string): T {
    return jwt.verify(token, this.jwtSecret) as T;
  }
}
