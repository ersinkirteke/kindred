# Kindred — Privacy Policy Update

**Draft date:** 2026-04-06
**Intended hosting URL:** https://kindred.app/privacy
**Effective date:** [USER SETS THIS when copying to hosted site — recommended: Phase 28 submission date]
**Version:** 2.1 (adds Google AdMob disclosure for free-tier banner ads — IDFA via ATT, UMP for EU)

---

## Summary of Changes in This Update

1. Added **Spoonacular** as a named third-party data processor for recipe data.
2. Elevated **ElevenLabs** disclosure from the App Store description into the policy itself.
3. Added **Search History** as a collected data type (previously undeclared).
4. Described the backend proxy chain (`api.kindredcook.app`) between the app and Spoonacular.
5. No changes to retention periods, account deletion, or user rights.
6. Added **Google AdMob** disclosure (advertising network, IDFA via ATT, UMP for EU). Phase 27 omitted this because Phase 27 was scoped to Spoonacular only; Phase 27.1 reconciles the gap.

---

## Third-Party Data Processors

Kindred uses the following third-party services to deliver core features. Each processor receives only the data needed to perform its specific function.

### Spoonacular (Recipe Data Provider)

**Purpose.** We use the Spoonacular API to provide recipe search results, ingredient lists, cooking instructions, and nutrition estimates.

**Data sent.** When you search for recipes or apply dietary filters, we send your search keywords and filter selections (cuisine, diet type, intolerances) to our backend server at `api.kindredcook.app`. Our backend then forwards those queries to Spoonacular. Your user account identifier is **not** attached to the request; Spoonacular receives the query text only.

**Backend proxy chain.** Requests flow:
`Your device → api.kindredcook.app (our backend) → Spoonacular API`.
This architecture lets us cache popular recipes and stay under our daily API quota. Spoonacular never sees your device identifier or account id — only the anonymized query text our backend forwards.

**Data retention.** Spoonacular's own retention policies apply to query data sent to their API. Our backend caches recipe responses for 6 hours and then refreshes them.

**Spoonacular Privacy Policy:** https://spoonacular.com/food-api/privacy

**Nutrition disclaimer.** Nutrition values shown in the app (calories, macronutrients, servings) are estimates provided by Spoonacular. They are approximations suitable for general meal planning and are **not** intended for medical, therapeutic, or diagnostic use. Always consult a qualified healthcare professional for dietary advice.

### ElevenLabs (Voice Cloning — Pro Subscribers Only)

**Purpose.** ElevenLabs AI voice cloning technology creates the personalized recipe narration voices used by Kindred Pro subscribers ("Hear recipes in your loved one's voice").

**Data sent.** When you record a voice profile, your audio recording is uploaded to ElevenLabs for voice cloning. Voice audio is sent **only** with your explicit consent — you must accept the voice-consent screen (which names ElevenLabs) before any recording leaves your device. Voice audio is linked to your account so you can manage it later.

**User control.** You can delete a voice profile at any time from the Kindred Settings tab. Deletion removes the clone from our system and requests deletion from ElevenLabs on your behalf.

**ElevenLabs Privacy Policy:** https://elevenlabs.io/privacy

**Free-tier users.** If you do not have a Pro subscription, recipe narration uses Apple's built-in text-to-speech (AVSpeechSynthesizer) running on your device. No audio or text is sent to ElevenLabs for free users.

### Google AdMob (Advertising Network)

**Purpose.** We display banner advertisements on the free tier of Kindred using Google AdMob (the Google Mobile Ads SDK). Kindred Pro subscribers do not see any ads — the ad system is fully suppressed for Pro users.

**Data sent.** When you use the free tier, Google AdMob may collect:
- **Device ID (IDFA)** if you authorize App Tracking Transparency (ATT). If you deny ATT, personalized ads are disabled and AdMob operates in limited-data mode.
- **Advertising Data** (which ads you've seen, ad interactions) to measure ad performance and prevent fraud.
- **Coarse Location** (city-level) to show regionally relevant ads. This is separate from the location data Kindred uses to find local recipes (that data stays under "App Functionality" and is processed independently of AdMob).
- **Diagnostic Data** (SDK performance metrics, crash reports) used solely to maintain the AdMob SDK.

**User control / consent.** Before collecting your IDFA, Kindred displays the App Tracking Transparency prompt required by Apple. You can deny this request, and personalized ads will be disabled. EU users will also see a separate Google User Messaging Platform (UMP) consent form to comply with GDPR. You can change your ATT choice at any time in iOS Settings → Privacy & Security → Tracking.

**Data retention.** Google's retention policies apply to advertising data. See Google's privacy policy for details.

**AdMob Privacy Policy:** https://policies.google.com/technologies/ads
**AdMob Privacy FAQ:** https://support.google.com/admob/answer/6128543

---

## Data We Collect

This section lists every category of data we collect, linked to the corresponding entries in our App Store Privacy Label.

### Search History (NEW)

**What we collect.** Recipe search keywords and filter selections (cuisine, diet type, intolerances) you enter in the app.

**How it's used.** Sent to our backend, which forwards the query to Spoonacular to return matching recipes (see the Spoonacular section above).

**Linked to you.** No — search queries are proxied without your user identifier.

**Used for tracking.** No.

**Purpose.** App functionality (recipe search and filtering) only.

### Other Data Types

The following data types continue to be collected as described in the current App Store Privacy Label and were not changed by this update:

- **Audio Data** (voice recordings for ElevenLabs, Pro subscribers only) — Linked, not tracked, App Functionality.
- **Coarse Location** (city only, derived on-device) — Not linked, not tracked, App Functionality.
- **Email Address** (Clerk authentication) — Linked, not tracked, App Functionality.
- **User ID** (Clerk) — Linked, not tracked, App Functionality.
- **Product Interaction** (Firebase Analytics) — Linked, not tracked, Analytics.
- **Crash Data** (Firebase Crashlytics) — Not linked, not tracked, App Functionality.
- **Purchase History** (StoreKit) — Linked, not tracked, App Functionality.
- **Device ID (IDFA)** (Google AdMob, free tier only) — Not linked, **tracked**, Third-Party Advertising.
- **Advertising Data** (Google AdMob, free tier only) — Not linked, **tracked**, Third-Party Advertising.
- **Coarse Location (AdMob entry)** (Google AdMob, free tier only) — Not linked, **tracked**, Third-Party Advertising. Separate from the App Functionality Coarse Location entry above.
- **Other Diagnostic Data** (Google AdMob SDK telemetry) — Not linked, not tracked, Analytics.

---

## Contact

For privacy questions or data-access requests, email: [USER SETS CONTACT EMAIL]

---

*This document is the Phase 27 draft. Before Phase 28 submission, copy the content above to the hosted policy at https://kindred.app/privacy, set the Effective date and contact email, and preserve the Version field for audit history.*
