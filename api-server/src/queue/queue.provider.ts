import { Queue } from 'bullmq';
import { queueConfig } from './queue.config';

export const EXECUTION_QUEUE = 'EXECUTION_QUEUE';

export const executionQueueProvider = {
  provide: EXECUTION_QUEUE,
  useFactory: () => {
    return new Queue('execution', queueConfig);
  },
};
