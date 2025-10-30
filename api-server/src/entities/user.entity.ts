import { Entity, Column, PrimaryColumn, OneToMany } from 'typeorm';
import { ExecutionJob } from './execution-job.entity';

@Entity('User')
export class User {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 100 })
  email: string;

  @Column({ type: 'varchar', length: 255 })
  password: string;

  @Column({ type: 'datetime', precision: 3 })
  createdAt: Date;

  @OneToMany(() => ExecutionJob, (job) => job.user)
  executionJobs: ExecutionJob[];
}
