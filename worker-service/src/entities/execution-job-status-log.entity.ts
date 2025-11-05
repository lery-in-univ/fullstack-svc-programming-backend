import { Entity, Column, PrimaryColumn, ManyToOne, JoinColumn } from 'typeorm';
import { ExecutionJob } from './execution-job.entity';
import { ExecutionJobStatus } from './execution-job-status';

@Entity('ExecutionJobStatusLog')
export class ExecutionJobStatusLog {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 50 })
  jobId: string;

  @Column({ type: 'varchar', length: 50 })
  status: ExecutionJobStatus;

  @Column({ type: 'datetime', precision: 3 })
  createdAt: Date;

  @ManyToOne(() => ExecutionJob, (job) => job.statuses, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'jobId' })
  job: ExecutionJob;
}
