import { ApiProperty } from '@nestjs/swagger';

export class UploadFileDto {
  @ApiProperty({ type: 'string', format: 'binary' })
  file: any;
}

export class UploadMultipleFilesDto {
  @ApiProperty({ type: 'array', items: { type: 'string', format: 'binary' } })
  files: any[];
}

export class FileResponseDto {
  @ApiProperty({ example: 'https://storage.googleapis.com/...' })
  url: string;

  @ApiProperty({ example: 'image.png' })
  originalName: string;

  @ApiProperty({ example: 1024 })
  size: number;

  @ApiProperty({ example: 'image/png' })
  mimetype: string;
}