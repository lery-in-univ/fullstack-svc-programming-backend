import { SetMetadata } from '@nestjs/common';

export const AuthMetadataKey = '@fullstack-svc-programming-api-server/Auth';

export const Auth = () => SetMetadata(AuthMetadataKey, true);
