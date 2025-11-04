import { createParamDecorator } from '@nestjs/common';
import { Request } from 'express';

export type Requester = {
  userId: string;
};

export const GetRequester = () =>
  createParamDecorator((data, ctx) => {
    const req = ctx.switchToHttp().getRequest<Request>();
    return req['requester'] as Requester;
  });
