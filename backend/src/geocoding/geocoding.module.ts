import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { GeocodingService } from './geocoding.service';

@Module({
  imports: [PrismaModule],
  providers: [GeocodingService],
  exports: [GeocodingService],
})
export class GeocodingModule {}
