import { Module } from '@nestjs/common';
import { LanguageServerController } from './language-server.controller';
import { LanguageServerService } from './language-server.service';
import { LanguageServerGateway } from './language-server.gateway';
import { UtilModule } from '../util/util.module';

@Module({
  imports: [UtilModule],
  controllers: [LanguageServerController],
  providers: [LanguageServerService, LanguageServerGateway],
  exports: [LanguageServerService],
})
export class LanguageServerModule {}
