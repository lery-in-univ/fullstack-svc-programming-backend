import { Module } from '@nestjs/common';
import { LanguageServerController } from './language-server.controller';
import { LanguageServerService } from './language-server.service';

@Module({
  controllers: [LanguageServerController],
  providers: [LanguageServerService],
  exports: [LanguageServerService],
})
export class LanguageServerModule {}
