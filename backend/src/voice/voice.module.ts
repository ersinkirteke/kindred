import { Module } from '@nestjs/common';
import { ImagesModule } from '../images/images.module';
import { ElevenLabsService } from './elevenlabs.service';

/**
 * VoiceModule
 *
 * Manages voice cloning and text-to-speech narration for recipe videos.
 * Uses ElevenLabs API for voice cloning and TTS streaming.
 */
@Module({
  imports: [ImagesModule],
  providers: [ElevenLabsService],
  exports: [ElevenLabsService],
})
export class VoiceModule {}
