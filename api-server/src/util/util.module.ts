import { Global, Module } from '@nestjs/common';
import { PasswordHashCreator } from './password-hash-creator';
import { TokenManager } from './token-manager';

const providers = [PasswordHashCreator, TokenManager];

@Global()
@Module({ providers, exports: providers })
export class UtilModule {}
