# Deferred Items - Phase 21

## Pre-existing Build Blockers

### KindredAPI GraphQL Code Generation Error
**Discovered during:** Plan 21-04, Task 1 (GuestSessionStore ModelConfiguration)
**File:** `Kindred/Packages/KindredAPI/Sources/Operations/Queries/VoiceProfilesQuery.graphql.swift:55`
**Error:** `error: no type named 'Enums' in module 'KindredAPI'`
**Impact:** Blocks all xcodebuild commands (FeedFeature, KindredAPI, Kindred schemes)
**Root cause:** GraphQL code generation issue - VoiceProfilesQuery references `KindredAPI.Enums.VoiceStatus` but the `Enums` namespace doesn't exist in the generated schema
**Out of scope:** Pre-existing error in unrelated file (VoiceProfilesQuery vs GuestSessionClient changes)
**Resolution needed:** Regenerate GraphQL schema or fix code generation configuration

**Status:** Deferred - not caused by Phase 21 changes, not blocking Phase 21 completion verification
