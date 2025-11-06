import { Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Queue } from 'bullmq';
import { ExecutionJob } from 'src/entities/execution-job.entity';
import { ExecutionJobStatusLog } from 'src/entities/execution-job-status-log.entity';
import { ExecutionJobStatus } from 'src/entities/execution-job-status';
import { EXECUTION_QUEUE } from 'src/queue/queue.provider';
import { DataSource, Repository } from 'typeorm';
import { ulid } from 'ulid';
import { promises as fs } from 'fs';
import { join } from 'path';

@Injectable()
export class ExecutionService {
  constructor(
    @InjectRepository(ExecutionJob)
    private readonly executionJobRepository: Repository<ExecutionJob>,

    private readonly dataSource: DataSource,

    @Inject(EXECUTION_QUEUE)
    private readonly executionQueue: Queue,
  ) {}

  async createExecutionJob(
    userId: string,
    file: Express.Multer.File,
  ): Promise<ExecutionJob> {
    const fileExtension = file.originalname.substring(
      file.originalname.lastIndexOf('.'),
    );
    const fileName = `${ulid()}${fileExtension}`;

    const basePath = process.env.CODE_FILES_PATH || '/code-files';

    await fs.mkdir(basePath, { recursive: true });

    const fullPath = join(basePath, fileName);
    await fs.writeFile(fullPath, file.buffer);

    const relativeFilePath = fileName;

    const newJob = await this.dataSource.transaction(async (em) => {
      const executionJobRepository = em.getRepository(ExecutionJob);
      const executionJobStatusLogRepository = em.getRepository(
        ExecutionJobStatusLog,
      );

      const jobId = ulid();
      const now = new Date();

      const newJob = executionJobRepository.create({
        id: jobId,
        userId,
        filePath: relativeFilePath,
        createdAt: now,
      });
      await executionJobRepository.save(newJob);

      const initialStatusLog = executionJobStatusLogRepository.create({
        id: ulid(),
        jobId,
        status: ExecutionJobStatus.QUEUED,
        createdAt: now,
      });
      await executionJobStatusLogRepository.save(initialStatusLog);

      return newJob;
    });

    // Publish execution task to BullMQ after DB transaction commits
    await this.executionQueue.add('execute-code', {
      jobId: newJob.id,
    });

    return newJob;
  }

  async findExecutionJobsByUserId(
    userId: string,
  ): Promise<(ExecutionJob & { statuses: ExecutionJobStatusLog[] })[]> {
    const jobs = await this.executionJobRepository.find({
      where: { userId },
      relations: { statuses: true },
      order: { createdAt: 'DESC' },
    });
    return jobs as (ExecutionJob & { statuses: ExecutionJobStatusLog[] })[];
  }

  async findExecutionJobById(
    jobId: string,
    userId: string,
  ): Promise<(ExecutionJob & { statuses: ExecutionJobStatusLog[] }) | null> {
    const job = await this.executionJobRepository.findOne({
      where: { id: jobId, userId },
      relations: { statuses: true },
    });
    return job as (ExecutionJob & { statuses: ExecutionJobStatusLog[] }) | null;
  }
}
