import {
  BadRequestException,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Auth } from 'src/auth/auth.decorator';
import { GetRequester } from 'src/auth/requester.decorator';
import type { Requester } from 'src/auth/requester.decorator';
import { ExecutionService } from './execution.service';
import { ExecutionJob } from 'src/entities/execution-job.entity';
import { ExecutionJobStatusLog } from 'src/entities/execution-job-status-log.entity';

@Controller()
export class ExecutionController {
  constructor(private readonly executionService: ExecutionService) {}

  @Auth()
  @Post('/execution-jobs')
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
  async createExecutionJob(
    @GetRequester() requester: Requester,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const job = await this.executionService.createExecutionJob(
      requester.userId,
      file,
    );

    return {
      id: job.id,
      status: 'QUEUED',
      createdAt: job.createdAt,
    };
  }

  @Auth()
  @Get('/execution-jobs')
  async getExecutionJobs(@GetRequester() requester: Requester) {
    const jobs = await this.executionService.findExecutionJobsByUserId(
      requester.userId,
    );

    return jobs.map((job: ExecutionJob) => {
      const statuses: ExecutionJobStatusLog[] = job.statuses || [];
      const latestStatus =
        statuses.length > 0
          ? [...statuses].sort(
              (a, b) => b.createdAt.getTime() - a.createdAt.getTime(),
            )[0]
          : null;

      return {
        id: job.id,
        status: latestStatus?.status || 'UNKNOWN',
        filePath: job.filePath,
        createdAt: job.createdAt,
      };
    });
  }

  @Auth()
  @Get('/execution-jobs/:jobId')
  async getExecutionJob(
    @GetRequester() requester: Requester,
    @Param('jobId') id: string,
  ) {
    const job = await this.executionService.findExecutionJobById(
      id,
      requester.userId,
    );

    if (!job) {
      throw new NotFoundException('Execution job not found');
    }

    const statuses: ExecutionJobStatusLog[] = job.statuses || [];
    const sortedStatuses = [...statuses].sort(
      (a, b) => a.createdAt.getTime() - b.createdAt.getTime(),
    );

    const latestStatus =
      sortedStatuses.length > 0
        ? sortedStatuses[sortedStatuses.length - 1]
        : null;

    return {
      id: job.id,
      status: latestStatus?.status || 'UNKNOWN',
      filePath: job.filePath,
      createdAt: job.createdAt,
      statusHistory: sortedStatuses.map((status: ExecutionJobStatusLog) => ({
        status: status.status,
        createdAt: status.createdAt,
      })),
    };
  }
}
