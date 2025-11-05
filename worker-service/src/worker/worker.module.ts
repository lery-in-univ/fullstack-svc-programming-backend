import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ExecutionJob } from '../entities/execution-job.entity';
import { ExecutionJobStatusLog } from '../entities/execution-job-status-log.entity';
import { ExecutionProcessor } from './execution.processor';

@Module({
  imports: [
    TypeOrmModule.forFeature([ExecutionJob, ExecutionJobStatusLog]),
  ],
  providers: [ExecutionProcessor],
})
export class WorkerModule {}
