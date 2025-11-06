import { IsNotEmpty } from 'class-validator';

export class CreateExecutionJobDto {
  @IsNotEmpty()
  file: Express.Multer.File;
}
