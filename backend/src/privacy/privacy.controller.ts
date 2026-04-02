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
  private cachedHtml: string | null = null;

  @Get()
  getPrivacyPolicy(@Res() res: Response) {
    try {
      if (!this.cachedHtml) {
        this.cachedHtml = this.loadHtml();
      }

      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.setHeader('Cache-Control', 'public, max-age=86400');
      res.send(this.cachedHtml);
    } catch (error) {
      this.logger.error('Failed to serve privacy policy', error);
      res.status(500).send('Privacy policy page is currently unavailable.');
    }
  }

  private loadHtml(): string {
    // Try multiple paths since nest build asset copying and tsc output
    // may place the HTML in different locations depending on rootDir
    const candidates = [
      join(__dirname, 'privacy-policy.html'),
      join(process.cwd(), 'dist', 'privacy', 'privacy-policy.html'),
      join(process.cwd(), 'dist', 'src', 'privacy', 'privacy-policy.html'),
    ];

    for (const htmlPath of candidates) {
      if (existsSync(htmlPath)) {
        this.logger.log(`Serving privacy policy from: ${htmlPath}`);
        return readFileSync(htmlPath, 'utf-8');
      }
    }

    this.logger.warn(
      `privacy-policy.html not found at any path, using inline fallback. Tried: ${candidates.join(', ')}`,
    );
    return PRIVACY_POLICY_HTML;
  }
}

/**
 * Inline fallback HTML — used when the file cannot be found at runtime.
 * Keep in sync with src/privacy/privacy-policy.html
 */
const PRIVACY_POLICY_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - Kindred</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; background: #f9f9f9; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1); }
        h1 { font-size: 32px; font-weight: 700; margin-bottom: 10px; color: #1a1a1a; }
        .effective-date { font-size: 14px; color: #666; margin-bottom: 30px; }
        h2 { font-size: 24px; font-weight: 600; margin-top: 40px; margin-bottom: 16px; color: #1a1a1a; }
        h3 { font-size: 18px; font-weight: 600; margin-top: 24px; margin-bottom: 12px; color: #333; }
        p { margin-bottom: 16px; font-size: 16px; }
        ul, ol { margin-bottom: 16px; margin-left: 24px; }
        li { margin-bottom: 8px; }
        strong { font-weight: 600; color: #1a1a1a; }
        a { color: #007AFF; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .section { margin-bottom: 32px; }
        .data-type { background: #f5f5f5; padding: 16px; border-radius: 8px; margin-bottom: 16px; }
        .contact-info { background: #f0f8ff; padding: 20px; border-radius: 8px; margin-top: 40px; }
        @media (max-width: 640px) { body { padding: 10px; } .container { padding: 24px; } h1 { font-size: 28px; } h2 { font-size: 22px; } }
    </style>
</head>
<body>
    <div class="container">
        <h1>Privacy Policy</h1>
        <p class="effective-date">Effective Date: March 30, 2026</p>

        <div class="section">
            <h2>1. Introduction</h2>
            <p>Welcome to Kindred. We are committed to protecting your privacy and being transparent about how we collect, use, and protect your personal data.</p>
            <p>Kindred is an AI-powered cooking app that helps you discover recipes based on your dietary preferences and pantry contents. Our standout feature is voice cloning: you can upload a voice sample of a loved one, and we'll use it to narrate recipes in their voice, making cooking feel like a warm conversation with someone you care about.</p>
            <p><strong>Data Controller:</strong> Ersin Kirteke<br>
            <strong>Location:</strong> Vilnius, Lithuania (European Union)<br>
            <strong>Contact:</strong> <a href="mailto:privacy@kindred.app">privacy@kindred.app</a></p>
        </div>

        <div class="section">
            <h2>2. Data We Collect</h2>

            <h3>2.1 Voice Data (Biometric Identifier)</h3>
            <div class="data-type">
                <p><strong>What:</strong> Audio recordings of human speech (30-90 seconds) for AI voice cloning</p>
                <p><strong>Why:</strong> To create a personalized AI-cloned voice that narrates recipes in Kindred</p>
                <p><strong>How it works:</strong></p>
                <ul>
                    <li>You upload a voice recording via the app (requires explicit consent)</li>
                    <li>Audio is sent to <strong>ElevenLabs</strong> (third-party AI voice provider) for processing</li>
                    <li>Audio sample is stored in Cloudflare R2 storage (encrypted)</li>
                    <li>Voice is used ONLY for recipe narration within Kindred</li>
                    <li>Voice is NEVER shared with other users</li>
                </ul>
                <p><strong>Legal basis:</strong> Explicit consent (GDPR Article 6(1)(a) + Article 9(2)(a) for biometric data)</p>
                <p><strong>Retention:</strong> Stored until you delete it from Settings or close your account</p>
                <p><strong>Your rights:</strong> Delete your voice profile anytime from Settings → Privacy & Data</p>
            </div>

            <h3>2.2 Location Data</h3>
            <div class="data-type">
                <p><strong>What:</strong> City-level location (coarse location, not precise GPS)</p>
                <p><strong>Why:</strong> To show you trending recipes in your area</p>
                <p><strong>How it works:</strong></p>
                <ul>
                    <li>Location is detected once during onboarding (requires system permission)</li>
                    <li>Geocoded to city name using <strong>Mapbox</strong> API</li>
                    <li>Location is processed on-device first, then sent to Mapbox for city lookup</li>
                    <li>We do NOT store your GPS coordinates</li>
                </ul>
                <p><strong>Legal basis:</strong> Consent (GDPR Article 6(1)(a))</p>
                <p><strong>Retention:</strong> Location preference stored locally on your device (UserDefaults)</p>
                <p><strong>Your rights:</strong> Change location anytime from app settings</p>
            </div>

            <h3>2.3 Account Data</h3>
            <div class="data-type">
                <p><strong>What:</strong> Email address, Apple ID identifier (if you sign in with Apple)</p>
                <p><strong>Why:</strong> Authentication and account management</p>
                <p><strong>How it works:</strong></p>
                <ul>
                    <li>Authentication managed by <strong>Clerk</strong> (third-party auth provider)</li>
                    <li>If you sign in with Apple, we receive a privacy-preserving Apple ID token</li>
                    <li>Email is used for account recovery and security notifications (if provided)</li>
                </ul>
                <p><strong>Legal basis:</strong> Contract performance (GDPR Article 6(1)(b))</p>
                <p><strong>Retention:</strong> Until you delete your account</p>
            </div>

            <h3>2.4 Analytics & Diagnostics</h3>
            <div class="data-type">
                <p><strong>What:</strong> App usage events, crash logs, device model, OS version</p>
                <p><strong>Why:</strong> To improve app stability and understand how features are used</p>
                <p><strong>How it works:</strong></p>
                <ul>
                    <li>Collected via <strong>Firebase Analytics</strong> and <strong>Firebase Crashlytics</strong></li>
                    <li>Data is anonymous and aggregated</li>
                    <li>NOT linked to your account or identity</li>
                </ul>
                <p><strong>Legal basis:</strong> Legitimate interest (GDPR Article 6(1)(f))</p>
                <p><strong>Retention:</strong> 14 months (Firebase default)</p>
            </div>

            <h3>2.5 Advertising Data (Free Tier Only)</h3>
            <div class="data-type">
                <p><strong>What:</strong> Ad impressions, ad interactions</p>
                <p><strong>Why:</strong> To fund the free tier via non-personalized ads</p>
                <p><strong>How it works:</strong></p>
                <ul>
                    <li>Ads served by <strong>Google AdMob</strong></li>
                    <li>Kindred does NOT use personalized ads (no tracking across apps)</li>
                    <li>We do NOT request IDFA (Apple's advertising identifier)</li>
                    <li>Pro subscribers see NO ads</li>
                </ul>
                <p><strong>Legal basis:</strong> Legitimate interest (GDPR Article 6(1)(f))</p>
            </div>
        </div>

        <div class="section">
            <h2>3. Your Rights (GDPR)</h2>
            <p>As a user in the European Union, you have the following rights under GDPR:</p>

            <h3>3.1 Access & Portability</h3>
            <p>You can request a copy of your personal data in a machine-readable format (JSON). Email <a href="mailto:privacy@kindred.app">privacy@kindred.app</a> with subject "Data Export Request".</p>

            <h3>3.2 Deletion (Right to Erasure)</h3>
            <p>You can delete your data at any time:</p>
            <ul>
                <li><strong>Voice profile:</strong> Delete from Settings → Privacy & Data → Delete Voice Profile</li>
                <li><strong>Account:</strong> Email <a href="mailto:privacy@kindred.app">privacy@kindred.app</a> with subject "Delete My Account"</li>
            </ul>
            <p>Upon account deletion, we will:</p>
            <ul>
                <li>Delete your voice profile from ElevenLabs</li>
                <li>Delete your audio sample from R2 storage</li>
                <li>Anonymize your account data within 30 days</li>
            </ul>

            <h3>3.3 Withdraw Consent</h3>
            <p>You can withdraw consent for voice cloning or location access at any time:</p>
            <ul>
                <li><strong>Voice:</strong> Delete voice profile from Settings</li>
                <li><strong>Location:</strong> Revoke permission in iOS Settings → Kindred → Location</li>
            </ul>

            <h3>3.4 Object to Processing</h3>
            <p>You can object to analytics or advertising by:</p>
            <ul>
                <li>Disabling analytics in iOS Settings → Privacy & Security → Analytics & Improvements</li>
                <li>Upgrading to Pro (removes ads entirely)</li>
            </ul>

            <h3>3.5 Lodge a Complaint</h3>
            <p>If you believe we've violated your privacy rights, you can file a complaint with your national Data Protection Authority (DPA). In Lithuania: <a href="https://vdai.lrv.lt" target="_blank">State Data Protection Inspectorate</a>.</p>
        </div>

        <div class="section">
            <h2>4. Third-Party Services</h2>
            <p>Kindred uses the following third-party services to provide core functionality:</p>
            <ul>
                <li><strong>ElevenLabs</strong> (AI voice cloning): <a href="https://elevenlabs.io/privacy" target="_blank">Privacy Policy</a></li>
                <li><strong>Clerk</strong> (authentication): <a href="https://clerk.com/privacy" target="_blank">Privacy Policy</a></li>
                <li><strong>Firebase Analytics & Crashlytics</strong> (Google): <a href="https://firebase.google.com/support/privacy" target="_blank">Privacy Policy</a></li>
                <li><strong>Google AdMob</strong> (ads): <a href="https://policies.google.com/privacy" target="_blank">Privacy Policy</a></li>
                <li><strong>Mapbox</strong> (geocoding): <a href="https://www.mapbox.com/legal/privacy" target="_blank">Privacy Policy</a></li>
                <li><strong>Cloudflare R2</strong> (voice sample storage): <a href="https://www.cloudflare.com/privacypolicy/" target="_blank">Privacy Policy</a></li>
            </ul>
            <p>These services are bound by their own privacy policies and may process data in the United States. ElevenLabs and Cloudflare are GDPR-compliant and use Standard Contractual Clauses (SCCs) for EU data transfers.</p>
        </div>

        <div class="section">
            <h2>5. Data Security</h2>
            <p>We implement industry-standard security measures to protect your data:</p>
            <ul>
                <li><strong>Encryption in transit:</strong> TLS 1.3 for all network communication</li>
                <li><strong>Encryption at rest:</strong> AES-256 for voice samples in R2 storage</li>
                <li><strong>Access control:</strong> Voice samples accessible only to authenticated backend services</li>
                <li><strong>Regular audits:</strong> Third-party security reviews for backend infrastructure</li>
            </ul>
            <p>However, no method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.</p>
        </div>

        <div class="section">
            <h2>6. Children's Privacy</h2>
            <p>Kindred is not intended for children under the age of:</p>
            <ul>
                <li><strong>13 years old</strong> in the United States (COPPA compliance)</li>
                <li><strong>16 years old</strong> in the European Union (GDPR Article 8)</li>
            </ul>
            <p>We do not knowingly collect personal data from children. If you believe a child has provided us with personal data, please contact us at <a href="mailto:privacy@kindred.app">privacy@kindred.app</a> and we will delete it immediately.</p>
        </div>

        <div class="section">
            <h2>7. Changes to This Policy</h2>
            <p>We may update this Privacy Policy from time to time to reflect changes in:</p>
            <ul>
                <li>Our data practices</li>
                <li>Legal requirements</li>
                <li>New features</li>
            </ul>
            <p>Material changes will be notified via:</p>
            <ul>
                <li>In-app notification</li>
                <li>Email (if you've provided one)</li>
                <li>Updated effective date at the top of this page</li>
            </ul>
            <p>Your continued use of Kindred after changes constitutes acceptance of the updated policy.</p>
        </div>

        <div class="contact-info">
            <h2>8. Contact Us</h2>
            <p>For privacy-related questions, data requests, or to exercise your rights under GDPR:</p>
            <p>
                <strong>Data Controller:</strong> Ersin Kirteke<br>
                <strong>Email:</strong> <a href="mailto:privacy@kindred.app">privacy@kindred.app</a><br>
                <strong>Location:</strong> Vilnius, Lithuania (European Union)<br>
                <strong>Response time:</strong> Within 30 days (as required by GDPR Article 12)
            </p>
        </div>
    </div>
</body>
</html>`;
