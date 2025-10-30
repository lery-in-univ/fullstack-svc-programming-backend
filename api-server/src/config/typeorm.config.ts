import { TypeOrmModuleOptions } from '@nestjs/typeorm';

import { ExecutionJobStatus } from 'src/entities/execution-job-status.entity';
import { ExecutionJob } from 'src/entities/execution-job.entity';
import { User } from 'src/entities/user.entity';

export const typeOrmConfig: TypeOrmModuleOptions = {
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10) || 3306,
  username: process.env.DB_USERNAME || 'root',
  password: process.env.DB_PASSWORD || 'test',
  database: process.env.DB_DATABASE || 'Hello',
  entities: [User, ExecutionJob, ExecutionJobStatus],
  synchronize: false,
};
