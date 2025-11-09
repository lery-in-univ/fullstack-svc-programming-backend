import {
  Controller,
  Post,
  Param,
  HttpCode,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
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

  @Auth()
  @Post('sessions/:sessionId/files')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 1 * 1024 * 1024, // 1MB
      },
      fileFilter: (_req, file, callback) => {
        const allowedExtensions = ['.dart'];
        const ext = file.originalname.substring(
          file.originalname.lastIndexOf('.'),
        );
        if (allowedExtensions.includes(ext)) {
          callback(null, true);
        } else {
          callback(
            new BadRequestException(
              `File type not allowed. Only .dart files are allowed.`,
            ),
            false,
          );
        }
      },
    }),
  )
  async uploadFile(
    @Param('sessionId') sessionId: string,
    @GetRequester() requester: Requester,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const result = await this.languageServerService.uploadFile(
      sessionId,
      requester.userId,
      file,
    );

    return result;
  }
}
