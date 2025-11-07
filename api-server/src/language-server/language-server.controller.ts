import { Controller, Post, Param, HttpCode } from '@nestjs/common';
import { LanguageServerService } from './language-server.service';
import { Auth } from '../auth/auth.decorator';
import { GetRequester } from '../auth/requester.decorator';
import type { Requester } from '../auth/requester.decorator';
import { CreateSessionResponseDto } from './dto/create-session-response.dto';

@Controller('language-server')
export class LanguageServerController {
  constructor(private readonly languageServerService: LanguageServerService) {}

  @Auth()
  @Post('sessions')
  async createSession(
    @GetRequester() requester: Requester,
  ): Promise<CreateSessionResponseDto> {
    return this.languageServerService.createSession(requester.userId);
  }

  @Auth()
  @HttpCode(200)
  @Post('sessions/:sessionId/renew')
  async renewSession(
    @Param('sessionId') sessionId: string,
    @GetRequester() requester: Requester,
  ): Promise<void> {
    return this.languageServerService.renewSession(sessionId, requester.userId);
  }
}
