import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { GeocodingModule } from '../geocoding/geocoding.module';
import { FeedService } from './feed.service';
import { FeedResolver } from './feed.resolver';

@Module({
  imports: [PrismaModule, GeocodingModule],
  providers: [FeedService, FeedResolver],
  exports: [FeedService],
})
export class FeedModule {}
