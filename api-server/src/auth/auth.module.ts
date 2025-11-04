import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from 'src/entities/user.entity';
import { RequestValidator } from './request-validator';
import { APP_GUARD } from '@nestjs/core';
import { AuthGuard } from './auth.guard';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [RequestValidator, { provide: APP_GUARD, useClass: AuthGuard }],
})
export class AuthModule {}
