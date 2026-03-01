import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * ElevenLabsService
 *
 * REST API client for ElevenLabs voice cloning and text-to-speech.
 * Uses ultra-low latency model (eleven_flash_v2_5) for ~75ms streaming.
 */
@Injectable()
export class ElevenLabsService {
  private readonly logger = new Logger(ElevenLabsService.name);
  private readonly apiKey: string | null;
  private readonly baseUrl = 'https://api.elevenlabs.io/v1';

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('ELEVENLABS_API_KEY') ?? null;

    if (!this.apiKey) {
      this.logger.warn(
        'ELEVENLABS_API_KEY not configured. Voice cloning will not work. ' +
          'Set ELEVENLABS_API_KEY in environment variables.',
      );
    } else {
      this.logger.log('ElevenLabs API client initialized');
    }
  }

  /**
   * Clone a voice from audio samples
   *
   * @param params - Voice cloning parameters
   * @param params.name - Name for the cloned voice (e.g., "Mom's Voice")
   * @param params.files - Array of audio buffers (MP3 format)
   * @returns ElevenLabs voice_id for the cloned voice
   * @throws Error if cloning fails or API key is missing
   */
  async cloneVoice(params: {
    name: string;
    files: Buffer[];
  }): Promise<string> {
    if (!this.apiKey) {
      throw new Error('ELEVENLABS_API_KEY not configured');
    }

    try {
      const formData = new FormData();
      formData.append('name', params.name);

      // Append each audio file as a blob
      params.files.forEach((buffer, index) => {
        const uint8Array = new Uint8Array(buffer);
        const blob = new Blob([uint8Array], { type: 'audio/mpeg' });
        formData.append('files', blob, `sample-${index}.mp3`);
      });

      const response = await fetch(`${this.baseUrl}/voices/add`, {
        method: 'POST',
        headers: {
          'xi-api-key': this.apiKey,
        },
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `ElevenLabs API error (${response.status}): ${JSON.stringify(errorData)}`,
        );
      }

      const data = await response.json();
      this.logger.log(`Voice cloned successfully: ${data.voice_id}`);
      return data.voice_id;
    } catch (error) {
      this.logger.error('Failed to clone voice', error);
      throw new Error(`Voice cloning failed: ${error.message}`);
    }
  }

  /**
   * Delete a cloned voice from ElevenLabs
   *
   * @param voiceId - ElevenLabs voice_id to delete
   * @throws Error if deletion fails (404 errors are swallowed)
   */
  async deleteVoice(voiceId: string): Promise<void> {
    if (!this.apiKey) {
      throw new Error('ELEVENLABS_API_KEY not configured');
    }

    try {
      const response = await fetch(`${this.baseUrl}/voices/${voiceId}`, {
        method: 'DELETE',
        headers: {
          'xi-api-key': this.apiKey,
        },
      });

      // Swallow 404 errors - voice already deleted
      if (response.status === 404) {
        this.logger.log(`Voice already deleted: ${voiceId}`);
        return;
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `ElevenLabs API error (${response.status}): ${JSON.stringify(errorData)}`,
        );
      }

      this.logger.log(`Voice deleted successfully: ${voiceId}`);
    } catch (error) {
      this.logger.error(`Failed to delete voice: ${voiceId}`, error);
      throw new Error(`Voice deletion failed: ${error.message}`);
    }
  }

  /**
   * Generate speech from text and stream it
   *
   * Uses eleven_flash_v2_5 model for ultra-low latency (~75ms).
   *
   * @param voiceId - ElevenLabs voice_id to use for TTS
   * @param text - Text to convert to speech
   * @returns ReadableStream of audio chunks
   * @throws Error if TTS generation fails
   */
  async generateSpeechStream(
    voiceId: string,
    text: string,
  ): Promise<ReadableStream> {
    if (!this.apiKey) {
      throw new Error('ELEVENLABS_API_KEY not configured');
    }

    try {
      const response = await fetch(
        `${this.baseUrl}/text-to-speech/${voiceId}/stream`,
        {
          method: 'POST',
          headers: {
            'xi-api-key': this.apiKey,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            text,
            model_id: 'eleven_flash_v2_5',
            voice_settings: {
              stability: 0.5,
              similarity_boost: 0.75,
            },
          }),
        },
      );

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `ElevenLabs API error (${response.status}): ${JSON.stringify(errorData)}`,
        );
      }

      if (!response.body) {
        throw new Error('No response body from ElevenLabs TTS');
      }

      this.logger.log(`TTS streaming started for voice: ${voiceId}`);
      return response.body;
    } catch (error) {
      this.logger.error(`Failed to generate speech for voice: ${voiceId}`, error);
      throw new Error(`TTS generation failed: ${error.message}`);
    }
  }

  /**
   * Get voice details from ElevenLabs
   *
   * Used for status checking during cloning process.
   *
   * @param voiceId - ElevenLabs voice_id to retrieve
   * @returns Voice data or null if not found
   */
  async getVoice(voiceId: string): Promise<{
    voice_id: string;
    name: string;
  } | null> {
    if (!this.apiKey) {
      throw new Error('ELEVENLABS_API_KEY not configured');
    }

    try {
      const response = await fetch(`${this.baseUrl}/voices/${voiceId}`, {
        method: 'GET',
        headers: {
          'xi-api-key': this.apiKey,
        },
      });

      if (response.status === 404) {
        return null;
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `ElevenLabs API error (${response.status}): ${JSON.stringify(errorData)}`,
        );
      }

      const data = await response.json();
      return {
        voice_id: data.voice_id,
        name: data.name,
      };
    } catch (error) {
      this.logger.error(`Failed to get voice: ${voiceId}`, error);
      throw new Error(`Get voice failed: ${error.message}`);
    }
  }
}
