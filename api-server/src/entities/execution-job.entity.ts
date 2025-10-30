import { Entity, Column, PrimaryColumn, OneToMany } from 'typeorm';
import { ExecutionJobStatus } from './execution-job-status.entity';

@Entity('ExecutionJob')
export class ExecutionJob {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 50 })
  userId: string;

  @Column({ type: 'datetime', precision: 3 })
  createdAt: Date;

  @OneToMany(() => ExecutionJobStatus, (status) => status.job)
  statuses: ExecutionJobStatus[];
}
