import { Entity, Column, PrimaryColumn, OneToMany } from 'typeorm';
import { ExecutionJobStatusLog } from './execution-job-status-log.entity';

@Entity('ExecutionJob')
export class ExecutionJob {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 50 })
  userId: string;

  @Column({ type: 'varchar', length: 200 })
  filePath: string;

  @Column({ type: 'datetime', precision: 3 })
  createdAt: Date;

  @OneToMany(() => ExecutionJobStatusLog, (status) => status.job)
  statuses: ExecutionJobStatusLog[];
}
