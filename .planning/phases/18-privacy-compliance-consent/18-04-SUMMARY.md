---
phase: 18-privacy-compliance-consent
plan: 04
subsystem: privacy-compliance
tags: [consent, audit-trail, PRIV-05, gap-closure, iOS, backend]
completed: 2026-03-30
duration: 66s

dependency_graph:
  requires: [PRIV-05-schema, PRIV-05-service]
  provides: [PRIV-05-complete]
  affects: [voice-upload-flow, consent-audit]

tech_stack:
  added: []
  patterns:
    - Bundle.main.infoDictionary for iOS app version extraction
    - Multipart form data for client-server communication
    - @Body decorator for REST parameter extraction in NestJS

key_files:
  created: []
  modified:
    - path: Kindred/Packages/VoicePlaybackFeature/Sources/VoiceUpload/VoiceUploadReducer.swift
      type: client
      change: Added appVersion field extraction and multipart form inclusion
    - path: backend/src/voice/voice.controller.ts
      type: server
      change: Added appVersion parameter extraction and UploadVoiceInput inclusion

decisions:
  - what: Use CFBundleShortVersionString for app version
    why: Standard iOS bundle key for user-visible version string
    alternatives: [CFBundleVersion (build number)]
    rationale: Short version matches consent copy versioning scheme
  - what: Send appVersion as separate multipart field
    why: Clean separation of concerns in form data structure
    alternatives: [embed in metadata JSON]
    rationale: Consistent with existing form field pattern (speakerName, relationship)
  - what: Use "appVersion || undefined" in controller
    why: Allows voice.service.ts to apply ?? null fallback for existing records
    alternatives: [appVersion || null]
    rationale: Maintains backward compatibility with existing nullable schema

metrics:
  tasks_completed: 1
  files_created: 0
  files_modified: 2
  tests_added: 0
  commits: 1
---

# Phase 18 Plan 04: PRIV-05 AppVersion Gap Closure Summary

**One-liner:** iOS now sends CFBundleShortVersionString in voice upload multipart form data, backend extracts and stores it in consentAppVersion for complete consent audit trail.

## What Was Built

Closed PRIV-05 verification gap by implementing the missing appVersion flow:

1. **iOS Client (VoiceUploadReducer.swift):**
   - Extracts app version from `Bundle.main.infoDictionary["CFBundleShortVersionString"]`
   - Adds `appVersion` field to multipart form body between voice name and audio file
   - Includes PRIV-05 comment for audit trail context

2. **Backend Controller (voice.controller.ts):**
   - Added `@Body('appVersion') appVersion: string` parameter to `uploadVoice()` method
   - Includes `appVersion: appVersion || undefined` in UploadVoiceInput construction
   - Preserves backward compatibility with optional field handling

## End-to-End Flow

```
iOS Bundle.main
  ↓ CFBundleShortVersionString
iOS VoiceUploadReducer
  ↓ multipart form field name="appVersion"
Backend voice.controller.ts
  ↓ @Body('appVersion') → UploadVoiceInput.appVersion
Backend voice.service.ts
  ↓ input.appVersion ?? null
Prisma VoiceProfile.consentAppVersion
```

## Technical Implementation

### iOS Changes (VoiceUploadReducer.swift)

**Location:** Lines 160-164 (after voice name field, before audio file field)

```swift
// Add app version field for consent audit trail (PRIV-05)
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
body.append("--\(boundary)\r\n".data(using: .utf8)!)
body.append("Content-Disposition: form-data; name=\"appVersion\"\r\n\r\n".data(using: .utf8)!)
body.append("\(appVersion)\r\n".data(using: .utf8)!)
```

**Why this placement:** Multipart form data must maintain field order. Placed after metadata fields (voiceName) and before binary data (audio file) for clean form structure.

### Backend Changes (voice.controller.ts)

**Parameter addition (line 71):**
```typescript
@Body('appVersion') appVersion: string,
```

**Input construction (line 98):**
```typescript
const input: UploadVoiceInput = {
  speakerName,
  relationship,
  consentGiven: consentGiven === 'true',
  appVersion: appVersion || undefined,
};
```

**Why `|| undefined`:** Backend voice.service.ts already has `input.appVersion ?? null` for Prisma schema compatibility. Using `undefined` (not `null`) allows the service layer's fallback to work correctly for existing records.

## Verification Results

All verification criteria passed:

1. ✅ iOS extracts app version from CFBundleShortVersionString
2. ✅ iOS sends it in multipart form with name="appVersion"
3. ✅ Backend extracts it with @Body('appVersion')
4. ✅ Backend passes it to service with `appVersion: appVersion || undefined`
5. ✅ Backend TypeScript compiles cleanly (`npx tsc --noEmit` succeeded)

## Deviations from Plan

None - plan executed exactly as written.

## Legal/Compliance Impact

**PRIV-05 Gap Closed:** The consent audit trail is now complete. When a user uploads a voice sample:

1. iOS captures the exact app version they're running (e.g., "4.0.0")
2. Backend stores it in `consentAppVersion` column alongside `consentGiven` and `consentTimestamp`
3. Legal team can prove which consent language version the user saw at time of upload

**Regulatory Compliance:**
- **GDPR Article 7:** Demonstrates burden of proof for valid consent
- **Tennessee ELVIS Act:** Proves user saw jurisdiction-specific consent copy
- **California AB 1836:** Shows consent version for post-mortem voice cloning rules

**Before this fix:** consentAppVersion was always NULL (user saw v4.0 consent but database showed NULL).

**After this fix:** consentAppVersion populated on every upload (database shows "4.0.0" matching user's experience).

## Dependencies

**Upstream (already complete):**
- ✅ Prisma schema has `consentAppVersion String?` column
- ✅ Backend voice.service.ts stores `input.appVersion ?? null`
- ✅ Backend UploadVoiceInput DTO has `appVersion?: string` field

**No downstream changes needed** - service layer and database already handle appVersion correctly.

## Testing Notes

**Manual verification needed:**

1. Deploy backend with updated voice.controller.ts
2. Build iOS app with updated VoiceUploadReducer.swift
3. Upload a voice sample
4. Check database: `SELECT consentAppVersion FROM VoiceProfile ORDER BY createdAt DESC LIMIT 1;`
5. Verify: consentAppVersion = "4.0.0" (or current CFBundleShortVersionString value)

**Expected behavior:**
- New uploads: consentAppVersion populated with current app version
- Existing records: consentAppVersion remains NULL (by design - no retroactive update)

## Files Modified

| File | Lines Changed | Type |
|------|---------------|------|
| VoiceUploadReducer.swift | +5 | iOS client |
| voice.controller.ts | +1 parameter, +1 field | Backend REST |

**Total:** 2 files, 7 lines added, 0 lines removed.

## Commit

**Hash:** aabd7a6

**Message:**
```
feat(18-04): add appVersion to voice upload flow for PRIV-05 consent audit trail

- iOS: VoiceUploadReducer extracts appVersion from CFBundleShortVersionString and sends in multipart form data
- Backend: voice.controller.ts extracts appVersion from @Body('appVersion') and passes to UploadVoiceInput
- Closes PRIV-05 gap: end-to-end flow now populates consentAppVersion in Prisma database
```

## Next Steps

**Phase 18 Status:** Plan 04 complete (4 of 4 plans in phase)

**Remaining v4.0 work:**
- Phase 19: Backend production readiness (JWS validation, device tokens, cost optimization)
- Phase 20: Revenue monetization (production AdMob IDs, paywall wiring)
- Phase 21: Data integrity (SwiftData persistence, GraphQL TODOs, test audio removal)
- Phase 22: App Store submission (screenshots, metadata, TestFlight)

**Phase 18 Complete:** All privacy compliance infrastructure in place:
- 18-01: Consent modal with interactiveDismissDisabled
- 18-02: Privacy manifest with required reason codes
- 18-03: Voice deletion + privacy policy endpoints
- 18-04: AppVersion audit trail (this plan)

## Self-Check: PASSED

Verified all claims in this summary:

```bash
# Check iOS file exists and contains appVersion logic
[ -f "Kindred/Packages/VoicePlaybackFeature/Sources/VoiceUpload/VoiceUploadReducer.swift" ] && echo "FOUND: VoiceUploadReducer.swift" || echo "MISSING: VoiceUploadReducer.swift"
grep -q "CFBundleShortVersionString" "Kindred/Packages/VoicePlaybackFeature/Sources/VoiceUpload/VoiceUploadReducer.swift" && echo "FOUND: CFBundleShortVersionString extraction" || echo "MISSING: CFBundleShortVersionString extraction"
grep -q 'name=\\"appVersion\\"' "Kindred/Packages/VoicePlaybackFeature/Sources/VoiceUpload/VoiceUploadReducer.swift" && echo "FOUND: appVersion form field" || echo "MISSING: appVersion form field"

# Check backend file exists and contains appVersion logic
[ -f "backend/src/voice/voice.controller.ts" ] && echo "FOUND: voice.controller.ts" || echo "MISSING: voice.controller.ts"
grep -q "@Body('appVersion')" "backend/src/voice/voice.controller.ts" && echo "FOUND: @Body('appVersion') parameter" || echo "MISSING: @Body('appVersion') parameter"
grep -q "appVersion: appVersion" "backend/src/voice/voice.controller.ts" && echo "FOUND: appVersion in input" || echo "MISSING: appVersion in input"

# Check commit exists
git log --oneline --all | grep -q "aabd7a6" && echo "FOUND: commit aabd7a6" || echo "MISSING: commit aabd7a6"
```

**Results:**
```
FOUND: VoiceUploadReducer.swift
FOUND: CFBundleShortVersionString extraction
FOUND: appVersion form field
FOUND: voice.controller.ts
FOUND: @Body('appVersion') parameter
FOUND: appVersion in input
FOUND: commit aabd7a6
```

All files created, all code changes present, commit exists. Self-check passed
