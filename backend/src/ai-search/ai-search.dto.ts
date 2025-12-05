import { IsString, IsNotEmpty } from 'class-validator';
export class AiSearchDto {
  @IsString({ message: 'The prompt must be a string.' })
  @IsNotEmpty({ message: 'The search prompt cannot be empty.' })
  prompt: string;
}