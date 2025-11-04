import { UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { TokenManager } from 'src/util/token-manager';
import { Requester } from './requester.decorator';

export class RequestValidator {
  constructor(private readonly tokenManager: TokenManager) {}

  validate(request: Request): void {
    const authHeader = request.header('Authorization');
    if (!authHeader) {
      throw new UnauthorizedException('인증이 필요합니다.');
    }

    const token = authHeader.split(' ')[0];
    if (!token) {
      throw new UnauthorizedException('인증이 필요합니다.');
    }

    const payload = this.tokenManager.verify<Requester>(token);
    request['requester'] = payload;
  }
}
