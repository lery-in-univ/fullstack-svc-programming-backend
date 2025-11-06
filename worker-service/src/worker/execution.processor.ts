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
import Docker from "dockerode";

interface ExecutionJobData {
  jobId: string;
}

@Injectable()
export class ExecutionProcessor implements OnModuleInit, OnModuleDestroy {
  private worker: Worker;
  private docker: Docker;

  constructor(
    @InjectRepository(ExecutionJob)
    private readonly executionJobRepository: Repository<ExecutionJob>,

    @InjectRepository(ExecutionJobStatusLog)
    private readonly executionJobStatusLogRepository: Repository<ExecutionJobStatusLog>
  ) {
    const dockerHost = process.env.DOCKER_HOST || "tcp://dind:2375";
    this.docker = new Docker({
      host: dockerHost.replace("tcp://", "").split(":")[0],
      port: parseInt(dockerHost.split(":")[2] || "2375"),
    });
  }

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

      console.log("Creating busybox container...");
      const container = await this.docker.createContainer({
        Image: "busybox",
        Cmd: ["echo", "hello"],
        AttachStdout: true,
        AttachStderr: true,
      });

      console.log(`Container created: ${container.id}`);

      await container.start();
      console.log("Container started");

      await container.wait();
      console.log("Container finished");

      const logs = await container.logs({
        stdout: true,
        stderr: true,
        follow: false,
      });

      console.log("Container output:", logs.toString());

      await container.remove();
      console.log("Container removed");

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
