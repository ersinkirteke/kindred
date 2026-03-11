# Feature Research

**Domain:** Smart Pantry Management (iOS Food/Cooking Apps)
**Researched:** 2026-03-11
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Manual pantry item add/edit/delete | Fallback when scanning fails; users need control over their inventory | LOW | SwiftUI CRUD operations with local persistence (Core Data/SwiftData). Studies show manual entry creates intentionality - "typing '3 eggs' into the app, I'm already thinking about breakfast tomorrow" |
| Barcode scanning for packaged goods | Speeds up item entry for bulk purchases; 99% accuracy expectation for packaged foods | MEDIUM | iOS Vision framework VNDetectBarcodesRequest. Database integration (Open Food Facts, USDA) for product lookup. ~79% of products deviate <5% from true nutritional values |
| Expiry date tracking with reminders | Core value proposition - prevent food waste; users expect alerts before items expire | MEDIUM | Date storage + local notification scheduling. Best practice: limit to 4-5 weekly notifications to avoid 73% disable rate. Smart timing (e.g., 3 days before expiry, 1 day before) |
| Basic ingredient matching to recipes | "What can I make with what I have?" is the #1 pantry app use case | MEDIUM | Query existing recipe database filtered by available ingredients. Display match ratio (e.g., "8/10 ingredients"). SuperCook showed this is expected behavior |
| Shopping list generation from missing ingredients | Users need to know what to buy for recipes; prevents app switching | LOW | Compare recipe ingredients against pantry inventory; generate diff list. Common pattern: "Add to shopping list" button on recipe cards |
| Persistent digital pantry inventory | Users expect state to persist across sessions; cloud sync for multi-device | MEDIUM | Local persistence (Core Data/SwiftData) + iCloud sync. Challenge: keeping mobile + cloud in sync without conflicts |
| Categorization by storage location | Organize by fridge/freezer/pantry/spices; improves findability and mental model | LOW | Enum-based categorization with filter UI. Manual apps support location tagging unlike camera-only solutions |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Photo-based fridge scanning (AI recognition) | Premium feature; bulk capture multiple items at once vs one-by-one barcode scanning | HIGH | CoreML custom food classification model (Food101 dataset: 86.97% Top-1, 97.42% Top-5 accuracy). Challenges: mixed dishes, overlapping foods, poor lighting. GE Profile Smart Fridge ($4,899) has built-in camera showing market demand |
| Receipt OCR for batch grocery import | Instant pantry population after shopping trip; saves 10+ minutes manual entry | HIGH | Transformer-based OCR (Vision framework + custom model or TabScanner API). Line-item extraction achieves >95% accuracy for vendor/date/amounts but item categorization is harder. International support needed (multi-currency, 10+ languages) |
| AI expiry estimation for fresh items | Estimate shelf life for produce without expiry dates (e.g., "bananas: 5-7 days") | MEDIUM-HIGH | ML model trained on USDA shelf life data + user feedback loop. Differentiate "Best By" vs "Use By". Smart Home Integration: Samsung Family Hub already does this |
| Match percentage badge on recipe cards | Visual indicator of "cookability" based on pantry contents; reduces decision friction | LOW | Calculate intersection: (pantry ∩ recipe) / recipe * 100. Display as badge or progress ring. Case studies show recipe cards with ingredient ratios increase engagement |
| Loyalty card integration (US grocery stores) | Auto-populate pantry from store purchases; zero manual entry for Cooklist users | HIGH | API integration with Kroger, Safeway, Target APIs. Requires partnership agreements. Cooklist's key differentiator - connects to 1M+ recipes automatically |
| Food waste analytics & insights | Gamification: "You saved $47 this month"; aligns with sustainability values | MEDIUM | Track consumed vs wasted items; monthly reports. ConsumeSmart and NourishMate show users save $2,000+ annually with visibility. Behavioral psychology: tracking reduces waste |
| Voice-based pantry updates | Hands-free "Hey Siri, add milk to pantry" while cooking; aligns with existing voice narration feature | MEDIUM | SiriKit App Intents integration. Natural synergy with Kindred's voice playback feature - unified audio experience |
| Pantry-aware meal planning | Weekly meal plans that prioritize using expiring items; proactive not reactive | MEDIUM | Constraint solver: prioritize recipes containing items expiring in 3-7 days. Paprika and Portions Master show demand for planning + pantry integration |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-time camera-based continuous fridge monitoring | "Smart fridge" appeal; GE Profile/Samsung marketing creates expectation | Requires $4,899 smart fridge hardware OR constant camera access draining battery. Privacy concerns with always-on camera. 91.1% recipe match rate requires ingredient RULES not just AI | Photo-on-demand: user snaps photo when needed. Batch recognition, not continuous. "Scan fridge now" button |
| Automatic expiry detection from package photos | Seems smarter than manual date entry | OCR on package dates has poor accuracy (<60%) due to date format variability, small print, curved surfaces. Vision framework struggles with poor-quality images. Better to fail gracefully than give false confidence | OCR-assisted manual entry: pre-populate date field but require user confirmation. Provide smart defaults based on product type (e.g., "milk: typical 7-14 days") |
| Ingredient substitution suggestions for every recipe | AI hype: "ran out of X? use Y!" | Determining "good" substitutions requires context (allergies, dietary restrictions, cooking chemistry). One-to-many and many-to-one substitutions are computationally complex. Risk of recipe failure erodes trust | Focus on recipe discovery with available ingredients instead of forcing substitutions. If implemented, limit to common swaps (butter↔oil) with confidence scores. Don't suggest exotic replacements |
| Social pantry sharing & comparisons | Community features drive engagement | Privacy sensitive: users don't want neighbors knowing their food habits. "Keeping up with Joneses" creates negative emotion. Adds social layer complexity (moderation, reporting) for unclear value | Keep collaborative features to household level only: shared family pantry with role-based access (Cooklist pattern). Multi-device sync, not multi-household |
| Gamification with leaderboards/badges | Engagement mechanics from other apps | Food waste prevention is personal utility not competitive sport. Risk of encouraging unhealthy behavior (e.g., eating expired food to "win"). Leaderboards require large user base for meaningful comparison | Personal progress tracking: "You reduced waste 15% this month vs last month". Compare user to themselves, not others. Celebrate milestones (e.g., "30-day streak of zero waste") |
| Every scanning method at once | Perception that more input methods = better UX | Overwhelming UI: barcode scanner, photo scanner, receipt scanner, voice input, manual entry = 5 ways to do same thing. Increases QA surface, maintenance burden. Data shows users pick ONE preferred method and stick with it | Progressive disclosure: default to barcode scan (most accurate), "Can't find barcode?" → manual entry. Hide advanced methods (receipt scan, photo scan) behind Pro paywall or settings. Voice as auxiliary, not primary |

## Feature Dependencies

```
[Persistent Digital Pantry]
    └──requires──> [Manual Item CRUD]
    └──requires──> [Local Persistence (Core Data)]

[Barcode Scanning]
    └──requires──> [Food Database Integration]
                       └──requires──> [API Client (Open Food Facts)]

[Receipt OCR Scanning]
    └──requires──> [Barcode Scanning] (fallback for line items)
    └──requires──> [Item Categorization Logic]

[Photo-based Fridge Scanning]
    └──requires──> [CoreML Food Classification Model]
    └──requires──> [Manual Item CRUD] (correction UI)

[Expiry Date Tracking]
    └──requires──> [Persistent Digital Pantry]
    └──requires──> [Local Notification Permissions]

[AI Expiry Estimation]
    └──requires──> [Expiry Date Tracking]
    └──requires──> [USDA Shelf Life Dataset]

[Ingredient Matching to Recipes]
    └──requires──> [Persistent Digital Pantry]
    └──requires──> [Recipe Database] (already exists in Kindred)

[Match % Badge on Recipe Cards]
    └──requires──> [Ingredient Matching to Recipes]
    └──requires──> [Recipe Card UI] (already exists in Kindred)

[Shopping List from Missing Ingredients]
    └──requires──> [Ingredient Matching to Recipes]
    └──requires──> [Persistent Digital Pantry]

[Food Waste Analytics]
    └──requires──> [Expiry Date Tracking]
    └──requires──> [Item Consumption Logging]

[Voice-Based Pantry Updates]
    └──requires──> [SiriKit App Intents]
    └──requires──> [Manual Item CRUD]

[Pantry-Aware Meal Planning]
    └──requires──> [Persistent Digital Pantry]
    └──requires──> [Expiry Date Tracking]
    └──requires──> [Ingredient Matching to Recipes]
```

### Dependency Notes

- **Receipt OCR requires Barcode Scanning:** When OCR can't determine item category from text, fallback to barcode lookup for known products. This is why receipt scanning complexity is HIGH - it's a composition of multiple subsystems.

- **Photo Scanning requires Manual CRUD:** AI misidentifies items ~13% of the time (Top-1 accuracy 87%). Users MUST be able to correct mistakes or scanning becomes frustrating. Correction UI is non-negotiable.

- **Match % Badge requires existing Recipe Database:** LOW complexity only because Kindred already has recipe infrastructure. For new apps, this would be MEDIUM complexity.

- **All scanning methods require Manual CRUD fallback:** Scanning accuracy is never 100%. Manual entry is the reliability escape hatch. Any app without manual entry will have 1-star reviews from users who couldn't add items.

- **Loyalty Card Integration is INDEPENDENT:** Doesn't require other scanning methods. Can be Phase 1 feature if APIs are accessible, but partnership agreements make this HIGH complexity.

- **AI Expiry Estimation enhances Expiry Tracking:** Optional intelligence layer on top of basic tracking. Start with manual entry + barcode database lookups, add AI estimation later for fresh produce.

## MVP Definition

### Launch With (v1) — THIS MILESTONE

Minimum viable product to validate pantry concept with existing Kindred users.

- [x] **Manual pantry item add/edit/delete** — Essential fallback; LOW complexity; builds on existing SwiftUI patterns
- [x] **Persistent digital pantry with iCloud sync** — Core feature; users expect inventory to persist; leverages existing Kindred sync architecture
- [x] **Expiry date tracking with push notifications** — Primary value proposition (prevent food waste); MEDIUM complexity but proven pattern
- [x] **Barcode scanning for packaged goods** — Table stakes; users expect fast entry; Vision framework makes this achievable
- [x] **Basic ingredient matching to recipes** — Answers "what can I make?" query; leverages existing recipe database (LOW complexity due to existing infra)
- [x] **Match % badge on recipe cards** — Visual indicator of cookability; LOW complexity, HIGH perceived value differentiator
- [x] **Shopping list generation from missing ingredients** — Completes workflow loop; prevents app switching

**Why this MVP:**
- Focuses on UTILITY over novelty: helps users answer "what's in my fridge?" and "what can I cook?"
- Leverages existing Kindred infrastructure (recipe database, SwiftUI patterns, iCloud sync)
- Avoids high-risk AI features (photo scanning, receipt OCR) that require extensive training data
- All features have MEDIUM or LOW complexity
- Validates core hypothesis: do Kindred users want pantry management alongside recipe discovery?

**PRO tier gating:**
- Photo-based fridge scanning (AI recognition) — Premium differentiator
- Receipt OCR for batch import — Premium differentiator
- Food waste analytics dashboard — Premium value-add

### Add After Validation (v1.x)

Features to add once core is working and user feedback validates direction.

- [ ] **AI expiry estimation for fresh items** — Trigger: Users request help with produce without expiry dates (bananas, lettuce). Requires USDA dataset integration.
- [ ] **Food waste analytics & insights** — Trigger: 60+ days of data per user to show meaningful trends. Gamification angle for retention.
- [ ] **Photo-based fridge scanning (Pro)** — Trigger: Users complain barcode scanning is too slow for bulk pantry audits. Requires CoreML model training on Food101 dataset.
- [ ] **Receipt OCR scanning (Pro)** — Trigger: Users request post-shopping import workflow. Requires OCR accuracy >95% or support burden spikes.
- [ ] **Voice-based pantry updates via Siri** — Trigger: Users request hands-free workflow during cooking. Natural extension of voice narration feature.
- [ ] **Categorization by storage location** — Trigger: Users with large inventories (50+ items) need organization. Low cost, high value for power users.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Loyalty card integration for auto-population** — Why defer: Requires partnership agreements with grocery chains. HIGH business development effort. Pursue after proving pantry PMF.
- [ ] **Pantry-aware meal planning** — Why defer: Requires sophisticated constraint solver. Build after understanding user planning patterns (weekly vs daily planners?).
- [ ] **Household collaboration with shared pantries** — Why defer: Multi-user complexity (conflict resolution, permissions). Validate single-user experience first.
- [ ] **Ingredient substitution engine** — Why defer: Complex cooking chemistry logic. High risk of recipe failure eroding trust. Needs culinary expertise.
- [ ] **Export pantry data to CSV/PDF** — Why defer: Power user feature. Build after understanding what users want to export and why.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Manual item CRUD | HIGH | LOW | P1 |
| Persistent pantry inventory | HIGH | MEDIUM | P1 |
| Barcode scanning | HIGH | MEDIUM | P1 |
| Expiry tracking + notifications | HIGH | MEDIUM | P1 |
| Ingredient matching to recipes | HIGH | MEDIUM | P1 |
| Match % badge on recipe cards | MEDIUM | LOW | P1 |
| Shopping list generation | MEDIUM | LOW | P1 |
| Photo-based fridge scanning (Pro) | MEDIUM | HIGH | P2 |
| Receipt OCR (Pro) | MEDIUM | HIGH | P2 |
| AI expiry estimation | MEDIUM | MEDIUM | P2 |
| Food waste analytics | MEDIUM | MEDIUM | P2 |
| Voice pantry updates (Siri) | LOW | MEDIUM | P2 |
| Storage location categorization | LOW | LOW | P2 |
| Loyalty card integration | LOW | HIGH | P3 |
| Pantry-aware meal planning | MEDIUM | HIGH | P3 |
| Household collaboration | LOW | HIGH | P3 |
| Ingredient substitution engine | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch (v1.0) — 7 features
- P2: Should have, add when possible (v1.x) — 6 features
- P3: Nice to have, future consideration (v2+) — 4 features

**Cost/Value Analysis:**
- **Quick wins (High Value, Low Cost):** Manual CRUD, Match % badge, Shopping list — implement immediately
- **Strategic investments (High Value, Medium Cost):** Barcode scanning, Expiry tracking, Ingredient matching — core MVP
- **Avoid traps (Low Value, High Cost):** Loyalty card integration, Household collaboration — defer indefinitely unless user demand spikes

## Competitor Feature Analysis

| Feature | Cooklist | SuperCook | Portions Master | Kindred Smart Pantry |
|---------|----------|-----------|-----------------|----------------------|
| **Manual item entry** | Yes | Yes (from list of 2000+) | Yes | Yes — SwiftUI forms |
| **Barcode scanning** | Yes | No | Yes | Yes — Vision framework |
| **Photo-based scanning** | No | No | Yes (AI recognition) | Yes (Pro) — CoreML Food101 |
| **Receipt OCR** | No | No | No | Yes (Pro) — transformer OCR |
| **Expiry tracking** | Basic | No | Yes with alerts | Yes — push notifications |
| **Recipe matching** | Yes (1M+ recipes from loyalty cards) | Yes (only shows makeable recipes) | Yes with AI recommendations | Yes — leverage existing recipe DB |
| **Match % indicator** | No | Implicit (binary: can/can't make) | No | YES — differentiator |
| **Shopping list** | Yes | No (shows only makeable) | Yes | Yes — from missing ingredients |
| **Loyalty card integration** | YES — key differentiator | No | No | No (defer to v2) |
| **Food waste analytics** | No | No | Basic tracking | Yes (v1.x) — save $2K/year messaging |
| **Voice input** | No | No | No | YES — leverages existing voice feature |

**Our Competitive Position:**
- **Differentiation:** Match % badge + Voice integration (unique to Kindred ecosystem)
- **Parity:** Barcode scanning, expiry tracking, recipe matching (table stakes)
- **Strategic omission:** Loyalty card integration (HIGH cost, niche value for non-US users)
- **Premium upsell:** Photo scanning + Receipt OCR behind Pro tier (monetization strategy)

**Why we can win:**
1. **Existing user base:** 10K+ Kindred users already engaged with recipes; pantry is natural extension
2. **Unified experience:** Voice narration + voice pantry updates = cohesive audio-first brand
3. **Recipe database advantage:** Competitors like SuperCook require users to find recipes; we have curated feed
4. **Pro tier infrastructure:** Already have StoreKit 2 + AdMob; easy to gate premium scanning features
5. **International focus:** Turkish + English bilingual from day 1; competitors are US-centric (Cooklist loyalty cards)

## Sources

### Ecosystem & Competing Products
- [GE Profile Smart Refrigerator with Kitchen Assistant](https://pressroom.geappliances.com/news/ge-profileTM-unveils-game-changing-smart-refrigerator-with-kitchen-assistantTM-revolutionizing-grocery-shopping-and-meal-planning) — $4,899 fridge with built-in barcode scanner; shows enterprise investment in pantry tech
- [Portions Master: Best Pantry Inventory App](https://portionsmaster.com/blog/best-pantry-inventory-app-and-fridge-management-tool/) — Image recognition + barcode scanning, AI meal recommendations
- [Cooklist App Store](https://apps.apple.com/us/app/cooklist-pantry-meals-recipes/id1352600944) — Loyalty card integration, 1M+ recipes matched to purchases
- [SuperCook](https://www.supercook.com/) — Only shows recipes with available ingredients; 2000+ ingredient list
- [ConsumeSmart](https://www.consumesmart.com/) — AI grocery/pantry app; receipt scanning, expiry tracking, meal suggestions

### User Expectations & Best Practices
- [Top 12 Best Cooking Apps for Android 2026](https://www.recipeone.app/blog/best-cooking-apps-for-android) — AI pantry scanning locked behind $6.99/month subscriptions
- [Best Meal Planning Apps 2026](https://www.foodieprep.ai/blog/meal-planning-apps-in-2026-which-tools-actually-simplify-your-kitchen) — Smarter grocery workflows, pantry-aware suggestions, price-aware substitutions
- [Complete Guide to Smart Pantry Management](https://www.nourishmate.app/blog/complete-guide-smart-pantry-management) — Users save $2,000+ annually with pantry visibility
- [Best Meal Planning Apps 2026 Comparison](https://cookingwithrobots.com/blog/best-meal-planning-app-2026) — Household collaboration with shared collections and role-based access

### Technical Implementation
- [Food Barcode Scanning Quality Assessment](https://pmc.ncbi.nlm.nih.gov/articles/PMC10260744/) — 99% availability, 79% within 5% accuracy for energy values
- [Vision Framework Image Detection Guide](https://www.davydovconsulting.com/ios-app-development/using-vision-framework-for-image-analysis) — Vision struggles with poor-quality images; needs optimization for real-time
- [CoreML Food Classification Models](https://github.com/ph1ps/Food101-CoreML) — Food101 InceptionV3: 86.97% Top-1, 97.42% Top-5 accuracy
- [Receipt OCR Best Practices](https://tabscanner.com/ocr-supermarket-receipts/) — Transformer-based AI, >95% accuracy for vendor/date/amounts, line-item extraction
- [Best Receipt Scanning Apps 2026](https://www.yomio.app/en/blog/best-receipt-scanning-apps) — 10+ languages, multi-currency, bulk scan capabilities

### Food Recognition Challenges
- [AI Food Recognition Accuracy Assessment](https://pmc.ncbi.nlm.nih.gov/articles/PMC11314244/) — Mixed dishes and overlapping foods have higher error rates; accuracy isn't the problem, expectations are
- [Mobile Food Recognition Survey](https://pmc.ncbi.nlm.nih.gov/articles/PMC9818870/) — 90.9% of apps don't distinguish food vs non-food; occlusion and scale ambiguity are key challenges
- [Vision-Language Models for Dietary Assessment](https://arxiv.org/html/2504.06925) — Free-living conditions with varied image quality impact recognition accuracy

### UX Patterns & Design
- [Recipe App UX Case Study: Perfect Recipes](https://blog.tubikstudio.com/case-study-recipes-app-ux-design/) — "Cook" filter preset shows recipes based on available ingredients
- [Recipe Card UI Experiments](https://uxplanet.org/ui-experiments-recipe-cards-options-in-a-food-app-36dce82d7b01) — Display ingredient ratio (8/10), plus/minus servings adjustment, "Add to shopping list" button
- [AI Recipe Ingredient Substitution UX](https://uxdesigncontest.com/contests/ux-design-contest-16.html) — Bolded red color for substitutes, icon differentiation

### Expiry Tracking & Notifications
- [BEEP Expiry Date Tracking App](https://apps.apple.com/us/app/beep-expiry-date-tracking/id1242739153) — Barcode database learns expiration info from user entries
- [Selfly Store Expiry Management](https://www.selflystore.com/selfly-store-expiry-date-management-for-fighting-food-waste/) — Distinguish "Best By" vs "Use By", automatic notifications via email/cloud
- [Push Notification Best Practices 2025](https://www.pushwoosh.com/blog/push-notification-best-practices/) — 73% disable if overwhelmed; limit to 4-5 weekly; timing matters (lunch/dinner)
- [Mobile App Push Notification Best Practices](https://userpilot.com/blog/push-notification-best-practices/) — Triggered by meaningful events; personalized based on user action; 3.48% CTR with emojis

### Food Waste Prevention
- [Rise of Food Waste Apps](https://shapiroe.com/blog/food-waste-app-us/) — Inventory tracking, expiration alerts, recipe suggestions, personalized shopping lists
- [14 Apps Preventing Food Waste](https://foodtank.com/news/2018/09/apps-preventing-food-waste/) — Scan food barcodes, send expiry notifications, storage optimization, AI predictive analytics
- [Food Waste Management App Development](https://emizentech.com/blog/food-waste-management-app-development.html) — Food storage optimization, recipe/shopping integration, AI-powered insights

### Common Pitfalls
- [Pantry Organization Mistakes](https://www.kimsorganizingsolutions.com/single-post/pantry-organization-mistakes-every-home-makes-and-how-to-fix-them) — Misunderstanding "best by" vs "use by"; not checking inventory before shopping; only using horizontal space (30-40% capacity loss)
- [21 Pantry Mistakes That Waste Money](https://kitchenseer.com/pantry-mistakes-waste-money-groceries/) — Duplicate purchases of oregano/pasta; can't remember what's running low; expired items in sauces/spices
- [Smart Fridge Cameras vs Manual Inventory Apps](https://www.alibaba.com/product-insights/smart-fridge-cameras-vs-manual-inventory-apps-which-solution-actually-reduces-food-waste-at-home.html) — Manual entry creates intentionality; "typing '3 eggs' into the app, I'm already thinking about breakfast tomorrow"

### Ingredient Matching & Substitution
- [Ingredient Matching Research](https://www.researchgate.net/publication/234061858_Ingredient_Matching_to_Determine_the_Nutritional_Properties_of_Internet-Sourced_Recipes) — 47.2% match without rules; 91.1% with rules
- [Ingredient Substitution Complexity](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2020.621766/full) — Difficult to identify valid replacements; must consider allergies, nutrition, dietary restrictions, one-to-many/many-to-one substitutions
- [AI Ingredient Substitution with OpenAI](https://samedelstein.medium.com/ingredient-substitution-with-openai-d5274c9f76de) — ML algorithms analyze recipe data; predict outcome of substitutions

### Freemium Models
- [Best Grocery List and Pantry Management Apps](https://www.meetpenny.com/grocery-list-and-pantry-management-apps/) — Free: 200 item limit; Premium: unlimited items, cloud sync, advanced stats, custom images
- [KitchenPal Pantry App](https://kitchenpalapp.com/en/) — Premium: unlimited barcode scanner scans
- [My Pantry Tracker](https://mypantrytracker.com/) — Premium: cloud storage, iOS/Android/web sync, 6-month or yearly subscription

---
*Feature research for: Kindred Smart Pantry Milestone*
*Researched: 2026-03-11*
*Confidence: MEDIUM — Based on WebSearch-verified competitor analysis, UX case studies, and technical feasibility research. Confidence is MEDIUM (not HIGH) because CoreML food classification accuracy claims need Context7 or official Apple documentation verification, and receipt OCR accuracy standards come from vendor marketing materials rather than independent research.*
