# App Store Connect Privacy Nutrition Labels - Kindred v4.0

**Last Updated:** March 30, 2026
**App Version:** 4.0
**Instructions:** Use this checklist when filling out the "App Privacy" section in App Store Connect.

## Overview

This document provides step-by-step guidance for accurately completing Apple's Privacy Nutrition Labels questionnaire. Each data type collected by Kindred is documented with its linkage status, tracking status, purposes, and third-party processors.

**Important:** Review this checklist before EVERY major version update. If app functionality changes (e.g., adding personalized ads in Phase 20), update accordingly.

---

## Data Types Collected

### 1. Contact Info - Email Address

- [ ] **Category:** Contact Info → Email Address
- [ ] **Linked to user:** YES (used for account identification)
- [ ] **Used for tracking:** NO (not used for advertising or analytics tracking)
- [ ] **Purposes:** App Functionality (account creation and authentication)
- [ ] **Third party:** Clerk (authentication provider)

**Details:** Email collected during Sign in with Apple or manual registration. Managed by Clerk authentication service.

---

### 2. Audio Data

- [ ] **Category:** Audio Data → Voice or Sound Recordings
- [ ] **Linked to user:** YES (voice profile tied to user account)
- [ ] **Used for tracking:** NO (not used for advertising or analytics tracking)
- [ ] **Purposes:** App Functionality (voice cloning for recipe narration)
- [ ] **Third party:** ElevenLabs (AI voice cloning provider)

**Details:** 30-60 second voice samples uploaded by user to create cloned voice for recipe narration. Processed by ElevenLabs, stored on Cloudflare R2 backup. User can delete anytime from Settings → Privacy & Data.

---

### 3. User Content - Other User Content

- [ ] **Category:** User Content → Other User Content
- [ ] **Linked to user:** YES (bookmarks and pantry items are user-specific)
- [ ] **Used for tracking:** NO (not used for advertising or analytics tracking)
- [ ] **Purposes:** App Functionality (save recipes, track pantry inventory)
- [ ] **Third party:** None (stored on Kindred backend)

**Details:** Includes recipe bookmarks, pantry items (ingredients with expiry dates), and dietary preferences. Stored on Kindred backend with user authentication.

---

### 4. Identifiers - User ID

- [ ] **Category:** Identifiers → User ID
- [ ] **Linked to user:** YES (unique identifier for user account)
- [ ] **Used for tracking:** NO (not used for advertising or analytics tracking)
- [ ] **Purposes:** App Functionality (account management and data sync)
- [ ] **Third party:** Clerk (authentication provider)

**Details:** Clerk-generated user identifier (CUID format) used for backend API authentication and data association.

---

### 5. Usage Data - Product Interaction

- [ ] **Category:** Usage Data → Product Interaction
- [ ] **Linked to user:** NO (anonymous analytics, not tied to identity)
- [ ] **Used for tracking:** NO (no cross-app or cross-site tracking)
- [ ] **Purposes:** Analytics (improve app experience, understand feature usage)
- [ ] **Third party:** Firebase Analytics

**Details:** Anonymous usage patterns such as button taps, screen views, feature engagement. No personally identifiable information collected. Used to improve app design and prioritize features.

---

### 6. Diagnostics - Crash Data

- [ ] **Category:** Diagnostics → Crash Data
- [ ] **Linked to user:** NO (anonymous crash logs, not tied to identity)
- [ ] **Used for tracking:** NO (no cross-app or cross-site tracking)
- [ ] **Purposes:** App Functionality (fix bugs and improve stability)
- [ ] **Third party:** Firebase Crashlytics

**Details:** Anonymous crash reports including stack traces, device model, OS version. No personally identifiable information. Used exclusively for debugging and improving app reliability.

---

### 7. Location - Coarse Location

- [ ] **Category:** Location → Coarse Location
- [ ] **Linked to user:** NO (city stored device-only, not sent to backend after onboarding)
- [ ] **Used for tracking:** NO (no location tracking beyond initial onboarding)
- [ ] **Purposes:** App Functionality (show locally trending recipes)
- [ ] **Third party:** Mapbox (geocoding service during onboarding)

**Details:** City-level location detected once during onboarding via Mapbox geocoding. Stored on device only. Not transmitted to backend servers after initial setup. Used to personalize recipe discovery with local trends.

---

### 8. Financial Info - Purchase History

- [ ] **Category:** Financial Info → Purchase History
- [ ] **Linked to user:** YES (subscription status tied to user account)
- [ ] **Used for tracking:** NO (not used for advertising or analytics tracking)
- [ ] **Purposes:** App Functionality (subscription management and access control)
- [ ] **Third party:** Apple (StoreKit in-app purchases)

**Details:** Subscription purchase status (free tier vs premium). Managed entirely by Apple StoreKit. Kindred verifies subscription status via StoreKit API for feature access control.

---

## Data NOT Collected

Mark **NO** for these categories in App Store Connect:

- [ ] Health & Fitness
- [ ] Physical Address
- [ ] Phone Number
- [ ] Name (full name not required - voice profile uses nicknames)
- [ ] Contacts
- [ ] Photos or Videos
- [ ] Browsing History
- [ ] Search History
- [ ] Sensitive Info (race, ethnicity, political beliefs, etc.)
- [ ] Precise Location (GPS coordinates)
- [ ] Other Data Types not listed above

**Note:** If future features collect additional data types, update this checklist accordingly.

---

## Tracking Status

- [ ] **Question:** "Does your app or third-party partners collect data from this app to track users across apps or websites owned by other companies?"
  - **Answer:** NO
  - **Reason:** Kindred v4.0 does not use IDFA (Identifier for Advertisers), does not enable personalized advertising, and does not track users across apps or websites.

**Important:** If Phase 20 (Subscription & Billing) enables personalized AdMob ads with IDFA:
1. Change tracking status to YES
2. Add ATT (App Tracking Transparency) prompt to app
3. Update this checklist to reflect new tracking disclosure
4. Add IDFA to Identifiers category in nutrition labels

---

## Privacy Policy URL

**Production URL:** `https://api.kindred.app/privacy`
**Staging URL (for testing):** `https://staging-api.kindred.app/privacy`

### Pre-Submission Checklist

Before submitting to App Store Connect, verify:

- [ ] Privacy policy URL is publicly accessible (no authentication required)
- [ ] Privacy policy loads successfully in Safari (not just SFSafariViewController)
- [ ] Privacy policy contains all required sections (data collection, user rights, contact info)
- [ ] Privacy policy naming matches app name ("Kindred")
- [ ] Effective date is current
- [ ] Contact email (privacy@kindred.app) is active and monitored

**Test command:**
```bash
curl -I https://api.kindred.app/privacy
# Should return: HTTP/1.1 200 OK
# Should NOT return: 401 Unauthorized or 403 Forbidden
```

---

## App Store Connect Navigation

### Where to Fill This Out

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **My Apps** → **Kindred** → **App Privacy**
3. Click **Get Started** (first time) or **Edit** (updating existing)
4. Answer the questionnaire using this checklist as reference

### Question Flow

App Store Connect will ask:

1. **Data Collection:** "Does this app collect data?" → YES
2. **Data Types:** Select 8 categories as documented above
3. **For each data type:** Answer linkage, tracking, purposes (use checklist)
4. **Tracking:** "Do you or your third-party partners use data to track?" → NO
5. **Privacy Policy:** Enter URL: `https://api.kindred.app/privacy`

### Submission Validation

After submitting privacy details, App Store Connect will:

- Validate privacy policy URL is publicly accessible
- Check that PrivacyInfo.xcprivacy manifest matches declared data types
- Warn if any Required Reason APIs are undeclared
- Display preview of nutrition labels as they appear to users

---

## Version History

| Version | Date | Changes | Updated By |
|---------|------|---------|------------|
| 4.0 | March 30, 2026 | Initial nutrition labels for v4.0 launch | Phase 18-02 |
| | | Future: Add personalized ads tracking if Phase 20 implements IDFA | |

---

## Notes for Future Updates

### Phase 20 (Subscription & Billing)

If personalized AdMob ads are enabled:

- [ ] Change tracking status to YES
- [ ] Add ATT prompt implementation
- [ ] Update PrivacyInfo.xcprivacy with NSPrivacyTracking: true
- [ ] Add advertising tracking domains to NSPrivacyTrackingDomains
- [ ] Add IDFA to Identifiers category
- [ ] Update privacy policy with personalized advertising disclosure

### Phase 21+ (Account Deletion)

If account deletion is implemented:

- [ ] Update privacy policy with account deletion process
- [ ] Add in-app link to account deletion flow in Settings
- [ ] Verify GDPR compliance (30-day data retention, etc.)

### Legal Counsel Review

Voice cloning consent language requires legal counsel review for multi-state compliance:

- Tennessee ELVIS Act (biometric voice protection)
- California AB 1836 (digital replicas)
- Federal AI Voice Act (pending legislation)
- GDPR biometric data consent (Art. 9)

**Budget:** $20-50K for AI/media legal counsel
**Timeline:** 2-4 weeks for review (can run parallel to technical work)

---

## Contact

**Questions about this checklist?**
Internal: Phase 18 documentation
Apple Support: [App Privacy Details - Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)

**Privacy inquiries from users:**
Email: privacy@kindred.app

---

*Last updated: March 30, 2026*
*Phase: 18-privacy-compliance-consent*
*Plan: 18-02*
