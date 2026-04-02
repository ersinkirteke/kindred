import { Controller, Get, Logger, Res } from '@nestjs/common';
import { Response } from 'express';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

/**
 * PrivacyController
 *
 * Serves the privacy policy HTML page at GET /privacy.
 * This is a PUBLIC route (no authentication required) as mandated by:
 * - App Store Review Guidelines (requires publicly accessible privacy policy URL)
 * - GDPR Article 13 (transparent processing information)
 */
@Controller('privacy')
export class PrivacyController {
  private readonly logger = new Logger(PrivacyController.name);

  /**
   * GET /privacy
   *
   * Serves the privacy policy HTML page.
   * No authentication required - public route.
   */
  @Get()
  getPrivacyPolicy(@Res() res: Response) {
    // Try multiple paths since nest build asset copying and tsc output
    // may place the HTML in different locations depending on rootDir
    const candidates = [
      join(__dirname, 'privacy-policy.html'),
      join(process.cwd(), 'dist', 'privacy', 'privacy-policy.html'),
      join(process.cwd(), 'dist', 'src', 'privacy', 'privacy-policy.html'),
    ];

    for (const htmlPath of candidates) {
      if (existsSync(htmlPath)) {
        const html = readFileSync(htmlPath, 'utf-8');
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        res.send(html);
        return;
      }
    }

    this.logger.error(
      `privacy-policy.html not found. Tried: ${candidates.join(', ')}`,
    );
    res.status(500).send('Privacy policy page is currently unavailable.');
  }
}
