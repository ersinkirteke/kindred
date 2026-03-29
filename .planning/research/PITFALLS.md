# Pitfalls Research: App Store Launch Prep

**Domain:** iOS app with AI voice cloning, in-app purchases, and advertising
**Researched:** 2026-03-30
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: ATT Consent Prompt Shown Before App Provides Value

**What goes wrong:**
App shows the App Tracking Transparency (ATT) permission prompt immediately on first launch before the user experiences any value from the app. This results in 25-35% opt-in rates instead of the 50-70% possible with proper timing.

**Why it happens:**
Developers assume ATT must be requested early because AdMob needs tracking authorization. They request it during onboarding before establishing user trust or explaining value.

**How to avoid:**
1. Never show ATT prompt on first launch
2. Implement pre-prompt education screen that explains personalized ads in benefit-focused language (8th grade reading level)
3. Show pre-prompt after user has experienced core value (completed onboarding, interacted with feed)
4. Use full-screen pre-prompt (outperforms modals by 30-35%)
5. Horizontal button layout (Continue / Learn More side-by-side generates 10-15% higher opt-in than vertical)
6. Trigger system ATT prompt immediately after user taps "Continue" on pre-prompt
7. Test pre-prompt designs: TikTok, Wise, Nike, Expedia, Fitbit, Strava, Pinterest, and Flo all use pre-prompt strategies

**Warning signs:**
- ATT prompt appears during first app launch
- No context or explanation before system prompt
- System prompt happens before user completes onboarding
- Opt-in rate below 40%
- AdMob not serving personalized ads due to low IDFA availability

**Phase to address:**
Phase focused on AdMob production setup (likely Phase 2 or 3 of v4.0)

**Sources:**
- [Mastering IDFA Opt-In Rates: The Complete AppTrackingTransparency Guide for iOS Apps](https://www.playwire.com/blog/mastering-idfa-opt-in-rates-the-complete-apptrackingtransparency-guide-for-ios-apps)
- [Opt-in design do's and don'ts for Apple's App Tracking Trans](https://www.adjust.com/blog/opt-in-design-for-apple-app-tracking-transparency-att-ios14/)
- [Mobile App Consent for iOS: A Deep Dive (2025)](https://secureprivacy.ai/blog/mobile-app-consent-ios-2025)

---

### Pitfall 2: Privacy Labels Don't Match Actual SDK Behavior

**What goes wrong:**
App Store privacy labels claim the app doesn't collect certain data types, but AdMob SDK, ElevenLabs API calls, Gemini Vision requests, or analytics SDKs actually do collect that data. Apple audits privacy labels and rejects apps or removes them entirely for inaccurate disclosures.

**Why it happens:**
Developers fill out privacy labels based on their own code without auditing what third-party SDKs collect. AdMob, Firebase, and other Google SDKs collect device identifiers, usage data, and diagnostics even when not using ATT tracking. AI API calls (ElevenLabs, Gemini) send user audio/images to external servers but this isn't disclosed.

**How to avoid:**
1. Audit every third-party SDK and API integration for data collection:
   - AdMob: Collects device identifiers, diagnostics, usage data even without ATT consent
   - Firebase Cloud Messaging: Collects device tokens, app usage patterns
   - ElevenLabs: User voice uploads sent to third-party servers for cloning
   - Gemini 2.0 Flash: User photos (fridge, receipts) sent to Google AI
   - Apollo GraphQL: May cache sensitive data locally
   - Clerk Auth: Email, Apple ID tokens sent to Clerk servers
2. Check each SDK's official privacy manifest or documentation
3. For each data type collected, determine if it's "linked to user" or "not linked to user"
4. Disclose third-party AI data sharing per Guideline 5.1.2(i) (added November 2025)
5. Update privacy labels before every App Store submission (don't rely on old labels)
6. Document all SDKs and their data collection in internal audit file

**Warning signs:**
- Privacy labels filled out once and never updated
- No audit trail of SDK data collection behavior
- SDK versions updated without privacy label review
- Rejection with message: "The app's privacy practices do not match the information provided"
- Apple sends inquiry: "We noticed your app uses [SDK] but doesn't disclose [data type]"

**Phase to address:**
Privacy compliance phase (likely Phase 6 or 7 of v4.0), before first App Store submission

**Sources:**
- [iOS App Store Review Guidelines 2026: Requirements, Rejections & Submission Guide](https://theapplaunchpad.com/blog/app-store-review-guidelines)
- [App Privacy Details - App Store - Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)
- [Using adMob & Analytics in my app and got rejected - Guideline 5.1.2](https://community.flutterflow.io/database-and-apis/post/using-admob-analytics-in-my-app-and-got-rejected---guideline-5-1-2---snbwdcrAhPAGqM2)

---

### Pitfall 3: Third-Party AI Data Sharing Not Disclosed Before First Use

**What goes wrong:**
App sends user data (voice clips, fridge photos, recipe preferences) to third-party AI services (ElevenLabs, Gemini) without explicit user consent or disclosure. App is rejected under Guideline 5.1.2(i) for sharing personal data with third-party AI without permission.

**Why it happens:**
Developers assume privacy policy and general terms acceptance covers AI data sharing. Apple's November 2025 guideline update requires explicit, purpose-specific disclosure before first AI API call — not after, not in privacy policy footnotes.

**How to avoid:**
1. Before FIRST voice upload to ElevenLabs: Show disclosure modal explaining "Your voice clip will be sent to ElevenLabs AI service to create a voice profile. [Learn More]"
2. Before FIRST fridge photo scan: Show disclosure explaining "Your photo will be sent to Google Gemini AI to identify ingredients. [Learn More]"
3. Disclosure must appear BEFORE data transmission, not during or after
4. Cannot rely on privacy policy link — disclosure must be clear, conspicuous, and near the action
5. Use non-technical language (8th grade reading level per Apple HIG)
6. Implement consent flags: `hasConsentedToVoiceCloning`, `hasConsentedToVisionAnalysis`
7. Store consent timestamp and version for audit trail
8. For recipe narration AI rewriting (Gemini): Disclose that "Recipe instructions are processed by AI for clarity"

**Warning signs:**
- AI features work without any specific consent flow
- Consent buried in general Terms of Service acceptance
- Privacy policy link used instead of explicit disclosure
- AI disclosure shown after data already sent
- No per-feature consent flags in code
- App Store rejection mentioning Guideline 5.1.2(i) or "third-party AI"

**Phase to address:**
Voice cloning consent phase (likely Phase 4 of v4.0) and AI scanning consent (same phase or Phase 5)

**Sources:**
- [Apple Updates App Review Guidelines: Third-Party AI Calls Must Be Disclosed and Approved by the User](https://news.aibase.com/news/22810)
- [Apple's new App Review Guidelines clamp down on apps sharing personal data with 'third-party AI'](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)
- [Apple Silently Regulated Third-Party AI—Here's What Every Developer Must Do Now](https://dev.to/arshtechpro/apples-guideline-512i-the-ai-data-sharing-rule-that-will-impact-every-ios-developer-1b0p)

---

### Pitfall 4: Voice Cloning Consent Framework Missing Legal Requirements

**What goes wrong:**
App allows users to upload voice clips of "loved ones" (mom, grandma) without verifying consent from the person being cloned. When legal issue arises (user clones celebrity voice, uploads without permission, uses for commercial purpose), app has no consent audit trail or terms protecting it from liability. State laws (Tennessee ELVIS Act, California AB 1836, New York digital replica laws) impose penalties.

**Why it happens:**
Developers assume ElevenLabs handles consent verification. ElevenLabs ToS requires app developers to obtain consent, but provides no enforcement mechanism. Developer doesn't implement identity verification or consent documentation.

**How to avoid:**
1. Before voice cloning feature launch, budget $20-50K for AI/media legal counsel (per PROJECT.md constraints)
2. Implement consent attestation flow: User must check "I have permission to clone this voice" before upload
3. Store consent record: Who uploaded, when, whose voice, consent attestation timestamp
4. Block professional voice cloning of others (ElevenLabs policy: only clone your own voice for PVC)
5. Implement abuse reporting mechanism for unauthorized voice cloning
6. Add ToS clause: "You represent and warrant you have legal right to clone this voice"
7. For commercial use (Pro tier narration): Require stricter consent documentation
8. Consider requiring uploader to record consent phrase: "I [name] consent to my voice being cloned"
9. Geofence features if specific states require stricter rules (Tennessee, California, New York)
10. Follow ElevenLabs consent requirements: scope, duration, compensation disclosure, revocation process

**Warning signs:**
- No consent attestation checkbox before voice upload
- No audit trail of who uploaded which voice
- ToS doesn't mention voice cloning rights
- No mechanism to report/remove unauthorized voice clones
- Legal counsel not consulted before voice cloning launch
- User can upload any voice without identity verification
- No distinction between personal use vs. commercial use consent

**Phase to address:**
Voice cloning consent framework phase (likely Phase 4 of v4.0, before voice feature wire-up)

**Sources:**
- [Is Voice Cloning Legal? State-by-State Guide (2026 Update)](https://www.soundverse.ai/blog/article/is-voice-cloning-legal-state-by-state-guide-1041)
- [AI Voice Cloning Regulation in 2026: What's Legal, What's Risky, and How to Stay Compliant](https://aitribune.net/2026/02/24/ai-voice-cloning-regulation-in-2026/)
- [ElevenLabs Voice Cloning in 2026: Consent Rules, Terms of Service Updates, and a Simple Compliance Checklist](https://margabagus.com/elevenlabs-voice-cloning-consent/)
- [Synthetic Media & Voice Cloning: Right of Publicity Risks for 2026](https://holonlaw.com/entertainment-law/synthetic-media-voice-cloning-and-the-new-right-of-publicity-risk-map-for-2026/)

---

### Pitfall 5: JWS Receipt Validation Uses Base64 Decoding Without Certificate Chain Verification

**What goes wrong:**
Backend validates StoreKit 2 JWS receipts by decoding base64url payload without verifying x5c certificate chain or OCSP revocation status. Attacker generates fake receipts with valid-looking payload, backend grants Pro access without payment. Financial loss from fraud.

**Why it happens:**
Developer reads "StoreKit 2 uses JWS" and implements simple base64url decoding without understanding cryptographic verification requirements. PROJECT.md shows current implementation uses base64url decoding (marked as "needs SignedDataVerifier for production"). Developer assumes client-side StoreKit verification is sufficient — it's not, server must verify independently.

**How to avoid:**
1. Never trust client-provided receipt data without server-side cryptographic verification
2. Implement full x5c certificate chain validation:
   - Extract 3 certificates from JWS x5c header (leaf, intermediate, root)
   - Download Apple Root CA certificate from Apple PKI
   - Verify leaf certificate signed by intermediate certificate
   - Verify intermediate certificate signed by root certificate
   - Check OCSP (Online Certificate Status Protocol) for revocation status of leaf certificate
   - Check OCSP for revocation status of intermediate certificate
   - Extract public key from verified leaf certificate
   - Verify JWS signature using extracted public key
3. Use Apple's official StoreKit server libraries (Swift, Java, Python, Node.js available since WWDC 2023)
4. For NestJS backend: Use Node.js SignedDataVerifier library or equivalent
5. Implement receipt caching with Redis to avoid repeated verification of same transaction
6. Add transaction ID deduplication to prevent replay attacks
7. Test with fake receipts to verify server properly rejects them

**Warning signs:**
- Backend code only decodes base64url without signature verification
- No x5c certificate chain validation in code
- No OCSP revocation checking
- Comments like "TODO: Add proper verification" in production code
- Security audit flags receipt validation as vulnerability
- Only client-side StoreKit verification, no server verification
- PROJECT.md TODO: "JWS verification needs SignedDataVerifier upgrade for production"

**Phase to address:**
Production IAP validation phase (likely Phase 2 of v4.0, critical for App Store launch)

**Sources:**
- [Validate StoreKit2 in-app purchase - Apple Developer Forums](https://developer.apple.com/forums/thread/691464)
- [Verifying JWS for StoreKit 2 in-app purchase](https://mixi-developers.mixi.co.jp/verifying-jws-for-storekit-2-in-app-purchase-3dae64302d8)
- [StoreKit 2 JWS Validation in Node.js: Verify Receipts Without Public Keys](https://openillumi.com/en/en-storekit2-jws-validation-nodejs/)
- [Meet StoreKit 2 - WWDC21](https://developer.apple.com/videos/play/wwdc2021/10114/)

---

### Pitfall 6: Push Notification Device Tokens Not Registered with Backend

**What goes wrong:**
iOS app registers for push notifications, receives device token from APNs, but never sends token to backend. Backend cannot deliver expiry alerts or engagement notifications because it doesn't have user's device token. Users miss important expiry alerts for food items.

**Why it happens:**
Developer implements local notification permission request and receives token, but forgets backend registration step. PROJECT.md shows "EXPIRY-02 partial: device token registered locally but not sent to backend for push delivery." FCM integration incomplete — APNs token obtained but not mapped to FCM registration token.

**How to avoid:**
1. After receiving APNs device token, immediately send to backend via GraphQL mutation:
   ```graphql
   mutation RegisterDeviceToken($token: String!, $platform: String!) {
     registerDeviceToken(token: $token, platform: $platform) {
       success
     }
   }
   ```
2. Use Firebase Cloud Messaging as broker: APNs → FCM → Backend
3. Upload APNs authentication key (.p8 file) to Firebase Console under Project Settings → Cloud Messaging
4. Enable FCM method swizzling to automatically map APNs token to FCM token
5. Register device token on EVERY app launch, not just first launch (tokens can change after iOS updates, device restores)
6. Implement token refresh detection: Listen for `didReceiveRegistrationToken` callback
7. Send token with user ID association to backend
8. Backend stores: userId → fcmToken → platform mapping in database
9. Test token registration: Send test push notification from Firebase Console
10. Handle edge case: User denies permission then later enables → re-register token

**Warning signs:**
- Push notifications work in Firebase Console test but not from backend
- Device token printed in logs but no network request to backend
- Backend database has no device tokens stored
- Users report not receiving expiry alert notifications
- FCM integration exists but APNs key not uploaded to Firebase
- PROJECT.md TODO: "Device token not sent to backend"
- Token registration happens once but never refreshed

**Phase to address:**
Push notification delivery phase (likely Phase 3 of v4.0, after backend wiring phase)

**Sources:**
- [Get started with Firebase Cloud Messaging in Apple platform apps](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Registering device tokens | Customer.io Docs](https://docs.customer.io/journeys/device-tokens/)
- [How to Fix Azure Notification Hub Push Notification Delivery Failures](https://oneuptime.com/blog/post/2026-02-16-how-to-fix-azure-notification-hub-push-notification-delivery-failures-on-ios-and-android/view)

---

### Pitfall 7: AdMob Test Ad Unit IDs Not Replaced Before App Store Submission

**What goes wrong:**
App submitted to App Store with test ad unit IDs instead of production ad unit IDs. Apple reviewer opens app, sees "Test Ad" watermark or ads don't load. App rejected for incomplete functionality or crashes during review.

**Why it happens:**
Developer uses AdMob test IDs during development (correct practice) but forgets to replace with production IDs before submission. Build configuration doesn't differentiate between debug/release ad IDs. PROJECT.md shows "Test ad unit IDs in AdClient (must replace before App Store submission)."

**How to avoid:**
1. Create production ad units in AdMob console BEFORE App Store submission:
   - Interstitial ad unit for feed navigation
   - Native ad unit if using inline ads
   - App open ad unit if implementing splash ads
2. Store ad unit IDs in build configuration, not hardcoded:
   ```swift
   #if DEBUG
   static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ID
   #else
   static let interstitialAdUnitID = "ca-app-pub-XXXXXXXXXXXXX/YYYYYYYYYY" // Production ID
   #endif
   ```
3. Add App Store Review mode detection: Disable ads during review if causing issues
4. Wait for AdMob app approval: New apps must be reviewed by AdMob before serving real ads
5. Verify production ads work in TestFlight BEFORE App Store submission
6. iOS apps must be listed in App Store before Google ads will serve (chicken-egg problem):
   - First submission: Use production IDs, accept that ads won't serve during review
   - After approval: Ads will serve normally
7. Add pre-submission checklist item: "Verify production ad unit IDs in AdClient.swift"
8. Test ad loading in release build on physical device before submission

**Warning signs:**
- AdClient.swift contains hardcoded "ca-app-pub-3940256099942544" test IDs
- No build configuration differentiation for ad IDs
- "Test Ad" watermark visible on ads in release build
- AdMob console shows no ad requests from production app
- TestFlight build shows test ads instead of real ads
- PROJECT.md TODO: "Test ad unit IDs in AdClient"
- No AdMob app approval request submitted

**Phase to address:**
AdMob production setup phase (likely Phase 1 or 2 of v4.0, before App Store submission)

**Sources:**
- [Common Reasons For Ads Not Showing](https://docs.page/invertase/react-native-google-mobile-ads/common-reasons-for-ads-not-showing)
- [Apple support team rejected the app because ads are showing in test mode](https://github.com/capacitor-community/admob/issues/252)
- [AdMob production ads not working on iOS Testflight](https://groups.google.com/g/google-admob-ads-sdk/c/Z6R25tjDDM0)

---

### Pitfall 8: Scraped Recipe Content Violates Platform Terms or Copyright

**What goes wrong:**
App scrapes recipes from Instagram/X without permission, displays them in app. Instagram or X sends DMCA takedown notice or sues for ToS violation (unauthorized scraping). App Store removes app. Backend scraping infrastructure disabled by platform anti-bot measures (IP bans, TLS fingerprinting, rate limits).

**Why it happens:**
Developer knows scraping violates Instagram/X ToS (PROJECT.md: "Instagram/X ToS prohibit scraping") but proceeds anyway, assuming "everyone does it." Scraping works during development but breaks in production when platforms detect automation. No fallback source for recipe content.

**How to avoid:**
1. Implement abstraction layer for recipe sources (PROJECT.md: "Build abstraction layer, diversify sources")
2. Add official API integrations where available:
   - X API v2 (paid, starts at $42K/year for 100 tweets — prohibitively expensive)
   - Instagram Basic Display API (only for user's own content, not discovery)
3. Partner with recipe aggregators or content platforms with legal data access
4. Implement user-generated content path: Users submit/share recipes they find
5. License recipe database from established provider
6. Fallback mode: App works without scraping using cached/licensed content (PROJECT.md: "ensure app works without scraping as fallback")
7. Attribution system: Link back to original Instagram/X posts for user discovery
8. Recipe copyright: Ingredient lists aren't copyrightable, but "substantial literary expression" (stories, photos) is
9. For MVP: Use public domain recipes, user submissions, or licensed content instead of scraping
10. If scraping: Implement respectful rate limiting, robots.txt compliance, user-agent identification

**Warning signs:**
- App's core value proposition depends entirely on scraped content
- No legal review of scraping approach
- No fallback content source if scraping disabled
- PROJECT.md constraint: "Instagram/X ToS prohibit scraping"
- Backend logs show 403 errors, IP bans, or CAPTCHA challenges from Instagram/X
- Scraping breaks after platform updates doc_ids or API endpoints
- No official API integrations or content partnerships
- App Store description mentions "Instagram recipes" without partnership disclosure

**Phase to address:**
Not in v4.0 scope (v1.5 implementation already complete), but legal review phase should assess risk and implement fallback content sources

**Sources:**
- [Instagram Data Leak 2026: 17.5M Users & API Security Failures](https://guptadeepak.com/the-instagram-api-scraping-crisis-when-public-data-becomes-a-17-5-million-user-breach/)
- [X.com filed a lawsuit against Bright Data for unauthorized scraping](https://liveproxies.io/blog/x-twitter-scraping)
- [Copyright Protection in Recipes](https://www.copyrightlaws.com/copyright-protection-recipes/)
- [Social Media Scraping in 2026](https://scrapfly.io/blog/posts/social-media-scraping)

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Base64url JWS decoding without x5c verification | Fast implementation (1 hour vs 1 day) | Receipt fraud, financial loss, security audit failure | MVP only with "TODO: Production" comment, never for App Store launch |
| Test ad unit IDs in production | Avoid AdMob app approval wait time | App Store rejection, no ad revenue, crashes during review | Debug builds only, never release builds |
| ATT prompt on first launch | Simple implementation, no pre-prompt design needed | 25-35% opt-in rate (lose 50% potential ad revenue) | Never acceptable — pre-prompt is table stakes |
| Privacy labels filled once, never updated | Save 15 minutes per SDK update | App Store rejection, removal from store, loss of user trust | Never acceptable — audit on every SDK version bump |
| No third-party AI disclosure | Avoid "scary" AI permission prompts | App Store rejection under Guideline 5.1.2(i), mandatory since Nov 2025 | Never acceptable post-Nov 2025 |
| Voice cloning without consent attestation | Faster feature launch, fewer friction points | Legal liability, state law violations, user abuse, reputational damage | Never acceptable — legal requirement in multiple states |
| Device tokens not sent to backend | Feature appears complete on device | Push notifications silently fail, users miss alerts, support burden | Never acceptable — notifications are core feature |
| Info.plist permission strings as placeholders | Quick permission setup during prototyping | App Store rejection for unclear purpose strings | Development only, must clarify before submission |
| Hardcoded production secrets in code | No config system needed | Security breach, credentials leaked in Git history, emergency rotation | Never acceptable — use environment variables |
| Scraping without fallback content | Fastest path to content, no partnerships needed | Platform bans, legal action, app becomes unusable | Never acceptable for core features (PROJECT.md: fallback required) |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| AdMob + ATT | Requesting ATT on first launch before user sees value | Show pre-prompt after onboarding, explain benefits, full-screen design, 50-70% opt-in |
| StoreKit 2 JWS | Base64 decoding payload without x5c certificate chain verification | Verify leaf → intermediate → root certificate chain, check OCSP revocation, use SignedDataVerifier |
| ElevenLabs Voice Cloning | Assuming ElevenLabs handles consent verification | App must obtain consent, store audit trail, verify uploader has rights (ElevenLabs ToS) |
| Firebase Cloud Messaging | Receiving APNs token but not sending to backend | Map APNs token to FCM token via method swizzling, register on every launch, handle refresh |
| AdMob Production Setup | Submitting with test ad unit IDs | Use build config for debug/release IDs, verify production IDs in TestFlight, wait for AdMob approval |
| Gemini 2.0 Flash API | Sending user photos without AI disclosure | Show disclosure before first scan: "Your photo will be sent to Google Gemini AI" per Guideline 5.1.2(i) |
| Clerk Auth | Checking user state immediately after signInWithApple() | Poll Clerk.shared.user after auth — SDK updates async (PROJECT.md: known issue) |
| Privacy Labels | Filling based on own code without auditing SDKs | Audit each SDK's data collection, check privacy manifests, update labels on SDK version changes |
| X/Instagram Scraping | Directly scraping without fallback or legal review | Implement abstraction layer, fallback content source, respect ToS, consider licensing (PROJECT.md) |
| Cloudflare R2 CORS | Using wildcard "*" for AllowedHeaders | Set AllowedHeaders to specific list like "content-type", AllowedMethods to "PUT", AllowedOrigins can be "*" |
| APNs Certificate Updates | Using expired APNs certificate or old root CA | Apple transitioned to USERTrust RSA CA (SHA-2 root) — update certificate authority before Feb 2026 |
| Camera Permission | Vague Info.plist NSCameraUsageDescription | Provide clear, concise explanation: "To scan fridge contents for ingredient identification" (not "Camera access") |
| Subscription Grace Period | Not checking grace period state in StoreKit 2 | Check subscription.state for `.inGracePeriod`, grant access, show payment update prompt, test in sandbox |
| Silent Push Notifications | Sending more than once per 20-21 minutes | Apple throttles or blocks delivery if sent too frequently, use batch delivery for expiry alerts (PROJECT.md: 8 AM UTC) |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Receipt verification on every app launch | Launch time increases to 2-3 seconds, API rate limits hit | Cache verified receipt with Redis/in-memory, TTL 1 hour, verify only on purchase/restore | 10K+ daily active users |
| FCM token registration on every network request | Backend overload, DB writes saturate | Register only on app launch and token refresh, deduplicate by comparing old vs new token | 50K+ daily active users |
| Privacy label audit manual process | Missing SDK updates, human error, inconsistent labels | Automate SDK privacy manifest scanning, CI/CD check before release, JSON schema validation | Every submission as app grows |
| AdMob ad requests without caching/batching | Network overhead, battery drain, poor UX | Preload interstitial ads, cache for 1 hour, batch native ad requests, respect user interaction | 100K+ monthly users |
| Voice profile generation without queue | ElevenLabs rate limits, failed uploads, poor UX | Implement background job queue (Redis + BullMQ), retry logic, user notification on completion | 1K+ voice uploads/day |
| Gemini vision analysis synchronous | Upload times out, UI freezes, poor UX | Background task with progress indicator, queue system, fallback to manual entry on timeout | 10K+ scans/day |
| Push notification delivery without batching | Firebase quota exceeded, throttling, delays | Batch notifications (e.g., 8 AM UTC expiry digest per PROJECT.md), respect platform limits | 100K+ active users |
| OCSP revocation check on every JWS verification | 500ms+ latency per receipt check, OCSP server load | Cache OCSP responses (short TTL 1-4 hours), async background verification, fail-open on timeout | 50K+ transactions/day |
| APNs stale token accumulation | Backend DB bloat, wasted push attempts, delivery failures | Implement token cleanup job: Remove tokens with repeated delivery failures after 30 days | 500K+ registered tokens |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| No JWS signature verification on backend | Receipt fraud, unlimited Pro access without payment, financial loss | Implement x5c certificate chain validation, OCSP revocation checking, use SignedDataVerifier library |
| Voice cloning without consent audit trail | Legal liability, impersonation fraud, state law violations (ELVIS Act, AB 1836) | Store: uploader ID, voice owner name, consent timestamp, attestation, revocation mechanism |
| APNs tokens stored unencrypted | Token theft enables push notification spam to users | Encrypt tokens at rest (AES-256), use AWS KMS or equivalent, rotate encryption keys annually |
| Third-party AI API keys in client app | API key theft, unlimited usage, $10K+ unexpected bills | All AI calls through backend proxy, enforce rate limits, budget caps per user |
| No rate limiting on voice upload endpoint | Abuse, storage costs, ElevenLabs bill explosion | Enforce: Free tier 1 upload, Pro tier 10 uploads, 60-second max duration, file size limits |
| Scraped content without attribution | DMCA takedown, copyright infringement, lawsuit | Link to original source, respect robots.txt, implement user reporting, fallback licensed content |
| User photos sent to Gemini without encryption | Man-in-the-middle attack, photo leak, privacy violation | Use HTTPS for all API calls (default), validate SSL certificates, consider end-to-end encryption |
| No CSRF protection on device token registration | Token hijacking, push notification to wrong user | Include auth token in registration request, validate user session, use Firebase Cloud Messaging Security |
| Hardcoded production secrets | Git leak, credential theft, full backend compromise | Use environment variables, AWS Secrets Manager, rotate keys quarterly, .gitignore .env files |
| No input validation on recipe scraping | XSS injection, SQL injection via recipe data, backend compromise | Sanitize all scraped content, validate against schema, escape HTML, use parameterized queries |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| ATT prompt with no context | User confused, taps "Don't Allow", ads never personalized, lower revenue | Pre-prompt education: "See recipes you'll love with personalized recommendations" → 50-70% opt-in |
| Voice upload fails without explanation | User thinks feature broken, abandons voice cloning | Show specific error: "Voice clip must be 30-60 seconds" with re-record button |
| Push notification permission on first launch | User denies, never sees expiry alerts | Request after user adds first pantry item: "Get notified before food expires" |
| AI disclosure uses technical jargon | User doesn't understand, concerned about privacy | Use plain language: "Your photo is analyzed by AI to identify ingredients" (not "sent to Gemini 2.0 Flash API") |
| Subscription grace period silent failure | Card declined, user loses Pro access immediately | Show gentle prompt: "Payment issue - update card to keep Pro features" during grace period |
| Camera permission without purpose | User denies, can't use fridge scanning | Request in context: User taps "Scan Fridge" → permission prompt with clear purpose string |
| Recipe narration starts without consent | User startled by voice, doesn't know about cloning | Onboarding step: "Upload a voice clip to hear recipes in that voice" with example |
| Ad loads during recipe step | User can't see next instruction, food burns, frustration | Never show interstitial during active cooking (playback in progress) — only between recipes |
| Expiry notification too late | Food already spoiled, user lost trust | Notify 2 days before expiry (PROJECT.md: AI estimation), not on expiry day |
| Receipt validation failure silent | User paid, didn't receive Pro access, support ticket | Show error: "Verifying purchase..." with retry button, contact support link |

---

## "Looks Done But Isn't" Checklist

- [ ] **ATT Consent:** Permission requested but pre-prompt education missing — verify full-screen pre-prompt shown after onboarding, not on first launch
- [ ] **Privacy Labels:** Labels filled but not audited against SDK behavior — verify AdMob, Firebase, ElevenLabs, Gemini disclosures match actual data collection
- [ ] **Third-Party AI Disclosure:** AI features work but no Guideline 5.1.2(i) disclosure — verify modal shown before first voice upload and photo scan
- [ ] **Voice Cloning Consent:** Upload works but no consent attestation — verify checkbox "I have permission to clone this voice" and audit trail storage
- [ ] **JWS Validation:** Backend accepts receipts but no x5c verification — verify certificate chain validation, OCSP checks, SignedDataVerifier library used
- [ ] **Device Token Registration:** Token received but not sent to backend — verify GraphQL mutation called with FCM token after every app launch
- [ ] **Production Ad Unit IDs:** Ads load but using test IDs — verify release build configuration uses production IDs from AdMob console
- [ ] **Recipe Content Attribution:** Recipes display but no source links — verify attribution to Instagram/X posts, fallback content source implemented
- [ ] **Camera Permission Purpose:** Permission requested but vague Info.plist string — verify NSCameraUsageDescription explains ingredient scanning clearly
- [ ] **Subscription Grace Period:** Subscriptions work but no grace period handling — verify StoreKit 2 checks `.inGracePeriod` state and shows payment prompt
- [ ] **Push Notification Delivery:** Notifications sent but APNs key not uploaded — verify .p8 file uploaded to Firebase Console Cloud Messaging settings
- [ ] **AI Disclosure Language:** Disclosure shown but uses technical jargon — verify 8th grade reading level, plain language, benefit-focused (not scary)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| ATT prompt shown too early | LOW | Update app with pre-prompt, resubmit, communicate change to users (opt-in rate will improve for new users) |
| Privacy labels inaccurate | LOW | Audit all SDKs, update labels in App Store Connect, resubmit metadata (no code change needed) |
| No third-party AI disclosure | MEDIUM | Add disclosure modals, version gate (show for new users + existing users on first AI use after update), resubmit app |
| Voice cloning without consent | HIGH | Add consent attestation, version gate existing voice profiles (require re-consent), legal review, potentially disable feature temporarily |
| JWS validation missing x5c verification | HIGH | Implement SignedDataVerifier, audit all existing Pro subscriptions, contact affected users, refund fraud victims, security audit |
| Device tokens not registered | LOW | Add registration mutation, trigger on app launch, backfill existing users (prompt permission re-request if needed) |
| Test ad unit IDs in production | LOW | Update to production IDs, fast-track resubmission, ads will start serving after approval (no user impact if free tier works) |
| Scraped content violates ToS | VERY HIGH | Immediate: Disable scraping, legal counsel, respond to DMCA/C&D. Long-term: Pivot to licensed content or partnerships, may require 4-8 weeks |
| Camera permission string rejected | LOW | Update Info.plist NSCameraUsageDescription, resubmit metadata (App Store Connect), approval typically 24-48 hours |
| Grace period not handled | MEDIUM | Add grace period state checking, show payment prompt, resubmit, communicate to affected users (prevent churn) |
| Push notifications fail (missing APNs key) | LOW | Upload .p8 key to Firebase Console, test delivery, no app resubmission needed (backend/Firebase config only) |
| Subscription fraud from fake receipts | VERY HIGH | Immediate: Revoke fraudulent Pro access, implement x5c verification, security audit, notify affected legitimate users, financial loss assessment |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| ATT prompt timing | Phase 2: AdMob Production Setup | Test: New user completes onboarding → sees pre-prompt → opt-in rate 50%+ |
| Privacy labels inaccurate | Phase 7: Privacy Compliance | Pre-submission checklist: Audit AdMob, Firebase, ElevenLabs, Gemini data collection vs labels |
| No AI disclosure | Phase 4: Voice Cloning Consent & Phase 5: AI Scanning Consent | Test: New user taps voice upload → disclosure modal before upload, same for fridge scan |
| Voice consent missing | Phase 4: Voice Cloning Consent Framework | Legal review checkpoint, consent attestation checkbox, audit trail storage verified |
| JWS validation weak | Phase 2: Production IAP Validation | Security audit: Attempt to validate fake receipt → backend rejects, x5c verification logged |
| Device tokens not registered | Phase 3: Push Notification Delivery | Test: Register device → send test notification from backend → verify delivery, check DB for token |
| Test ad unit IDs | Phase 1: AdMob Production Setup | Pre-submission checklist: Verify release build config has production IDs, TestFlight shows real ads |
| Recipe content violations | Not in v4.0 (legal review for existing scraping) | Legal review: ToS compliance assessment, fallback content source implemented and tested |
| Camera permission string | Phase 5: AI Scanning Consent | App Store submission metadata: NSCameraUsageDescription explains "ingredient scanning" clearly |
| Grace period not handled | Phase 2: Production IAP Validation | Test: Simulate failed renewal in sandbox → verify grace period detection, payment prompt shown |
| Push APNs key missing | Phase 3: Push Notification Delivery | Firebase Console check: Verify .p8 key uploaded, test push from console → device receives |
| Recipe copyright attribution | Not in v4.0 (future enhancement for post-scraping display) | Verify: Recipe detail view shows source link to original Instagram/X post |

---

## Sources

### ATT & Privacy
- [Mastering IDFA Opt-In Rates: The Complete AppTrackingTransparency Guide for iOS Apps](https://www.playwire.com/blog/mastering-idfa-opt-in-rates-the-complete-apptrackingtransparency-guide-for-ios-apps)
- [Opt-in design do's and don'ts for Apple's App Tracking Trans](https://www.adjust.com/blog/opt-in-design-for-apple-app-tracking-transparency-att-ios14/)
- [Mobile App Consent for iOS: A Deep Dive (2025)](https://secureprivacy.ai/blog/mobile-app-consent-ios-2025)
- [iOS App Store Review Guidelines 2026: Requirements, Rejections & Submission Guide](https://theapplaunchpad.com/blog/app-store-review-guidelines)
- [App Privacy Details - App Store - Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy strategies for iOS - Google AdMob Help](https://support.google.com/admob/answer/9997589)

### Third-Party AI Compliance
- [Apple Updates App Review Guidelines: Third-Party AI Calls Must Be Disclosed and Approved by the User](https://news.aibase.com/news/22810)
- [Apple's new App Review Guidelines clamp down on apps sharing personal data with 'third-party AI'](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/)
- [Apple Silently Regulated Third-Party AI—Here's What Every Developer Must Do Now](https://dev.to/arshtechpro/apples-guideline-512i-the-ai-data-sharing-rule-that-will-impact-every-ios-developer-1b0p)

### Voice Cloning Legal
- [Is Voice Cloning Legal? State-by-State Guide (2026 Update)](https://www.soundverse.ai/blog/article/is-voice-cloning-legal-state-by-state-guide-1041)
- [AI Voice Cloning Regulation in 2026: What's Legal, What's Risky, and How to Stay Compliant](https://aitribune.net/2026/02/24/ai-voice-cloning-regulation-in-2026/)
- [ElevenLabs Voice Cloning in 2026: Consent Rules, Terms of Service Updates, and a Simple Compliance Checklist](https://margabagus.com/elevenlabs-voice-cloning-consent/)
- [Synthetic Media & Voice Cloning: Right of Publicity Risks for 2026](https://holonlaw.com/entertainment-law/synthetic-media-voice-cloning-and-the-new-right-of-publicity-risk-map-for-2026/)

### StoreKit 2 & IAP
- [Validate StoreKit2 in-app purchase - Apple Developer Forums](https://developer.apple.com/forums/thread/691464)
- [Verifying JWS for StoreKit 2 in-app purchase](https://mixi-developers.mixi.co.jp/verifying-jws-for-storekit-2-in-app-purchase-3dae64302d8)
- [StoreKit 2 JWS Validation in Node.js: Verify Receipts Without Public Keys](https://openillumi.com/en/en-storekit2-jws-validation-nodejs/)
- [How to Handle Apple Billing Grace Period in an iOS App](https://adapty.io/blog/how-to-handle-apple-billing-grace-period/)
- [Implementing iOS Subscription Grace Periods](https://www.revenuecat.com/blog/engineering/ios-subscription-grace-periods/)

### Push Notifications
- [Get started with Firebase Cloud Messaging in Apple platform apps](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Registering device tokens | Customer.io Docs](https://docs.customer.io/journeys/device-tokens/)
- [How to Fix Azure Notification Hub Push Notification Delivery Failures](https://oneuptime.com/blog/post/2026-02-16-how-to-fix-azure-notification-hub-push-notification-delivery-failures-on-ios-and-android/view)
- [Why Most Mobile Push Notification Architecture Fails (And How to Fix It)](https://www.netguru.com/blog/why-mobile-push-notification-architecture-fails)

### AdMob
- [Common Reasons For Ads Not Showing](https://docs.page/invertase/react-native-google-mobile-ads/common-reasons-for-ads-not-showing)
- [Using adMob & Analytics in my app and got rejected - Guideline 5.1.2](https://community.flutterflow.io/database-and-apis/post/using-admob-analytics-in-my-app-and-got-rejected---guideline-5-1-2---snbwdcrAhPAGqM2)
- [Apple support team rejected the app because ads are showing in test mode](https://github.com/capacitor-community/admob/issues/252)
- [AdMob production ads not working on iOS Testflight](https://groups.google.com/g/google-admob-ads-sdk/c/Z6R25tjDDM0)

### Content & Scraping
- [Instagram Data Leak 2026: 17.5M Users & API Security Failures](https://guptadeepak.com/the-instagram-api-scraping-crisis-when-public-data-becomes-a-17-5-million-user-breach/)
- [X.com filed a lawsuit against Bright Data for unauthorized scraping](https://liveproxies.io/blog/x-twitter-scraping)
- [Copyright Protection in Recipes](https://www.copyrightlaws.com/copyright-protection-recipes/)
- [Social Media Scraping in 2026](https://scrapfly.io/blog/posts/social-media-scraping)

### Infrastructure
- [Configure CORS · Cloudflare R2 docs](https://developers.cloudflare.com/r2/buckets/cors/)
- [Pre-signed URLs & CORS on Cloudflare R2](https://mikeesto.medium.com/pre-signed-urls-cors-on-cloudflare-r2-c90d43370dc4)
- [App Store Rejection: Camera Access - Apple Developer Forums](https://developer.apple.com/forums/thread/113646)

---

*Pitfalls research for: App Store Launch Prep (v4.0)*
*Researched: 2026-03-30*
*Confidence: HIGH*
