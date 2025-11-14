import { Injectable, BadRequestException } from '@nestjs/common';
import { FirebaseConfig } from './firebase.config';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class FirebaseService {
  private bucket;

  constructor(private firebaseConfig: FirebaseConfig) {
    this.bucket = this.firebaseConfig.getStorage().bucket();
  }

  async uploadFile(file: Express.Multer.File, folder: string = 'images'): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf'];
    if (!allowedMimes.includes(file.mimetype)) {
      throw new BadRequestException('File type not allowed. Allowed types: JPEG, PNG, GIF, WEBP, PDF');
    }

    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException('File size too large. Maximum size is 5MB');
    }

    const fileName = `${folder}/${uuidv4()}-${file.originalname}`;
    const fileUpload = this.bucket.file(fileName);

    const stream = fileUpload.createWriteStream({
      metadata: {
        contentType: file.mimetype,
      },
    });

    return new Promise((resolve, reject) => {
      stream.on('error', (error) => {
        reject(new Error(`Upload failed: ${error.message}`));
      });

      stream.on('finish', async () => {
        try {
          await fileUpload.makePublic();
          const publicUrl = `https://storage.googleapis.com/${this.bucket.name}/${fileName}`;
          resolve(publicUrl);
        } catch (error) {
          reject(new Error(`Failed to make file public: ${error.message}`));
        }
      });

      stream.end(file.buffer);
    });
  }

  async uploadMultipleFiles(files: Express.Multer.File[], folder: string = 'images'): Promise<string[]> {
    if (!files || files.length === 0) {
      throw new BadRequestException('No files provided');
    }

    const uploadPromises = files.map(file => this.uploadFile(file, folder));
    return Promise.all(uploadPromises);
  }

  async deleteFile(fileUrl: string): Promise<void> {
    try {
      const fileName = this.extractFileNameFromUrl(fileUrl);
      await this.bucket.file(fileName).delete();
    } catch (error) {
      throw new Error(`Delete failed: ${error.message}`);
    }
  }

  private extractFileNameFromUrl(url: string): string {
    const baseUrl = `https://storage.googleapis.com/${this.bucket.name}/`;
    return url.replace(baseUrl, '');
  }
}