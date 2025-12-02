import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SupabaseStorageService {
  private supabase: any;
  private sharp: any;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    try {
      const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
      const supabaseKey = this.configService.get<string>('SUPABASE_ANON_KEY');

      if (!supabaseUrl || !supabaseKey) {
        console.warn('⚠️ Supabase credentials missing - image uploads will use default avatars');
        return;
      }

      const { createClient } = await import('@supabase/supabase-js');
      this.sharp = (await import('sharp')).default;
      
      this.supabase = createClient(supabaseUrl, supabaseKey, {
        auth: {
          persistSession: false,
        },
      });
      
      console.log('✅ Supabase Storage initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize Supabase Storage:', error);
    }
  }

  async uploadImage(
    file: Express.Multer.File, 
    folder: string = 'users',
    compress: boolean = true
  ): Promise<string> {
    try {
      if (!this.supabase) {
        await this.onModuleInit();
      }

      if (!this.supabase) {
        console.warn('⚠️ Supabase not available, using default avatar');
        throw new Error('Supabase storage not available');
      }

      let fileBuffer = file.buffer;
      let mimeType = file.mimetype;
      let originalName = file.originalname;

      if (compress && this.isImageFile(file)) {
        try {
          const compressedResult = await this.compressImage(fileBuffer);
          fileBuffer = compressedResult.buffer;
          mimeType = compressedResult.mimeType;
          originalName = this.changeExtensionToWebp(originalName);
        } catch (compressError) {
          console.warn('⚠️ Image compression failed, using original image');
        }
      }

      const fileName = `${folder}/${Date.now()}-${originalName}`;

      const { data, error } = await this.supabase.storage
        .from('images') 
        .upload(fileName, fileBuffer, {
          contentType: mimeType,
          upsert: false,
        });

      if (error) {
        console.error('❌ Supabase upload error:', error);
        throw new BadRequestException(`Failed to upload image: ${error.message}`);
      }

      const { data: { publicUrl } } = this.supabase.storage
        .from('images')
        .getPublicUrl(fileName);

      console.log('✅ Image uploaded to Supabase:', publicUrl);
      return publicUrl;

    } catch (error) {
      console.error('❌ Supabase service error:', error);
      throw new BadRequestException('Image upload failed');
    }
  }

  private async compressImage(buffer: Buffer): Promise<{ buffer: Buffer; mimeType: string }> {
    try {

      if (!this.sharp) {
        this.sharp = (await import('sharp')).default;
      }

      const compressedBuffer = await this.sharp(buffer)
        .resize(800, 800, {
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 80 })
        .toBuffer();

      return {
        buffer: compressedBuffer,
        mimeType: 'image/webp',
      };
    } catch (error) {
      console.error('❌ Image compression failed, using original:', error);
      return {
        buffer: buffer,
        mimeType: 'image/jpeg',
      };
    }
  }

  private isImageFile(file: Express.Multer.File): boolean {
    return file.mimetype.startsWith('image/');
  }

  async deleteImage(imageUrl: string): Promise<void> {
    try {
      if (!imageUrl) {
        return;
      }

      // Extract file path from URL
      const urlParts = imageUrl.split('/');
      const fileName = urlParts.slice(urlParts.indexOf('images')).join('/');
      
      if (!fileName || !fileName.includes('images/')) {
        console.log('Invalid image URL or default avatar, skipping deletion');
        return;
      }

      // Delete file from Supabase
      const { error } = await this.supabase.storage
        .from('images')
        .remove([fileName]);

      if (error) {
        console.error('Supabase delete error:', error);
        // Don't throw error for delete failures to avoid breaking the update process
        console.warn(`Failed to delete image: ${imageUrl}`);
        return;
      }

      console.log(`✅ Successfully deleted image: ${fileName}`);
    } catch (error) {
      console.error('Error in deleteImage:', error);
      // Don't throw error to avoid breaking the main operation
      console.warn(`Error deleting image: ${imageUrl}`);
    }
  }

  /**
   * Update image - delete old and upload new
    */
    async updateImage(
      oldImageUrl: string,
      newFile: Express.Multer.File,
      folder: string = 'images'
    ): Promise<string> {
      try {
        // Delete old image if it exists and is not a default avatar
        if (oldImageUrl && !oldImageUrl.includes('ui-avatars.com')) {
          await this.deleteImage(oldImageUrl);
        }

        // Upload new image
        return await this.uploadImage(newFile, folder, true);
      } catch (error) {
        console.error('Error in updateImage:', error);
        throw new BadRequestException('Image update failed');
      }
    }
    

  private changeExtensionToWebp(filename: string): string {
    return filename.replace(/\.[^/.]+$/, '.webp');
  }

  async deleteFile(fileUrl: string): Promise<void> {
    try {
      if (!this.supabase) {
        await this.onModuleInit();
      }

      if (!this.supabase) {
        throw new Error('Supabase storage not available');
      }

      const fileName = this.extractFileNameFromUrl(fileUrl);
      
      const { error } = await this.supabase.storage
        .from('images')
        .remove([fileName]);

      if (error) {
        console.error('❌ Supabase delete error:', error);
        throw new Error(`Failed to delete file: ${error.message}`);
      }

      console.log('✅ File deleted from Supabase:', fileName);
    } catch (error) {
      console.error('❌ Delete operation failed:', error);
      throw error;
    }
  }

  private extractFileNameFromUrl(url: string): string {
    const urlParts = url.split('/');
    return urlParts.slice(-2).join('/'); 
  }
}