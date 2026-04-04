import { Module } from '@nestjs/common';
import { HealthResolver } from './health.resolver';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [HealthResolver],
})
export class HealthModule {}
