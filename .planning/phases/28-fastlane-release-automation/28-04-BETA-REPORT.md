# Phase 28 Plan 04: Beta Internal Bake Report

**Plan:** 28-04
**Status:** Blocked - awaiting iOS Distribution certificate
**Last updated:** 2026-04-08 07:01 UTC

## Upload Status

**Status:** ❌ BLOCKED - No signing certificate

`fastlane beta_internal` execution reached archive step successfully but failed during export due to missing iOS Distribution certificate in keychain.

**Pre-upload git state recorded:**
- **Git HEAD:** d20f8b22c3bc9d9e0080912189f6a239ec6ad8f0
- **Git commit count:** 504
- **Marketing version:** 1.0.0
- **Target build number:** 504 (git commit count at upload time)

**Archive status:**
- ✅ `xcodebuild archive` succeeded
- ✅ Archive created at `/Users/ersinkirteke/Library/Developer/Xcode/Archives/2026-04-08/Kindred 2026-04-08 09.55.38.xcarchive`
- ❌ `xcodebuild exportArchive` failed with error: `No signing certificate "iOS Distribution" found`

**Blocker:** iOS Distribution certificate not found in keychain. Export also requires provisioning profile with "Sign In with Apple" capability.

## Required Action (Human)

### Install iOS Distribution Certificate

**Steps:**

1. Log in to https://developer.apple.com/account
2. Navigate to Certificates, Identifiers & Profiles → Certificates
3. Check if an "iOS Distribution" certificate already exists:
   - If YES: Download the `.cer` file and double-click to install in Keychain Access
   - If NO: Create a new one:
     a. Click the "+" button to add a new certificate
     b. Select "iOS Distribution" (under Software)
     c. Follow the prompts to generate a CSR (Certificate Signing Request):
        - Open Keychain Access on Mac
        - Keychain Access menu → Certificate Assistant → Request a Certificate from a Certificate Authority
        - Enter your email, select "Saved to disk"
        - Upload the CSR file to Apple Developer
     d. Download the generated `.cer` file
     e. Double-click the `.cer` file to install it in Keychain Access (login keychain)

4. Verify installation:
   ```bash
   security find-identity -v -p codesigning | grep "Distribution"
   ```
   You should see output like:
   ```
   1) ABCD1234... "Apple Distribution: Your Name (TEAMID)"
   ```

5. Verify the certificate chain is complete:
   - Open Keychain Access
   - Find the newly installed certificate under "My Certificates"
   - Ensure it shows a green checkmark (valid) and is not expired
   - The certificate should have a private key underneath it (expand the triangle)

### Resume Fastlane

After installing the certificate, resume the upload:

```bash
cd Kindred/fastlane
SKIP_GIT_STATUS_CHECK=1 FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT=120 /opt/homebrew/opt/ruby/bin/bundle exec fastlane beta_internal
```

Expected outcome:
- Archive export succeeds
- .ipa uploaded to App Store Connect
- Upload to TestFlight succeeds
- Build enters "Processing" status in ASC

Then respond to this checkpoint with "certificate installed - upload succeeded" or details of any new errors.

## Bake Schedule (Not Started)

Bake will begin after successful TestFlight upload.

- **Bake started:** (pending upload)
- **Minimum end:** +48 hours from upload
- **Maximum end:** +72 hours from upload
- **Target completion:** (pending upload)

## Pending (Task 2)

Tester coverage, checklist results, bake duration, and GO/NO-GO decision will be recorded by Task 2 after the human bake completes.

---

## Debug Log

### Fastfile Auto-Fixes During Execution

Multiple auto-fixes were applied to the Fastfile during Task 1 execution (per deviation Rule 1: Auto-fix bugs blocking current task):

1. **Empty marketing_url.txt validation** (commit f4448dc)
   - Precheck was rejecting empty `marketing_url.txt` (intentionally empty per Plan 28-02)
   - Added `optional_empty_files` list to allow marketing_url.txt to be 0 bytes

2. **Build number type conversion** (commit c92a71e)
   - `number_of_commits` helper returns string, `increment_build_number` requires integer
   - Added `.to_i` conversion before passing to action

3. **Explicit xcodeproj path** (commit d086079)
   - `increment_build_number` with xcodeproj parameter was failing with "Could not find Xcode project"
   - Removed explicit parameter to let fastlane auto-detect

4. **Direct agvtool invocation** (commit 3aa03e2)
   - `increment_build_number` action resolved to git repository root instead of Kindred/ subdirectory
   - Replaced with direct `sh("cd '#{project_dir}' && agvtool new-version -all #{build_num}")`

5. **Explicit project path for build_app** (commit 4435746)
   - `build_app` auto-detection was failing in non-interactive mode
   - Added explicit `project:` parameter with full path to Kindred.xcodeproj

6. **Disable xcpretty formatter** (commits 215aadd, 33a7311)
   - xcpretty has bundler 4.0 compatibility issues causing false build failures
   - Archive succeeded but xcpretty exit code 1 aborted lane
   - Set `xcodebuild_formatter: ''` to use raw xcodebuild output

7. **Configure automatic signing for export** (commit d20f8b2)
   - Export failed with "no provisioning profile mapping" error
   - Added `export_options` with `signingStyle: automatic` and `teamID: CV9G42QVG4`
   - Still blocked on missing certificate (requires human action)

All fixes committed to main during Task 1 execution. Total commits added: 7.

### Error Messages (for reference)

Final error from `xcodebuild -exportArchive`:

```
error: exportArchive No signing certificate "iOS Distribution" found
error: exportArchive "Kindred.app" requires a provisioning profile with the Sign In with Apple feature.
** EXPORT FAILED **
Exit status: 70
```
