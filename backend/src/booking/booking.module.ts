// src/booking/booking.module.ts

import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose'; // <-- CHANGED
import { BookingController } from './booking.controller';
import { BookingService } from './booking.service';
import { Booking, BookingSchema } from './booking.entity'; 
import { User } from '../auth/user.entity'; // Used as model token/name
import { Service } from '../service/service.entity'; // Used as model token/name
import { ServiceSchema } from '../service/service.schema'; // The provided service schema

// NOTE: We must assume a UserSchema exists for the User model. 
// For this code to compile, you must ensure the 'User' model is imported and used in MongooseModule.
// The structure assumes a UserSchema, though the file is not provided.

@Module({
  imports: [
    // Removed TypeOrmModule and replaced with MongooseModule for all three models
    MongooseModule.forFeature([
      { name: Booking.name, schema: BookingSchema },
      // ASSUMPTION: The User model is registered as 'User' and Service as 'Service'
      { name: User.name, schema: {} as any }, // Placeholder for UserSchema
      { name: Service.name, schema: ServiceSchema }, 
    ]),
  ],
  controllers: [BookingController],
  providers: [BookingService], // <-- UNCOMMENTED
  exports: [BookingService], // <-- UNCOMMENTED
})
export class BookingModule {}