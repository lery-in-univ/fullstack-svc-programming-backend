import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { typeOrmConfig } from './config/typeorm.config';
import { WorkerModule } from './worker/worker.module';

@Module({
  imports: [TypeOrmModule.forRoot(typeOrmConfig), WorkerModule],
})
export class AppModule {}
