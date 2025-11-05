import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Worker, Job } from 'bullmq';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ExecutionJob } from '../entities/execution-job.entity';
import { ExecutionJobStatusLog } from '../entities/execution-job-status-log.entity';
import { redisConfig } from '../config/redis.config';

interface ExecutionJobData {
  jobId: string;
}

@Injectable()
export class ExecutionProcessor implements OnModuleInit, OnModuleDestroy {
  private worker: Worker;

  constructor(
    @InjectRepository(ExecutionJob)
    private readonly executionJobRepository: Repository<ExecutionJob>,

    @InjectRepository(ExecutionJobStatusLog)
    private readonly executionJobStatusLogRepository: Repository<ExecutionJobStatusLog>,
  ) {}

  async onModuleInit() {
    this.worker = new Worker(
      'execution',
      async (job: Job<ExecutionJobData>) => {
        return this.processJob(job);
      },
      {
        connection: redisConfig,
        concurrency: 4,
      },
    );

    this.worker.on('completed', (job) => {
      console.log(`Job ${job.id} completed successfully`);
    });

    this.worker.on('failed', (job, err) => {
      console.error(`Job ${job?.id} failed with error:`, err);
    });

    console.log('Execution worker started with concurrency: 4');
  }

  async onModuleDestroy() {
    await this.worker?.close();
  }

  private async processJob(job: Job<ExecutionJobData>): Promise<void> {
    const { jobId } = job.data;

    console.log(`Processing execution job: ${jobId}`);
    console.log(`Job data:`, JSON.stringify(job.data, null, 2));

    // Initial implementation: just print the jobId
    // Future: implement actual code execution logic
  }
}
