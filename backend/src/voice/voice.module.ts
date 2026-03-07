import { Module } from '@nestjs/common';
import { ImagesModule } from '../images/images.module';
import { PrismaModule } from '../prisma/prisma.module';
import { PushModule } from '../push/push.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { ElevenLabsService } from './elevenlabs.service';
import { NarrationService } from './narration.service';
import { NarrationController } from './narration.controller';
import { VoiceService } from './voice.service';
import { VoiceCloningProcessor } from './voice-cloning.processor';
import { VoiceResolver } from './voice.resolver';
import { VoiceController } from './voice.controller';

/**
 * VoiceModule
 *
 * Manages voice cloning and text-to-speech narration for recipe videos.
 * Uses ElevenLabs API for voice cloning and TTS streaming.
 * Uses Gemini 2.0 Flash for conversational rewriting.
 *
 * Provides:
 * - Voice upload pipeline (REST controller for file uploads)
 * - Background voice cloning queue with ElevenLabs integration
 * - GraphQL resolver for voice profile management
 * - TTS streaming for recipe narration
 */
@Module({
  imports: [ImagesModule, PrismaModule, PushModule, SubscriptionModule],
  providers: [
    ElevenLabsService,
    NarrationService,
    VoiceService,
    VoiceCloningProcessor,
    VoiceResolver,
  ],
  controllers: [NarrationController, VoiceController],
  exports: [ElevenLabsService, NarrationService, VoiceService],
})
export class VoiceModule {}
