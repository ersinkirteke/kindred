# Phase 18: Privacy Compliance & Consent Infrastructure - Research

**Researched:** 2026-03-30
**Domain:** iOS privacy compliance, App Store submission requirements, GDPR consent
**Confidence:** HIGH

## Summary

Phase 18 implements privacy compliance infrastructure required for App Store submission, focusing on voice cloning consent (biometric data under GDPR), PrivacyInfo.xcprivacy manifest with Required Reason APIs, Privacy Nutrition Labels documentation, and hosted privacy policy. This is a foundational compliance phase blocking App Store launch.

The research reveals that voice data is classified as **special category biometric data** under GDPR (since 2018), requiring explicit consent with affirmative action before processing. Apple requires privacy manifests starting February 2025 for SDKs using Required Reason APIs (UserDefaults, Firebase, AdMob all require declarations). Privacy policies must be publicly hosted and linked in both in-app Settings and App Store Connect metadata.

**Primary recommendation:** Implement consent flow as a full-screen modal (`.fullScreenCover`) with `.interactiveDismissDisabled()` to prevent accidental dismissal, store consent audit trail including app version (for legal defense), use SwiftUI `.confirmationDialog` with destructive style for voice deletion, and host privacy policy as static HTML via NestJS route at `/privacy` opened in-app via `SFSafariViewController`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Voice Consent Flow:**
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

**Voice Profile Deletion:**
- Lives in a new **"Privacy & Data" section** in ProfileView (Profile tab → Settings area)
- Shows a **simple card** with: speaker name, relationship, creation date, status (Ready/Processing/Failed), and a Delete button
- Section is **hidden** when no voice profile exists — keeps Settings clean
- Confirmation via **standard iOS destructive alert dialog**: "Delete Voice Profile?" with explanation that the cloned voice is permanently removed from ElevenLabs. Red "Delete" + Cancel buttons.
- **Loading spinner** shown during backend deletion (prevents double-taps)
- **Toast/banner message** on success: "Voice profile deleted."
- After deletion: existing narrations **fall back to default AI voice** — already-generated audio files persist on R2, only new narrations use default voice
- Scope: voice data deletion only — account deletion is a separate future phase

**Privacy Policy:**
- **Draft actual content** in this phase covering all data collection: ElevenLabs (voice), AdMob (ads), Firebase (analytics/crash), Mapbox (city detection), Clerk (auth)
- **Host on backend**: NestJS route at `/privacy` serving static HTML page (no separate domain yet)
- **In-app access**: SFSafariViewController opens the hosted URL from a "Privacy Policy" row in the Privacy & Data settings section
- Legal entity: personal name (Ersin Kirteke) as developer/data controller
- Include a **privacy-specific contact email** for inquiries (required for GDPR — user is in EU/Lithuania)
- Link in both: in-app Settings AND App Store Connect metadata

**PrivacyInfo.xcprivacy & Nutrition Labels:**
- **No IDFA usage, no cross-app/cross-site tracking** — ATT prompt not needed in this phase
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

### Deferred Ideas (OUT OF SCOPE)

- **Account deletion** — App Store requires it eventually, but scoped as a separate future phase
- **ATT prompt** — Not needed currently (no IDFA usage), but if AdMob config changes to use IDFA, will need its own implementation (Phase 20)

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PRIV-02 | Privacy Nutrition Labels accurately declare all data collection in App Store Connect | Standard Stack: 14-category questionnaire, Code Examples: AdMob/Firebase/Mapbox declarations |
| PRIV-03 | PrivacyInfo.xcprivacy manifest declares tracking domains and API usage with approved reason codes | Standard Stack: Xcode 15 .xcprivacy editor, Architecture Patterns: NSPrivacyAccessedAPITypes structure, Code Examples: CA92.1 for UserDefaults |
| PRIV-04 | Voice cloning consent screen shown before first voice upload naming ElevenLabs as AI provider | Architecture Patterns: fullScreenCover with interactiveDismissDisabled, Code Examples: VoiceUploadReducer integration |
| PRIV-05 | Voice consent audit trail stores userId, timestamp, IP, and app version in backend | Don't Hand-Roll: Backend already has consentedAt/consentIpAddress fields, just add appVersion to Prisma schema |
| PRIV-06 | User can delete voice profile from Settings with confirmation dialog | Architecture Patterns: SwiftUI confirmationDialog with destructive role, Code Examples: ProfileView Privacy & Data section |
| PRIV-07 | Privacy Policy hosted at public URL and linked in App Store Connect | Architecture Patterns: NestJS static route, SFSafariViewController in-app display |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI `.fullScreenCover` | iOS 14+ | Present voice consent modal | Apple's standard for immersive, undismissible modals requiring explicit user action |
| SwiftUI `.confirmationDialog` | iOS 15+ | Delete confirmation dialog | iOS native pattern for destructive actions with automatic cancel button and red styling |
| `SFSafariViewController` | iOS 9+ | Display privacy policy in-app | Apple-required pattern for web content, maintains privacy (no cookie sharing) |
| `PrivacyInfo.xcprivacy` | Required 2025+ | Declare Required Reason API usage | Apple's mandatory privacy manifest format, edited via Xcode 15+ property list editor |
| NestJS static routes | NestJS 10+ | Serve privacy policy HTML | Backend already uses NestJS, simple `@Get('/privacy')` controller |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ToastNotification` | Existing | Success feedback after deletion | Project's design system component for ephemeral messages |
| `CardSurface` | Existing | Voice profile card in Settings | Project's design system component for card-based UI |
| `KindredButton` | Existing | Consent Accept/Decline buttons | Project's design system button with WCAG AAA 56dp touch target |
| Prisma `VoiceProfile` | Existing | Store consent metadata | Backend already has `consentedAt`, `consentIpAddress` fields |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `fullScreenCover` | `sheet` | Sheet can be dismissed by dragging, violates "explicit consent" requirement under GDPR |
| `confirmationDialog` | Custom alert view | Custom view requires more code, loses iOS native styling and accessibility |
| NestJS static HTML | External privacy generator service | External services add dependencies, hosting on backend keeps control |
| Manual XML editing | Xcode property list editor | Manual XML editing error-prone, Xcode editor provides dropdowns with valid reason codes |

**Installation:**

No new dependencies required. All components are iOS native or already in project.

## Architecture Patterns

### Recommended Project Structure

```
Kindred/
├── Packages/
│   ├── VoicePlaybackFeature/
│   │   └── Sources/
│   │       ├── VoiceUpload/
│   │       │   ├── VoiceUploadReducer.swift      # Add consent gate before .selectFile
│   │       │   ├── VoiceUploadView.swift          # Existing file picker UI
│   │       │   └── VoiceConsentView.swift         # NEW: Full-screen consent modal
│   │       └── Models/
│   │           └── VoiceProfile.swift             # Existing model
│   ├── ProfileFeature/
│   │   └── Sources/
│   │       ├── ProfileReducer.swift               # Add Privacy & Data section state
│   │       ├── ProfileView.swift                  # Add Privacy & Data section UI
│   │       ├── PrivacyDataSection.swift           # NEW: Voice management + policy link
│   │       └── VoiceProfileCardView.swift         # NEW: Voice profile display card
│   └── DesignSystem/
│       └── Sources/
│           └── Components/
│               ├── KindredButton.swift            # Existing (use for Accept/Decline)
│               ├── ToastNotification.swift        # Existing (use for deletion feedback)
│               └── CardSurface.swift              # Existing (use for voice card)
├── Sources/
│   ├── Info.plist                                  # Actual Info.plist (per project.yml)
│   └── PrivacyInfo.xcprivacy                      # NEW: Privacy manifest
backend/
├── src/
│   ├── voice/
│   │   ├── dto/
│   │   │   └── upload-voice.input.ts              # Add appVersion field
│   │   └── voice.service.ts                       # Update uploadVoice to accept appVersion
│   └── privacy/
│       ├── privacy.controller.ts                  # NEW: Serve /privacy route
│       └── privacy-policy.html                    # NEW: Static HTML policy
└── prisma/
    └── schema.prisma                               # Add consentAppVersion to VoiceProfile
```

### Pattern 1: Voice Consent Gate (Full-Screen Modal)

**What:** Present undismissible full-screen consent modal before file picker, requiring explicit Accept/Decline action.

**When to use:** Before ANY voice upload (per-upload consent model), to comply with GDPR "explicit consent" requirement for biometric data processing.

**Example:**

```swift
// VoiceUploadReducer.swift
@Reducer
public struct VoiceUploadReducer {
    @ObservableState
    public struct State: Equatable {
        public var showConsentModal: Bool = false  // NEW
        public var consentGiven: Bool = false       // NEW
        public var showFilePicker: Bool = false
        // ... existing fields
    }

    public enum Action: Equatable {
        case uploadVoiceTapped                      // NEW: Entry point
        case consentAccepted                        // NEW
        case consentDeclined                        // NEW
        case selectFile                             // Existing (now gated)
        // ... existing actions
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .uploadVoiceTapped:
                state.showConsentModal = true       // Show consent first
                return .none

            case .consentAccepted:
                state.showConsentModal = false
                state.consentGiven = true
                state.showFilePicker = true         // Now show file picker
                return .none

            case .consentDeclined:
                state.showConsentModal = false      // Just dismiss, no punitive message
                return .none

            // ... rest of reducer
            }
        }
    }
}

// VoiceConsentView.swift (NEW)
public struct VoiceConsentView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    public var body: some View {
        VStack(spacing: KindredSpacing.xl) {
            // Icon
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.kindredAccent)

            // Title
            Text(String(localized: "voice.consent.title", bundle: .main))
                .font(.kindredHeading1Scaled(size: 34))
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)

            // ElevenLabs disclosure
            Text(String(localized: "voice.consent.elevenlabs_disclosure", bundle: .main))
                .font(.kindredBodyScaled(size: 18))
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)

            // Bullet points
            VStack(alignment: .leading, spacing: KindredSpacing.md) {
                ConsentBullet(text: String(localized: "voice.consent.bullet_sent_to_elevenlabs", bundle: .main))
                ConsentBullet(text: String(localized: "voice.consent.bullet_recipe_narration_only", bundle: .main))
                ConsentBullet(text: String(localized: "voice.consent.bullet_deletable_anytime", bundle: .main))
                ConsentBullet(text: String(localized: "voice.consent.bullet_never_shared", bundle: .main))
            }
            .padding(.horizontal, KindredSpacing.lg)

            Spacer()

            // Buttons
            VStack(spacing: KindredSpacing.md) {
                KindredButton(String(localized: "voice.consent.accept_button", bundle: .main), style: .primary) {
                    onAccept()
                }

                KindredButton(String(localized: "voice.consent.decline_button", bundle: .main), style: .secondary) {
                    onDecline()
                }
            }
            .padding(.horizontal, KindredSpacing.lg)
        }
        .padding(KindredSpacing.xl)
        .background(Color.kindredBackground)
        .interactiveDismissDisabled()  // CRITICAL: Prevent swipe-to-dismiss
    }
}

// Usage in VoiceUploadView
.fullScreenCover(isPresented: $store.showConsentModal) {
    VoiceConsentView(
        onAccept: { store.send(.consentAccepted) },
        onDecline: { store.send(.consentDeclined) }
    )
}
```

**Source:** [Mastering SwiftUI: Sheet & FullScreenCover](https://medium.com/@viralswift/mastering-swiftui-sheet-fullscreencover-presenting-modal-views-813a99b05903), [Apple HIG: Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)

### Pattern 2: Voice Profile Deletion (Destructive Confirmation Dialog)

**What:** Display voice profile card in Settings with Delete button → show iOS native destructive confirmation dialog → perform deletion with loading state → show success toast.

**When to use:** When user wants to delete their voice profile, to comply with GDPR "right to erasure" requirement.

**Example:**

```swift
// ProfileReducer.swift
@Reducer
public struct ProfileReducer {
    @ObservableState
    public struct State: Equatable {
        public var voiceProfile: VoiceProfile? = nil        // NEW
        public var showDeleteConfirmation: Bool = false     // NEW
        public var isDeletingVoice: Bool = false            // NEW
        public var showSuccessToast: Bool = false           // NEW
        // ... existing fields
    }

    public enum Action {
        case loadVoiceProfile                               // NEW
        case voiceProfileLoaded(VoiceProfile?)              // NEW
        case deleteVoiceTapped                              // NEW
        case confirmDeleteVoice                             // NEW
        case cancelDeleteVoice                              // NEW
        case voiceDeleted                                   // NEW
        case voiceDeletionFailed(String)                    // NEW
        // ... existing actions
    }

    @Dependency(\.voiceClient) var voiceClient              // NEW dependency

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadVoiceProfile:
                return .run { send in
                    let profile = try await voiceClient.getVoiceProfile()
                    await send(.voiceProfileLoaded(profile))
                }

            case let .voiceProfileLoaded(profile):
                state.voiceProfile = profile
                return .none

            case .deleteVoiceTapped:
                state.showDeleteConfirmation = true
                return .none

            case .confirmDeleteVoice:
                guard let profileId = state.voiceProfile?.id else { return .none }
                state.showDeleteConfirmation = false
                state.isDeletingVoice = true

                return .run { send in
                    try await voiceClient.deleteVoiceProfile(profileId)
                    await send(.voiceDeleted)
                } catch: { error, send in
                    await send(.voiceDeletionFailed(error.localizedDescription))
                }

            case .voiceDeleted:
                state.isDeletingVoice = false
                state.voiceProfile = nil
                state.showSuccessToast = true
                return .none

            // ... rest of reducer
            }
        }
    }
}

// PrivacyDataSection.swift (NEW)
struct PrivacyDataSection: View {
    let voiceProfile: VoiceProfile?
    let isDeleting: Bool
    let onDelete: () -> Void
    let onPrivacyPolicyTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.lg) {
            Text(String(localized: "profile.privacy_data.title", bundle: .main))
                .font(.kindredHeading2Scaled(size: 22))
                .foregroundColor(.kindredTextPrimary)

            // Voice profile card (if exists)
            if let profile = voiceProfile {
                VoiceProfileCard(profile: profile, isDeleting: isDeleting, onDelete: onDelete)
            }

            // Privacy Policy link
            Button {
                onPrivacyPolicyTapped()
            } label: {
                HStack {
                    Text(String(localized: "profile.privacy_data.privacy_policy", bundle: .main))
                        .font(.kindredBodyScaled(size: 18))
                        .foregroundColor(.kindredTextPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.kindredAccent)
                }
                .padding(KindredSpacing.md)
                .background(Color.kindredSurface)
                .cornerRadius(12)
            }
        }
    }
}

// VoiceProfileCard.swift (NEW)
struct VoiceProfileCard: View {
    let profile: VoiceProfile
    let isDeleting: Bool
    let onDelete: () -> Void

    var body: some View {
        CardSurface {
            HStack(alignment: .top, spacing: KindredSpacing.md) {
                // Avatar or icon
                Circle()
                    .fill(Color.kindredAccent.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "waveform")
                            .foregroundColor(.kindredAccent)
                    )

                // Info
                VStack(alignment: .leading, spacing: KindredSpacing.xs) {
                    Text(profile.name)
                        .font(.kindredBodyBoldScaled(size: 18))
                        .foregroundColor(.kindredTextPrimary)

                    Text(profile.relationship)
                        .font(.kindredCaptionScaled(size: 14))
                        .foregroundColor(.kindredTextSecondary)

                    Text("Created \(profile.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.kindredCaptionScaled(size: 14))
                        .foregroundColor(.kindredTextSecondary)

                    // Status badge
                    HStack(spacing: KindredSpacing.xs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.kindredCaptionScaled(size: 12))
                            .foregroundColor(.kindredTextSecondary)
                    }
                }

                Spacer()

                // Delete button
                if isDeleting {
                    ProgressView()
                } else {
                    Button {
                        onDelete()
                    } label: {
                        Text(String(localized: "profile.privacy_data.delete_voice", bundle: .main))
                            .font(.kindredCaptionBoldScaled(size: 14))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(KindredSpacing.md)
        }
    }

    private var statusText: String {
        switch profile.status {
        case .ready: return String(localized: "voice.status.ready", bundle: .main)
        case .processing: return String(localized: "voice.status.processing", bundle: .main)
        case .failed: return String(localized: "voice.status.failed", bundle: .main)
        default: return ""
        }
    }

    private var statusColor: Color {
        switch profile.status {
        case .ready: return .green
        case .processing: return .orange
        case .failed: return .red
        default: return .gray
        }
    }
}

// ProfileView.swift - Add confirmation dialog
.confirmationDialog(
    String(localized: "profile.privacy_data.delete_confirmation_title", bundle: .main),
    isPresented: $store.showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button(String(localized: "profile.privacy_data.delete_confirmation_action", bundle: .main), role: .destructive) {
        store.send(.confirmDeleteVoice)
    }
    Button(String(localized: "profile.privacy_data.delete_confirmation_cancel", bundle: .main), role: .cancel) {
        store.send(.cancelDeleteVoice)
    }
} message: {
    Text(String(localized: "profile.privacy_data.delete_confirmation_message", bundle: .main))
}
```

**Source:** [SwiftUI Confirmation Dialogs](https://useyourloaf.com/blog/swiftui-confirmation-dialogs/), [Apple HIG: Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts)

### Pattern 3: PrivacyInfo.xcprivacy Structure (Required Reason APIs)

**What:** Property list declaring all Required Reason API usage with approved reason codes.

**When to use:** Required for App Store submission starting February 2025 if app uses UserDefaults, file timestamps, system boot time, or disk space APIs.

**Example:**

```xml
<!-- Kindred/Sources/PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Privacy Tracking Domains (none for this app) -->
    <key>NSPrivacyTracking</key>
    <false/>

    <key>NSPrivacyTrackingDomains</key>
    <array/>

    <!-- Data Collection (matches App Store Connect Nutrition Labels) -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeAudioData</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeLocation</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>

    <!-- Required Reason APIs -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- UserDefaults: App-specific configuration -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>  <!-- Read/write app-specific config -->
            </array>
        </dict>

        <!-- File Timestamps: Check cache freshness -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>  <!-- Display file modification dates to user -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Reason Code Reference:**

- `CA92.1` (UserDefaults): "Accessing user defaults to read and write information that is only accessible to the app itself."
- `C617.1` (File Timestamps): "Displaying file timestamps to the user in the app's UI." (Used for pantry item creation dates)
- **Do NOT include** disk space or system boot time APIs unless actually used (avoid unnecessary declarations)

**Source:** [Privacy manifest files - Apple Developer](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files), [TN3183: Adding required reason API entries](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)

### Pattern 4: Privacy Policy Hosting (NestJS Static Route)

**What:** Serve privacy policy as static HTML from backend at `/privacy`, opened in-app via `SFSafariViewController`.

**When to use:** App Store requires public URL for privacy policy, NestJS backend already exists for hosting.

**Example:**

```typescript
// backend/src/privacy/privacy.controller.ts (NEW)
import { Controller, Get, Res } from '@nestjs/common';
import { Response } from 'express';
import { readFileSync } from 'fs';
import { join } from 'path';

@Controller('privacy')
export class PrivacyController {
  /**
   * Serve privacy policy as static HTML
   * Public route (no auth required)
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

// backend/src/privacy/privacy-policy.html (NEW)
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kindred Privacy Policy</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1 { font-size: 28px; margin-bottom: 10px; }
        h2 { font-size: 22px; margin-top: 30px; }
        h3 { font-size: 18px; margin-top: 20px; }
        p { margin-bottom: 15px; }
        ul { margin-left: 20px; }
        .contact { background: #f5f5f5; padding: 15px; border-radius: 8px; margin-top: 30px; }
    </style>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p><strong>Effective Date:</strong> March 30, 2026</p>
    <p><strong>Data Controller:</strong> Ersin Kirteke</p>
    <p><strong>Contact:</strong> privacy@kindred.app</p>

    <h2>1. Introduction</h2>
    <p>Kindred ("we", "our", or "us") is a cooking app that helps you discover recipes with AI-narrated voice playback. This Privacy Policy explains how we collect, use, and protect your personal information.</p>

    <h2>2. Data We Collect</h2>

    <h3>2.1 Voice Data (Biometric)</h3>
    <p>When you upload a voice sample:</p>
    <ul>
        <li><strong>What:</strong> Audio recording (30-60 seconds)</li>
        <li><strong>Purpose:</strong> Voice cloning for AI recipe narration</li>
        <li><strong>Third-Party Processor:</strong> ElevenLabs (AI voice provider)</li>
        <li><strong>Legal Basis (GDPR):</strong> Explicit consent (Art. 9(2)(a))</li>
        <li><strong>Storage:</strong> Cloudflare R2 (backup), ElevenLabs servers (cloned voice model)</li>
        <li><strong>Retention:</strong> Until you delete your voice profile from Settings</li>
    </ul>

    <h3>2.2 Location Data</h3>
    <p>During onboarding, we detect your city to show locally trending recipes:</p>
    <ul>
        <li><strong>What:</strong> City-level location (via Mapbox geocoding)</li>
        <li><strong>Purpose:</strong> Personalized recipe discovery</li>
        <li><strong>Storage:</strong> Device-only (not sent to servers after onboarding)</li>
        <li><strong>Legal Basis (GDPR):</strong> Consent (Art. 6(1)(a))</li>
    </ul>

    <h3>2.3 Account Data</h3>
    <p>Managed by Clerk (authentication provider):</p>
    <ul>
        <li><strong>What:</strong> Email, Apple ID (if Sign in with Apple), authentication tokens</li>
        <li><strong>Purpose:</strong> Account creation and login</li>
        <li><strong>Storage:</strong> Clerk servers (USA), encrypted</li>
        <li><strong>Legal Basis (GDPR):</strong> Contract performance (Art. 6(1)(b))</li>
    </ul>

    <h3>2.4 Analytics & Diagnostics</h3>
    <p>We use Firebase Analytics and Crashlytics:</p>
    <ul>
        <li><strong>What:</strong> App usage patterns, crash logs, device model, OS version</li>
        <li><strong>Purpose:</strong> Improve app stability and user experience</li>
        <li><strong>Data Linkage:</strong> Not linked to your identity (anonymous)</li>
        <li><strong>Legal Basis (GDPR):</strong> Legitimate interest (Art. 6(1)(f))</li>
    </ul>

    <h3>2.5 Advertising (Free Tier Only)</h3>
    <p>We use Google AdMob for ads:</p>
    <ul>
        <li><strong>What:</strong> Ad interaction data (impressions, clicks)</li>
        <li><strong>Purpose:</strong> Show relevant ads</li>
        <li><strong>Tracking:</strong> Currently NO personalized ads (no IDFA usage)</li>
        <li><strong>Legal Basis (GDPR):</strong> Consent (required before personalized ads)</li>
    </ul>

    <h2>3. Your Rights (GDPR)</h2>

    <h3>3.1 Access & Portability</h3>
    <p>You can request a copy of your data by emailing privacy@kindred.app.</p>

    <h3>3.2 Deletion (Right to Erasure)</h3>
    <ul>
        <li><strong>Voice Data:</strong> Delete your voice profile from Settings → Privacy & Data → Delete Voice Profile.</li>
        <li><strong>Account Data:</strong> Account deletion available in a future update (currently contact privacy@kindred.app).</li>
    </ul>

    <h3>3.3 Withdraw Consent</h3>
    <p>You can withdraw voice consent by deleting your voice profile. For advertising consent, disable personalized ads in iOS Settings → Privacy.</p>

    <h2>4. Third-Party Services</h2>
    <ul>
        <li><strong>ElevenLabs:</strong> Voice cloning (see <a href="https://elevenlabs.io/privacy">ElevenLabs Privacy Policy</a>)</li>
        <li><strong>Clerk:</strong> Authentication (see <a href="https://clerk.com/legal/privacy">Clerk Privacy Policy</a>)</li>
        <li><strong>Google Firebase:</strong> Analytics & Crashlytics (see <a href="https://firebase.google.com/support/privacy">Firebase Privacy</a>)</li>
        <li><strong>Google AdMob:</strong> Advertising (see <a href="https://policies.google.com/privacy">Google Privacy Policy</a>)</li>
        <li><strong>Mapbox:</strong> Geocoding (see <a href="https://www.mapbox.com/legal/privacy">Mapbox Privacy Policy</a>)</li>
    </ul>

    <h2>5. Data Security</h2>
    <p>We use industry-standard encryption for data in transit (TLS 1.3) and at rest (AES-256). Voice samples are stored on Cloudflare R2 with restricted access.</p>

    <h2>6. Children's Privacy</h2>
    <p>Kindred is not intended for users under 13 (USA) or 16 (EU). We do not knowingly collect data from children.</p>

    <h2>7. Changes to This Policy</h2>
    <p>We may update this policy. Changes are effective upon posting. Last updated: March 30, 2026.</p>

    <div class="contact">
        <h2>8. Contact Us</h2>
        <p><strong>Data Controller:</strong> Ersin Kirteke</p>
        <p><strong>Email:</strong> privacy@kindred.app</p>
        <p><strong>Location:</strong> Lithuania (EU)</p>
    </div>
</body>
</html>
```

```swift
// ProfileView.swift - Add privacy policy button
Button {
    store.send(.privacyPolicyTapped)
} label: {
    Text(String(localized: "profile.privacy_data.privacy_policy", bundle: .main))
}
.sheet(isPresented: $store.showPrivacyPolicy) {
    SafariView(url: URL(string: "https://api.kindred.app/privacy")!)
}

// SafariView.swift (NEW wrapper for SFSafariViewController)
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
```

**Source:** [SFSafariViewController - Apple Developer](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller), [Privacy Policy for iOS Apps - TermsFeed](https://www.termsfeed.com/blog/ios-apps-privacy-policy/)

### Anti-Patterns to Avoid

**1. Weak Consent UI:**
- Don't use dismissible sheet (`.sheet`) for consent — violates "explicit consent" under GDPR. Use `.fullScreenCover` with `.interactiveDismissDisabled()`.
- Don't pre-check consent checkbox — affirmative action required. Use explicit Accept button tap.
- Don't hide ElevenLabs disclosure in fine print — must be prominent per transparency principle.

**2. Missing Audit Trail:**
- Don't skip storing consent timestamp, IP, and **app version** — audit trail required for legal defense (GDPR Art. 7(1): "controller shall be able to demonstrate that the data subject has consented").
- App version is critical for proving which consent language the user saw at time of consent.

**3. Privacy Policy Gaps:**
- Don't omit third-party processors (ElevenLabs, AdMob, Firebase, Mapbox, Clerk) — GDPR Art. 13(1)(e) requires disclosure.
- Don't skip contact email — GDPR Art. 13(1)(a) requires data controller contact information.
- Don't use vague language ("we may share data") — must be specific about what data goes where.

**4. PrivacyInfo.xcprivacy Errors:**
- Don't declare tracking (`NSPrivacyTracking: true`) unless actually using IDFA for cross-app tracking — triggers ATT requirement.
- Don't omit Required Reason APIs (UserDefaults, file timestamps) — App Store will reject submissions starting February 2025.
- Don't use wrong reason code (e.g., `1C8F.1` for app groups when using `CA92.1` for app-only storage) — Apple will reject.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Consent UI patterns | Custom modal with custom dismiss handling | SwiftUI `.fullScreenCover` + `.interactiveDismissDisabled()` | iOS native pattern ensures accessibility (VoiceOver, Dynamic Type), prevents swipe-to-dismiss, familiar to users |
| Destructive confirmations | Custom alert view with red text | SwiftUI `.confirmationDialog` with `.destructive` role | iOS native styling (red button), automatic cancel button, haptic feedback, VoiceOver support |
| Privacy manifest format | Manual XML editing | Xcode 15+ Property List editor | Dropdown menus with valid reason codes, prevents typos, validates structure |
| Privacy policy generator | Third-party generator service | Static HTML hosted on backend | Full control over content, no external dependencies, easy updates, free |

**Key insight:** Apple provides native patterns for consent UI, destructive actions, and privacy manifests. Custom solutions risk accessibility failures, App Store rejection (invalid reason codes), and legal non-compliance (weak consent UX).

## Common Pitfalls

### Pitfall 1: Sheet-Based Consent (GDPR Violation)

**What goes wrong:** Using `.sheet` instead of `.fullScreenCover` allows user to dismiss consent by dragging downward, which is NOT "explicit consent" under GDPR — consent must be "unambiguous indication of the data subject's wishes by a clear affirmative action" (GDPR Art. 4(11)).

**Why it happens:** `.sheet` is SwiftUI's default modal, developers don't realize it can be dismissed without button tap.

**How to avoid:**
```swift
// BAD: Dismissible sheet
.sheet(isPresented: $store.showConsentModal) {
    VoiceConsentView(...)
}

// GOOD: Full-screen, undismissible modal
.fullScreenCover(isPresented: $store.showConsentModal) {
    VoiceConsentView(...)
        .interactiveDismissDisabled()  // CRITICAL: Blocks swipe-to-dismiss
}
```

**Warning signs:** User can swipe down to dismiss, consent not recorded in audit trail, regulatory audit reveals weak consent flow.

**Source:** [Biometric Data GDPR Compliance](https://gdprlocal.com/biometric-data-gdpr-compliance-made-simple/), [Voice Cloning Consent Laws](https://www.soundverse.ai/blog/article/voice-cloning-consent-laws-by-country-1049)

### Pitfall 2: Missing App Version in Consent Audit Trail

**What goes wrong:** Backend stores `consentedAt` timestamp and IP address, but NOT the app version. If consent language changes in a future update, no way to prove which version of consent language user saw. Legal defense requires showing exact consent text presented.

**Why it happens:** Developers focus on timestamp/IP per legal advice, miss that consent language evolves over app versions.

**How to avoid:**
```typescript
// backend/prisma/schema.prisma - Add consentAppVersion field
model VoiceProfile {
  id                 String      @id @default(cuid())
  // ... existing fields
  consentedAt        DateTime?
  consentIpAddress   String?
  consentAppVersion  String?     // NEW: Store app version at consent time
}

// backend/src/voice/dto/upload-voice.input.ts - Accept appVersion
@InputType()
export class UploadVoiceInput {
  @Field()
  appVersion: string;  // NEW: Pass from iOS via Bundle.main.infoDictionary!["CFBundleShortVersionString"]

  @Field()
  consentGiven: boolean;

  // ... existing fields
}

// iOS - Pass app version when uploading
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
// Include in GraphQL mutation variables
```

**Warning signs:** Regulatory audit asks "what consent language did user see?", you can only answer "sometime between March 2026 and August 2026 based on timestamp", not specific version.

**Source:** [GDPR Article 7(1): Conditions for consent](https://gdpr-info.eu/art-7-gdpr/), industry best practice from voice AI legal advisories (2026)

### Pitfall 3: AdMob/Firebase Privacy Manifest Confusion

**What goes wrong:** Developer assumes GoogleMobileAds SDK includes its own PrivacyInfo.xcprivacy (which it does), but misses that **app-level manifest is still required** to declare YOUR usage of Required Reason APIs (UserDefaults, file timestamps). App Store rejects submission with ITMS-91053 error: "Missing API declaration".

**Why it happens:** Google's SDKs include their own manifests (correct), but app must declare its OWN API usage separately.

**How to avoid:**
1. Check if SDK includes manifest: `Kindred/.build/artifacts/swift-package-manager-google-mobile-ads/GoogleMobileAds/GoogleMobileAds.xcframework/ios-arm64/GoogleMobileAds.framework/PrivacyInfo.xcprivacy` (exists ✅)
2. Create app-level manifest at `Kindred/Sources/PrivacyInfo.xcprivacy` declaring YOUR API usage (UserDefaults for preferences, file timestamps for pantry dates)
3. Do NOT duplicate SDK declarations — only declare APIs your app code calls

**Warning signs:** App Store Connect email: "ITMS-91053: Missing API declaration — your app uses NSUserDefaults but doesn't declare it in PrivacyInfo.xcprivacy".

**Source:** [Firebase and GoogleAdsMobile Migration To SPM for Privacy Manifest](https://github.com/firebase/firebase-ios-sdk/issues/12493), [App Store warning for Privacy Manifest](https://groups.google.com/g/google-admob-ads-sdk/c/X-jq7_i-Hvc)

### Pitfall 4: Privacy Policy Not Publicly Accessible

**What goes wrong:** Privacy policy hosted at `/privacy` route requires authentication (Clerk JWT check), or backend not deployed to production URL yet. App Store Connect rejects submission: "Privacy Policy URL not accessible".

**Why it happens:** Backend routes default to requiring auth, developer forgets to make `/privacy` public.

**How to avoid:**
```typescript
// backend/src/privacy/privacy.controller.ts - Make route PUBLIC
import { Controller, Get, Res } from '@nestjs/common';
// NO @UseGuards(JwtAuthGuard) decorator — public route

@Controller('privacy')
export class PrivacyController {
  @Get()
  getPrivacyPolicy(@Res() res: Response) {
    // ... serve HTML
  }
}

// Test accessibility BEFORE App Store submission
curl https://api.kindred.app/privacy  # Should return HTML, not 401 Unauthorized
```

**Warning signs:** App Store Connect shows "Unable to verify privacy policy URL", curl returns 401/403, SFSafariViewController shows authentication prompt instead of policy.

**Source:** [App Privacy Details - App Store](https://developer.apple.com/app-store/app-privacy-details/), [Privacy Policy for iOS Apps - TermsFeed](https://www.termsfeed.com/blog/ios-apps-privacy-policy/)

## Code Examples

Verified patterns from official sources.

### Voice Consent Localization Strings

```json
// Kindred/Sources/Resources/Localizable.xcstrings - Add new strings
{
  "sourceLanguage": "en",
  "strings": {
    "voice.consent.title": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Voice Cloning Consent"
          }
        }
      }
    },
    "voice.consent.elevenlabs_disclosure": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Your voice will be processed by ElevenLabs, an AI voice provider, to create a cloned voice for recipe narration."
          }
        }
      }
    },
    "voice.consent.bullet_sent_to_elevenlabs": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Voice is sent to ElevenLabs for AI cloning"
          }
        }
      }
    },
    "voice.consent.bullet_recipe_narration_only": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Used only for recipe narration in Kindred"
          }
        }
      }
    },
    "voice.consent.bullet_deletable_anytime": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "You can delete your voice anytime from Settings"
          }
        }
      }
    },
    "voice.consent.bullet_never_shared": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Voice is never shared with other users"
          }
        }
      }
    },
    "voice.consent.accept_button": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Accept & Continue"
          }
        }
      }
    },
    "voice.consent.decline_button": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Decline"
          }
        }
      }
    },
    "profile.privacy_data.title": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Privacy & Data"
          }
        }
      }
    },
    "profile.privacy_data.delete_voice": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Delete"
          }
        }
      }
    },
    "profile.privacy_data.delete_confirmation_title": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Delete Voice Profile?"
          }
        }
      }
    },
    "profile.privacy_data.delete_confirmation_message": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "This will permanently remove your cloned voice from ElevenLabs. Existing narrations will fall back to the default AI voice."
          }
        }
      }
    },
    "profile.privacy_data.delete_confirmation_action": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Delete Voice Profile"
          }
        }
      }
    },
    "profile.privacy_data.delete_confirmation_cancel": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Cancel"
          }
        }
      }
    },
    "profile.privacy_data.voice_deleted_success": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Voice profile deleted"
          }
        }
      }
    },
    "profile.privacy_data.privacy_policy": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Privacy Policy"
          }
        }
      }
    },
    "voice.status.ready": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Ready"
          }
        }
      }
    },
    "voice.status.processing": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Processing"
          }
        }
      }
    },
    "voice.status.failed": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Failed"
          }
        }
      }
    }
  }
}
```

**Source:** Existing Localizable.xcstrings pattern in project

### App Store Connect Privacy Nutrition Labels Checklist

Create markdown checklist for copy-paste into App Store Connect questionnaire:

```markdown
# App Store Connect Privacy Nutrition Labels - Kindred v4.0

**Last Updated:** March 30, 2026
**App Version:** 4.0
**Instructions:** Use this checklist when filling out "App Privacy" section in App Store Connect.

## Data Types Collected

### 1. Contact Info
- [ ] **Email Address**
  - Linked to user: YES
  - Used for tracking: NO
  - Purposes: App Functionality (account creation)
  - Third party: Clerk (authentication)

### 2. Audio Data
- [ ] **Audio Data** (Voice recordings)
  - Linked to user: YES
  - Used for tracking: NO
  - Purposes: App Functionality (voice cloning for narration)
  - Third party: ElevenLabs (voice cloning AI)

### 3. User Content
- [ ] **Other User Content** (Recipe bookmarks, pantry items)
  - Linked to user: YES
  - Used for tracking: NO
  - Purposes: App Functionality (save recipes, track pantry)
  - Third party: None (stored on Kindred backend)

### 4. Identifiers
- [ ] **User ID**
  - Linked to user: YES
  - Used for tracking: NO
  - Purposes: App Functionality (account management)
  - Third party: Clerk (authentication)

### 5. Usage Data
- [ ] **Product Interaction** (App usage, button taps, feature usage)
  - Linked to user: NO (anonymous)
  - Used for tracking: NO
  - Purposes: Analytics (improve app, understand feature usage)
  - Third party: Firebase Analytics

### 6. Diagnostics
- [ ] **Crash Data**
  - Linked to user: NO (anonymous)
  - Used for tracking: NO
  - Purposes: App Functionality (fix bugs, improve stability)
  - Third party: Firebase Crashlytics

### 7. Location
- [ ] **Coarse Location** (City-level)
  - Linked to user: NO (device-only, not sent to servers after onboarding)
  - Used for tracking: NO
  - Purposes: App Functionality (show locally trending recipes)
  - Third party: Mapbox (geocoding)

### 8. Financial Info
- [ ] **Purchase History**
  - Linked to user: YES
  - Used for tracking: NO
  - Purposes: App Functionality (subscription management)
  - Third party: Apple (StoreKit)

## Data NOT Collected

Mark **NO** for these categories:
- Health & Fitness
- Contacts
- Browsing History
- Search History
- Sensitive Info
- Purchases (outside subscription)
- Physical Address
- Phone Number
- Name
- Photos or Videos
- Other Data Types

## Tracking Status

- [ ] **Does your app or third-party partners collect data from this app to track users?**
  - Answer: **NO** (no IDFA usage, no personalized ads in v4.0)
  - Note: If AdMob personalized ads enabled in future (Phase 20), change to YES and add ATT prompt

## Privacy Policy URL

- Production: `https://api.kindred.app/privacy`
- Staging: `https://staging-api.kindred.app/privacy`

**Verify URL is publicly accessible before submission!**

---

**Notes:**
- This checklist reflects v4.0 state (no ATT, no personalized ads)
- Update if AdMob switches to personalized ads (Phase 20) — requires ATT prompt and tracking disclosure
- Review checklist before EVERY major version update
```

**Source:** [App Privacy Details - App Store](https://developer.apple.com/app-store/app-privacy-details/), [Submitting App Privacy Details - Singular](https://support.singular.net/hc/en-us/articles/360053160271-Submitting-App-Privacy-Details-Nutrition-Labels-to-the-App-Store)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic "I agree to Terms" checkbox | Explicit consent with clear disclosure naming third-party processors | GDPR 2018, CCPA 2020, AI-specific laws 2025-2026 | Voice data classified as biometric data (GDPR special category), requires explicit consent with affirmative action |
| Optional privacy manifest | Mandatory PrivacyInfo.xcprivacy with Required Reason APIs | Apple requirement Feb 2025 | Apps without manifests rejected from App Store |
| Privacy policy on separate website | Privacy policy URL required in App Store Connect | Apple policy 2020 | Must be publicly accessible and linked in-app |
| Manual privacy audit | Automated scanning for tracking domains and Required Reason APIs | Apple App Store Connect 2024+ | Upload triggers validation, warns about missing declarations |
| Pre-checked consent boxes | Clear affirmative action required (button tap, not checkbox) | GDPR 2018, enforced 2025+ | Pre-checked boxes considered invalid consent |

**Deprecated/outdated:**

- **Privacy Policy generators without GDPR compliance:** Old generators (pre-2018) don't cover biometric data consent. Use custom policy or modern generator (2025+).
- **Simple "I agree" checkboxes:** Not compliant with GDPR/CCPA. Must be explicit button tap with clear explanation of data use.
- **Privacy policy in app resources (not public URL):** Apple now requires publicly accessible URL, not just in-app PDF or text file.
- **AdMob without privacy manifest:** Google AdMob SDK versions < 11.2.0 lack privacy manifests. Update to 11.2.0+ (included in project).

## Open Questions

1. **Legal Counsel Review Timeline**
   - What we know: Voice cloning consent language must comply with Tennessee ELVIS Act, California AB 1836, Federal AI Voice Act (pending), GDPR biometric consent requirements
   - What's unclear: Budget ($20-50K) and timeline (2-4 weeks) are estimates — actual cost/timeline depends on legal firm chosen
   - Recommendation: Initiate legal counsel search in parallel with technical work. Technical implementation (this phase) can proceed with placeholder consent language, final language updated after legal review before App Store submission.

2. **ElevenLabs Data Residency**
   - What we know: ElevenLabs processes voice data, but data residency (USA vs EU servers) not confirmed
   - What's unclear: GDPR requires disclosure if data transferred outside EU (user is in Lithuania). Privacy policy currently states "ElevenLabs servers" without specifying location.
   - Recommendation: Contact ElevenLabs support to confirm data residency. If USA-based, add Standard Contractual Clauses (SCC) disclosure to privacy policy.

3. **Firebase Analytics Data Retention**
   - What we know: Firebase Analytics collects usage data anonymously
   - What's unclear: Default retention period (14 months? configurable?)
   - Recommendation: Check Firebase console settings, document retention period in privacy policy. Configure to minimum necessary (90 days for crash logs, 6 months for analytics).

## Sources

### Primary (HIGH confidence)

- [Privacy manifest files - Apple Developer](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) - Official PrivacyInfo.xcprivacy format and Required Reason API reference
- [TN3183: Adding required reason API entries to your privacy manifest - Apple Developer](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest) - Official reason code documentation (CA92.1, C617.1, etc.)
- [App Privacy Details - App Store - Apple Developer](https://developer.apple.com/app-store/app-privacy-details/) - Official Privacy Nutrition Labels requirements and 14 categories
- [Sheets - Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sheets) - Official guidance on fullScreenCover vs sheet
- [Alerts - Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/alerts) - Official guidance on confirmationDialog and destructive actions
- [SFSafariViewController - Apple Developer](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller) - Official API documentation for in-app web content

### Secondary (MEDIUM confidence)

- [Biometric Data GDPR Compliance Made Simple - GDPR Local](https://gdprlocal.com/biometric-data-gdpr-compliance-made-simple/) (2025) - Voice as biometric data, explicit consent requirements
- [Voice Cloning Consent Laws by Country - Soundverse AI](https://www.soundverse.ai/blog/article/voice-cloning-consent-laws-by-country-1049) (2026) - Multi-state voice cloning legal landscape (Tennessee ELVIS Act, California AB 1836, Federal AI Voice Act)
- [Is Voice Cloning Legal in 2025? - DupDub](https://www.dupdub.com/blog/is-voice-cloning-legal) (2025) - Documented permission requirement, explicit consent standards
- [SwiftUI Confirmation Dialogs - Use Your Loaf](https://useyourloaf.com/blog/swiftui-confirmation-dialogs/) (2024) - Practical guide to confirmationDialog with destructive role
- [Mastering SwiftUI: Sheet & FullScreenCover - ViralSwift on Medium](https://medium.com/@viralswift/mastering-swiftui-sheet-fullscreencover-presenting-modal-views-813a99b05903) (2024) - Best practices for modal presentation, interactiveDismissDisabled usage
- [Firebase Analytics AdMob privacy manifest required reason API - Firebase GitHub Issues](https://github.com/firebase/firebase-ios-sdk/issues/11490) (2024-2025) - Firebase 10.22+ includes privacy manifests, developer still responsible for app-level declarations
- [App Store data disclosure - Google for Developers](https://developers.google.com/admob/ios/privacy/data-disclosure) (2024) - AdMob privacy manifest requirements, nutrition label guidance

### Tertiary (LOW confidence)

- [Privacy Policy for iOS Apps - TermsFeed](https://www.termsfeed.com/blog/ios-apps-privacy-policy/) - General iOS privacy policy guidance, not voice-specific
- [ITMS-91053: Missing API declaration - MszPro](https://mszpro.com/itms-91053-missing-api-declaration-for-accessing-userdefaults-timestamps-other-apis) - Community troubleshooting for privacy manifest errors

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All components are iOS native or already in project (SwiftUI, NestJS)
- Architecture: HIGH - Patterns verified with Apple official docs (fullScreenCover, confirmationDialog, PrivacyInfo.xcprivacy structure)
- Pitfalls: HIGH - Based on official Apple documentation (privacy manifest requirements) and regulatory sources (GDPR biometric consent)
- Legal compliance: MEDIUM - Voice cloning consent laws are recent (2025-2026), legal counsel review recommended before submission

**Research date:** 2026-03-30
**Valid until:** May 2026 (30 days for stable domain) — Apple privacy requirements stable since Feb 2025 deadline, GDPR unchanged since 2018, voice cloning laws evolving but current sources reflect 2026 landscape
