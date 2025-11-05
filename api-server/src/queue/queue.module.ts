import { Module } from '@nestjs/common';
import { executionQueueProvider } from './queue.provider';

@Module({
  providers: [executionQueueProvider],
  exports: [executionQueueProvider],
})
export class QueueModule {}
