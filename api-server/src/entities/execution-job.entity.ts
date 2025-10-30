import {
  Entity,
  Column,
  PrimaryColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { ExecutionJobStatus } from './execution-job-status.entity';

@Entity('ExecutionJob')
export class ExecutionJob {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 50 })
  userId: string;

  @Column({ type: 'datetime', precision: 3 })
  createdAt: Date;

  @ManyToOne(() => User, (user) => user.executionJobs)
  @JoinColumn({ name: 'userId' })
  user: User;

  @OneToMany(() => ExecutionJobStatus, (status) => status.job)
  statuses: ExecutionJobStatus[];
}
