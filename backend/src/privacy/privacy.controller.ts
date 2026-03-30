import { Controller, Get, Res } from '@nestjs/common';
import { Response } from 'express';
import { readFileSync } from 'fs';
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
  /**
   * GET /privacy
   *
   * Serves the privacy policy HTML page.
   * No authentication required - public route.
   */
  @Get()
  getPrivacyPolicy(@Res() res: Response) {
    const htmlPath = join(__dirname, 'privacy-policy.html');
    const html = readFileSync(htmlPath, 'utf-8');

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache for 1 day
    res.send(html);
  }
}
