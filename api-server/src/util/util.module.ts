import { Global, Module } from '@nestjs/common';
import { PasswordHashCreator } from './password-hash-creator';
import { TokenManager } from './token-manager';

@Global()
@Module({
  providers: [PasswordHashCreator, TokenManager],
})
export class UtilModule {}
