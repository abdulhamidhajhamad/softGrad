import {
  Controller,
  Post,
  Delete,
  Param,
  UseInterceptors,
  UploadedFile,
  UploadedFiles,
  BadRequestException,
  Get,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { FirebaseService } from './firebase.service';
import { ApiTags, ApiOperation, ApiConsumes, ApiBody, ApiResponse, ApiParam } from '@nestjs/swagger';
import { UploadFileDto, UploadMultipleFilesDto, FileResponseDto } from './uploadFile.dto';

@ApiTags('Storage')
@Controller('storage')
export class FirebaseController {
  constructor(private readonly firebaseService: FirebaseService) {}

  @Post('upload/image')
  @ApiOperation({ summary: 'رفع صورة واحدة', description: 'رفع صورة واحدة إلى Firebase Storage' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ 
    description: 'ملف الصورة',
    type: UploadFileDto 
  })
  @ApiResponse({ 
    status: 201, 
    description: 'تم رفع الصورة بنجاح',
    type: FileResponseDto 
  })
  @ApiResponse({ status: 400, description: 'خطأ في البيانات المرسلة' })
  @UseInterceptors(FileInterceptor('file'))
  async uploadImage(@UploadedFile() file: Express.Multer.File) {
    try {
      const fileUrl = await this.firebaseService.uploadFile(file, 'images');
      
      return {
        success: true,
        message: 'File uploaded successfully',
        data: {
          url: fileUrl,
          originalName: file.originalname,
          size: file.size,
          mimetype: file.mimetype,
        },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Post('upload/images')
  @ApiOperation({ summary: 'رفع عدة صور', description: 'رفع عدة صور مرة واحدة إلى Firebase Storage' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ 
    description: 'مصفوفة من الملفات',
    type: UploadMultipleFilesDto 
  })
  @ApiResponse({ 
    status: 201, 
    description: 'تم رفع الصور بنجاح',
    type: [FileResponseDto] 
  })
  @ApiResponse({ status: 400, description: 'خطأ في البيانات المرسلة' })
  @UseInterceptors(FilesInterceptor('files', 10))
  async uploadMultipleImages(@UploadedFiles() files: Express.Multer.File[]) {
    try {
      const fileUrls = await this.firebaseService.uploadMultipleFiles(files, 'images');
      
      return {
        success: true,
        message: 'Files uploaded successfully',
        data: fileUrls.map((url, index) => ({
          url: url,
          originalName: files[index].originalname,
          size: files[index].size,
          mimetype: files[index].mimetype,
        })),
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Post('upload/document')
  @ApiOperation({ summary: 'رفع مستند', description: 'رفع مستند إلى Firebase Storage' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ 
    description: 'ملف المستند',
    type: UploadFileDto 
  })
  @ApiResponse({ 
    status: 201, 
    description: 'تم رفع المستند بنجاح',
    type: FileResponseDto 
  })
  @ApiResponse({ status: 400, description: 'خطأ في البيانات المرسلة' })
  @UseInterceptors(FileInterceptor('file'))
  async uploadDocument(@UploadedFile() file: Express.Multer.File) {
    try {
      const fileUrl = await this.firebaseService.uploadFile(file, 'documents');
      
      return {
        success: true,
        message: 'Document uploaded successfully',
        data: {
          url: fileUrl,
          originalName: file.originalname,
          size: file.size,
          mimetype: file.mimetype,
        },
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Delete('file/:fileUrl')
  @ApiOperation({ summary: 'حذف ملف', description: 'حذف ملف من Firebase Storage باستخدام الرابط' })
  @ApiParam({ name: 'fileUrl', description: 'رابط الملف المراد حذفه (مشفّر)' })
  @ApiResponse({ status: 200, description: 'تم حذف الملف بنجاح' })
  @ApiResponse({ status: 400, description: 'خطأ في حذف الملف' })
  async deleteFile(@Param('fileUrl') fileUrl: string) {
    try {
      const decodedFileUrl = decodeURIComponent(fileUrl);
      await this.firebaseService.deleteFile(decodedFileUrl);
      
      return {
        success: true,
        message: 'File deleted successfully',
      };
    } catch (error) {
      throw new BadRequestException(error.message);
    }
  }

  @Get('health')
  @ApiOperation({ summary: 'فحص حالة الخدمة', description: 'فحص إذا كانت خدمة Firebase Storage تعمل' })
  @ApiResponse({ status: 200, description: 'الخدمة تعمل بشكل طبيعي' })
  async healthCheck() {
    return {
      success: true,
      message: 'Firebase storage service is running',
      timestamp: new Date().toISOString(),
    };
  }
}