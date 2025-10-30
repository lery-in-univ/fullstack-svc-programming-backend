import { Entity, Column, PrimaryColumn, ManyToOne, JoinColumn } from 'typeorm';
import { ExecutionJob } from './execution-job.entity';

@Entity('ExecutionJobStatus')
export class ExecutionJobStatus {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 50 })
  jobId: string;

  @Column({ type: 'varchar', length: 50 })
  status: string;

  @Column({ type: 'datetime', precision: 3 })
  createdAt: Date;

  @ManyToOne(() => ExecutionJob, (job) => job.statuses, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'jobId' })
  job: ExecutionJob;
}
