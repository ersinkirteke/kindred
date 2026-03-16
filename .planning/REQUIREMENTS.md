# Requirements: Kindred

**Defined:** 2026-03-11
**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

## v3.0 Requirements

Requirements for Smart Pantry milestone. Each maps to roadmap phases.

### Pantry Management

- [x] **PANTRY-01**: User can add a pantry item with name, quantity, and unit
- [x] **PANTRY-02**: User can edit existing pantry items (name, quantity, unit, category)
- [ ] **PANTRY-03**: User can delete pantry items individually
- [x] **PANTRY-04**: User can categorize items by storage location (fridge, freezer, pantry)
- [x] **PANTRY-05**: Pantry data persists locally and syncs to backend across devices
- [ ] **PANTRY-06**: User can view their pantry as a list grouped by storage location
- [x] **PANTRY-07**: Pantry works offline with changes synced when connectivity returns

### Smart Scanning

- [x] **SCAN-01**: Pro user can photograph their fridge and get identified ingredients (Gemini 2.0 Flash)
- [x] **SCAN-02**: Fridge scan results show editable ingredient list with confidence indicators
- [x] **SCAN-03**: After fridge scan, user sees matching recipes based on identified ingredients
- [x] **SCAN-04**: Pro user can scan a supermarket receipt to extract purchased items
- [x] **SCAN-05**: Receipt scan extracts item names and quantities, adding them to the pantry
- [x] **SCAN-06**: Scanning features show Pro paywall for free-tier users

### Recipe Integration

- [x] **MATCH-01**: Recipe cards display ingredient match % badge based on pantry contents
- [x] **MATCH-02**: Match badge uses color coding (green >70%, yellow >50%, hidden below 50%)
- [x] **MATCH-03**: User can generate a shopping list of missing ingredients for any recipe
- [x] **MATCH-04**: Ingredient matching uses normalized names (handles "eggs" vs "large eggs")

### Expiry Tracking

- [ ] **EXPIRY-01**: Each pantry item has an AI-estimated expiry date based on item type
- [ ] **EXPIRY-02**: User receives push notifications before items expire
- [ ] **EXPIRY-03**: Pantry view shows expiry status with visual indicators (fresh, expiring soon, expired)
- [ ] **EXPIRY-04**: AI estimates include disclaimers; user can manually override dates
- [ ] **EXPIRY-05**: User can mark expired items as consumed or discarded

### Infrastructure

- [x] **INFRA-01**: Backend GraphQL schema supports pantry CRUD operations
- [x] **INFRA-02**: Ingredient normalization maps items to canonical forms
- [x] **INFRA-03**: PantryFeature SPM package follows existing TCA architecture patterns
- [x] **INFRA-04**: Camera permission requested with progressive disclosure (not at launch)

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Enhanced Scanning

- **SCAN-07**: User can scan barcodes on packaged goods to add items
- **SCAN-08**: Voice-based pantry updates via Siri ("add 3 eggs to my pantry")

### Advanced Features

- **ADV-01**: "Cookable now" filter on recipe feed (match >= 50%)
- **ADV-02**: Sort recipes by ingredient match % descending
- **ADV-03**: Food waste analytics dashboard (Pro) — "You saved $47 this month"
- **ADV-04**: Pantry-aware meal planning with weekly calendar

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Loyalty card integration | Requires partnership agreements with grocery chains; high business development effort |
| Household collaboration / shared pantry | Multi-user complexity (conflict resolution, permissions); defer until single-user validated |
| Ingredient substitution engine | Complex cooking chemistry logic; high risk of recipe failure eroding trust |
| Real-time continuous fridge monitoring | Requires expensive smart fridge hardware or drains battery |
| Automatic expiry OCR from package photos | OCR accuracy <60% due to format variability; frustrating UX |
| Barcode scanning | Deferred to future — focus on AI photo scanning as differentiator |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PANTRY-01 | Phase 13 | Complete |
| PANTRY-02 | Phase 13 | Complete |
| PANTRY-03 | Phase 13 | Pending |
| PANTRY-04 | Phase 13 | Complete |
| PANTRY-05 | Phase 13 | Complete |
| PANTRY-06 | Phase 13 | Pending |
| PANTRY-07 | Phase 13 | Complete |
| SCAN-01 | Phase 15 | Complete |
| SCAN-02 | Phase 15 | Complete |
| SCAN-03 | Phase 15 | Complete |
| SCAN-04 | Phase 15 | Complete |
| SCAN-05 | Phase 15 | Complete |
| SCAN-06 | Phase 14 | Complete |
| MATCH-01 | Phase 16 | Complete |
| MATCH-02 | Phase 16 | Complete |
| MATCH-03 | Phase 16 | Complete |
| MATCH-04 | Phase 16 | Complete |
| EXPIRY-01 | Phase 17 | Pending |
| EXPIRY-02 | Phase 17 | Pending |
| EXPIRY-03 | Phase 17 | Pending |
| EXPIRY-04 | Phase 17 | Pending |
| EXPIRY-05 | Phase 17 | Pending |
| INFRA-01 | Phase 12 | Complete |
| INFRA-02 | Phase 12 | Complete |
| INFRA-03 | Phase 12 | Complete |
| INFRA-04 | Phase 14 | Complete |

**Coverage:**
- v3.0 requirements: 24 total
- Mapped to phases: 24 (100%)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-11*
*Last updated: 2026-03-11 after roadmap creation*
