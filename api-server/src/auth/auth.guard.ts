import {
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthMetadataKey } from './auth.decorator';
import { TypedReflect } from 'src/util/typed-reflect';
import { Request } from 'express';
import { RequestValidator } from './request-validator';

export class AuthGuard implements CanActivate {
  constructor(private readonly requestValidator: RequestValidator) {}

  canActivate(context: ExecutionContext): boolean {
    const handler = context.getHandler();

    const shouldCheckAuth = TypedReflect.getMetadata<boolean>(
      AuthMetadataKey,
      handler,
    );
    if (!shouldCheckAuth) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request>();
    const authHeader = request.header('Authorization');

    if (!authHeader) {
      throw new UnauthorizedException();
    }

    this.requestValidator.validate(request);

    return true;
  }
}
