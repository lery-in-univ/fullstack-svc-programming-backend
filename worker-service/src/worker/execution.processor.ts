import { Injectable, OnModuleInit, OnModuleDestroy } from "@nestjs/common";
import { Worker, Job } from "bullmq";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { ExecutionJob } from "../entities/execution-job.entity";
import { ExecutionJobStatusLog } from "../entities/execution-job-status-log.entity";
import { ExecutionJobStatus } from "../entities/execution-job-status";
import { redisConfig } from "../config/redis.config";
import { promises as fs } from "fs";
import { join } from "path";
import { ulid } from "ulid";

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
    private readonly executionJobStatusLogRepository: Repository<ExecutionJobStatusLog>
  ) {}

  async onModuleInit() {
    this.worker = new Worker(
      "execution",
      async (job: Job<ExecutionJobData>) => {
        return this.processJob(job);
      },
      {
        connection: redisConfig,
        concurrency: 4,
      }
    );

    this.worker.on("completed", (job) => {
      console.log(`Job ${job.id} completed successfully`);
    });

    this.worker.on("failed", (job, err) => {
      console.error(`Job ${job?.id} failed with error:`, err);
    });

    console.log("Execution worker started with concurrency: 4");
  }

  async onModuleDestroy() {
    await this.worker?.close();
  }

  private async processJob(job: Job<ExecutionJobData>): Promise<void> {
    const { jobId } = job.data;

    console.log(`Processing execution job: ${jobId}`);
    console.log(`Job data:`, JSON.stringify(job.data, null, 2));

    try {
      const executionJob = await this.executionJobRepository.findOne({
        where: { id: jobId },
      });

      if (!executionJob) {
        throw new Error(`Execution job ${jobId} not found`);
      }

      await this.createStatusLog(jobId, ExecutionJobStatus.READY);

      const basePath = process.env.CODE_FILES_PATH || "/code-files";
      const fullPath = join(basePath, executionJob.filePath);

      await fs.access(fullPath);
      console.log(`File found at: ${fullPath}`);

      await this.createStatusLog(jobId, ExecutionJobStatus.RUNNING);

      // TODO: Implement actual code execution logic here
      // For now, just read the file to verify it's accessible
      const fileContent = await fs.readFile(fullPath, "utf-8");
      console.log(`File content length: ${fileContent.length} bytes`);

      await this.createStatusLog(
        jobId,
        ExecutionJobStatus.FINISHED_WITH_SUCCESS
      );
    } catch (error) {
      console.error(`Error processing job ${jobId}:`, error);

      await this.createStatusLog(jobId, ExecutionJobStatus.FAILED);
      throw error;
    }
  }

  private async createStatusLog(
    jobId: string,
    status: ExecutionJobStatus
  ): Promise<void> {
    const statusLog = this.executionJobStatusLogRepository.create({
      id: ulid(),
      jobId,
      status,
      createdAt: new Date(),
    });
    await this.executionJobStatusLogRepository.save(statusLog);
    console.log(`Job ${jobId} status updated to ${status}`);
  }
}
