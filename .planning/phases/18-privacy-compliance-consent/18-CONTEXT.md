# Phase 18: Privacy Compliance & Consent Infrastructure - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

App meets all privacy disclosure and consent requirements for App Store submission. Covers: voice cloning consent screen, voice profile deletion from Settings, privacy policy (content + hosting + in-app link), PrivacyInfo.xcprivacy manifest, and Privacy Nutrition Labels documentation for App Store Connect.

</domain>

<decisions>
## Implementation Decisions

### Voice Consent Flow
- Full-screen modal sheet shown **before** the file picker opens, every time the user uploads a voice
- Consent required per upload (not once-per-user) — each voice sample gets its own consent record
- ElevenLabs named explicitly: "Your voice will be processed by ElevenLabs, an AI voice provider, to create a cloned voice for recipe narration."
- Consent screen includes 3-4 bullet points:
  - Voice is sent to ElevenLabs for AI cloning
  - Used only for recipe narration in Kindred
  - You can delete your voice anytime from Settings
  - Voice is never shared with other users
- Prominent Accept/Decline buttons on the consent sheet
- If user declines: sheet dismisses, user returns to where they were, no punitive messaging
- Audit trail stores: userId, timestamp, IP address, **app version** (added to existing backend fields)
- Mention deletability on the consent screen (not full retention policy — that lives in Privacy Policy)

### Voice Profile Deletion
- Lives in a new **"Privacy & Data" section** in ProfileView (Profile tab → Settings area)
- Shows a **simple card** with: speaker name, relationship, creation date, status (Ready/Processing/Failed), and a Delete button
- Section is **hidden** when no voice profile exists — keeps Settings clean
- Confirmation via **standard iOS destructive alert dialog**: "Delete Voice Profile?" with explanation that the cloned voice is permanently removed from ElevenLabs. Red "Delete" + Cancel buttons.
- **Loading spinner** shown during backend deletion (prevents double-taps)
- **Toast/banner message** on success: "Voice profile deleted."
- After deletion: existing narrations **fall back to default AI voice** — already-generated audio files persist on R2, only new narrations use default voice
- Scope: voice data deletion only — account deletion is a separate future phase

### Privacy Policy
- **Draft actual content** in this phase covering all data collection: ElevenLabs (voice), AdMob (ads), Firebase (analytics/crash), Mapbox (city detection), Clerk (auth)
- **Host on backend**: NestJS route at `/privacy` serving static HTML page (no separate domain yet)
- **In-app access**: SFSafariViewController opens the hosted URL from a "Privacy Policy" row in the Privacy & Data settings section
- Legal entity: personal name (Ersin Kirteke) as developer/data controller
- Include a **privacy-specific contact email** for inquiries (required for GDPR — user is in EU/Lithuania)
- Link in both: in-app Settings AND App Store Connect metadata

### PrivacyInfo.xcprivacy & Nutrition Labels
- **No IDFA usage, no cross-app/cross-site tracking** — ATT prompt not needed
- **Firebase only** for analytics and crash reporting (no Mixpanel, Amplitude, Sentry, etc.)
- **Mapbox**: location used only for city detection during onboarding, no persistent location tracking
- **Local storage**: UserDefaults for preferences/onboarding state, Keychain for Clerk auth tokens
- Data linkage: **Linked to Identity** for authenticated data (voice profiles, bookmarks), **Not Linked** for anonymous data (crash logs, basic analytics)
- Create **both**: PrivacyInfo.xcprivacy manifest AND a markdown checklist documenting exactly what to select in each App Store Connect nutrition label category

### Claude's Discretion
- Exact consent screen layout and typography within the full-screen sheet pattern
- PrivacyInfo.xcprivacy reason codes selection based on actual API usage audit
- Privacy policy section ordering and legal language
- Toast/banner implementation pattern for deletion feedback
- Backend `/privacy` route implementation details (static HTML vs template engine)

</decisions>

<specifics>
## Specific Ideas

- Consent bullet points should feel reassuring, not legal — keep language human
- Voice card in Settings should be informative but not cluttered — similar density to the existing SubscriptionStatusView
- Privacy policy should cover GDPR basics given EU presence (Lithuania)
- App Store Connect checklist should be a step-by-step guide the developer can follow during submission

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProfileReducer` / `ProfileView`: Existing profile tab where Privacy & Data section will be added. Currently has subscription, dietary prefs, culinary DNA sections.
- `VoiceUploadReducer`: Existing upload flow that needs consent gate injected before file picker. Has `UploadVoiceInput.consentGiven` boolean.
- `VoiceProfile` model: Existing model with id, name, avatarURL, sampleAudioURL, isOwnVoice, createdAt.
- `SubscriptionStatusView`: Existing card component in Profile — good pattern reference for the voice profile card.
- `KindredButton`: Design system button component for consistent styling on consent Accept/Decline.
- `KindredSpacing`, `Color.kindredBackground`, `.kindredHeading1Scaled`, etc.: Established design tokens.

### Established Patterns
- TCA (The Composable Architecture): All features use @Reducer pattern with State/Action/body.
- Backend consent: `VoiceService.uploadVoice()` already validates `consentGiven`, stores `consentedAt` + `consentIpAddress` in Prisma.
- Backend deletion: `VoiceService.deleteVoiceProfile()` handles full cleanup (ElevenLabs + R2 + status update).
- Localization: All UI strings use `String(localized:bundle:)` pattern with Localizable.xcstrings.

### Integration Points
- `VoiceUploadReducer` — inject consent gate before `.selectFile` action
- `ProfileReducer` / `ProfileView` — add Privacy & Data section with voice management + privacy policy link
- `backend/prisma/schema.prisma` — may need `consentAppVersion` field added to VoiceProfile model
- `backend/src/voice/voice.service.ts` — update `uploadVoice()` to accept and store app version
- `backend/src/voice/dto/upload-voice.input.ts` — add `appVersion` field to UploadVoiceInput
- `Kindred/Sources/Info.plist` (actual Info.plist per project.yml) — PrivacyInfo.xcprivacy manifest location
- NestJS backend — new `/privacy` GET route for hosting privacy policy HTML

</code_context>

<deferred>
## Deferred Ideas

- **Account deletion** — App Store requires it eventually, but scoped as a separate future phase
- **ATT prompt** — Not needed currently (no IDFA usage), but if AdMob config changes to use IDFA, will need its own implementation

</deferred>

---

*Phase: 18-privacy-compliance-consent*
*Context gathered: 2026-03-30*
