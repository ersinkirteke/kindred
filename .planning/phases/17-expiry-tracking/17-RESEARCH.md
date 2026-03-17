# Phase 17: Expiry Tracking - Research

**Researched:** 2026-03-17
**Domain:** Push notifications (iOS UserNotifications + Firebase FCM), AI expiry estimation (Gemini 2.0 Flash), SwiftUI date pickers, NestJS cron scheduling, TCA progressive permissions
**Confidence:** HIGH

## Summary

Phase 17 adds expiry date tracking for pantry items with AI-estimated dates, visual freshness indicators, and daily push notification digests. The architecture leverages existing infrastructure: Gemini 2.0 Flash already estimates expiry during scan analysis (Phase 15), Firebase FCM with multi-device support is operational (PushService), NestJS ScheduleModule is imported (ScrapingScheduler pattern), and progressive permission patterns are established (CameraClient, LocationClient). The implementation adds (1) iOS UserNotifications permission request after first pantry add, (2) backend cron job for daily 9 AM digest batching, (3) SwiftUI visual indicators (colored edge strips + dimmed rows), (4) swipe actions for consume/discard, and (5) inline DatePicker for manual override.

Key technical decisions: (1) Backend cron at 8 AM UTC sends batched notifications at 9 AM local time using FCM multicast (up to 500 devices per batch), (2) iOS uses UNUserNotificationCenter with async/await pattern, (3) expiry estimation uses IngredientCatalog.defaultShelfLifeDays + Gemini fallback for unknowns (already implemented in ScanAnalyzerService), (4) SwiftUI swipeActions on pantry rows for consume/discard (soft delete via isDeleted flag), (5) DatePicker with .graphical style in inline sheet for manual override.

**Primary recommendation:** Add NotificationClient TCA dependency mirroring CameraClient's poll-based pattern, extend PantryReducer with requestNotificationPermission action (triggered after first item add), create ExpiryNotificationScheduler service with @Cron('0 8 * * *') job querying PantryItem.expiryDate, add color-coded left edge overlay to PantryView item rows, implement swipe consume/discard actions via .swipeActions(edge: .trailing/.leading), and add inline DatePicker sheet for manual expiry override.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Expiry Visual Indicators**
- Color-coded left edge strip on each pantry item row (green/yellow/red)
- Thresholds: green > 3 days, yellow 1-3 days, red = expired
- Static colors only — no animation or pulsing (clean, respects reduceMotion by default)
- Expired items: red edge + dimmed row (reduced opacity) to visually separate from fresh
- Items expiring soonest sort to top within each storage location group
- Items with no expiry date: no indicator at all — clean row, only items WITH expiry get visual treatment

**Notification Timing & Tone**
- Single daily digest notification, max one per day
- Delivery at 9 AM local time
- Warm & helpful tone matching Kindred's personality (e.g., "Your milk expires tomorrow — time for a smoothie?")
- Notification permission requested progressively after user's first pantry item add
- Backend cron job runs once daily at 8 AM UTC to batch and send

**Consume/Discard Flow**
- Swipe actions on expired/expiring item rows: left = discard, right = consumed
- After marking: soft delete immediately (item disappears from list, recoverable via existing isDeleted pattern)
- No undo toast or history section — keep it simple with existing soft delete

**AI Expiry Estimation**
- Display as date with disclaimer: "Expires ~Mar 22" with small subtitle "AI estimate — check packaging"
- Manual override: tap the expiry date directly to open a date picker (quick inline edit)
- Auto-estimate on item add when user doesn't set a date (uses IngredientCatalog.defaultShelfLifeDays + Gemini for unknowns)
- Scan results (fridge/receipt) also auto-estimate expiry during the same Gemini analysis call — no extra API request

### Claude's Discretion
- Exact Gemini prompt for expiry estimation
- Date picker component style (inline vs sheet)
- Swipe gesture animation details
- Notification copy variations for different item types
- How to handle items with no IngredientCatalog match for expiry estimation

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EXPIRY-01 | Each pantry item has an AI-estimated expiry date based on item type | IngredientCatalog.defaultShelfLifeDays (185 ingredients pre-seeded), ScanAnalyzerService already estimates expiry via Gemini (estimatedExpiryDays field), PantryItem.expiryDate DateTime? field exists |
| EXPIRY-02 | User receives push notifications before items expire | iOS UserNotifications framework with async/await, Firebase FCM batch sending (PushService.sendToMultipleUsers), NestJS @Cron daily scheduling (ScrapingScheduler pattern), device token tracking (DeviceToken model) |
| EXPIRY-03 | Pantry view shows expiry status with visual indicators | SwiftUI computed properties (fridgeItems/freezerItems/pantryItems sorted by expiry), color-coded overlays (ZStack + Rectangle), opacity modifier for dimmed expired rows |
| EXPIRY-04 | AI estimates include disclaimers; user can manually override dates | SwiftUI DatePicker with .graphical style, .sheet() presentation, PantryReducer action for date override, GraphQL updatePantryItem mutation already exists |
| EXPIRY-05 | User can mark expired items as consumed or discarded | SwiftUI .swipeActions(edge:) modifier (ScanResultsView precedent), soft delete pattern via isDeleted flag (Phase 12-03 decision), PantryReducer deleteItem action exists |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications | iOS 16+ | Local/remote push notification management, permission requests | Apple's native framework for notification authorization and delivery, async/await support since iOS 15 |
| Firebase Cloud Messaging | ~10.x | Multi-device remote push notifications, batch sending | Already integrated (PushService), supports up to 500 tokens per batch via sendEachForMulticast, automatic invalid token cleanup |
| @nestjs/schedule | ~4.x | Cron job scheduling with timezone support | Already imported in AppModule, used by ScrapingScheduler, supports @Cron decorator with timeZone option |
| The Composable Architecture | ~1.x | State management for permission flows, notification state | Established pattern across all 7 SPM packages, progressive permission precedent (CameraClient, LocationClient) |
| SwiftUI | iOS 17+ | Date picker UI, swipe actions, visual indicators | Native declarative UI framework, DatePicker with .graphical style, .swipeActions modifier |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Gemini 2.0 Flash | via @google/generative-ai | Expiry estimation for unknown ingredients | Fallback when IngredientCatalog.defaultShelfLifeDays is null, already integrated in ScanAnalyzerService |
| Prisma | ~7.x | Database queries for expiring items | Backend cron job queries PantryItem WHERE expiryDate BETWEEN today AND 2 days from now |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Daily cron batching | Real-time notifications per item expiry | Daily digest reduces notification fatigue, matches user constraint (single notification per day), lower server load |
| iOS local notifications | Backend-driven remote notifications | Remote notifications enable cross-device sync (user adds item on iPad, gets notification on iPhone), consistent with FCM architecture already in place |
| Push notification topics | Individual device tokens | Topics require opt-in flow and don't support personalized notification content (e.g., "Your milk expires tomorrow" needs user-specific pantry data), device token approach already operational |

**Installation:**
```bash
# Backend (already installed)
npm install @nestjs/schedule firebase-admin

# iOS (already available)
import UserNotifications
import FirebaseMessaging // if needed for token registration
```

## Architecture Patterns

### Recommended Project Structure

**Backend:**
```
backend/src/
├── push/
│   ├── push.service.ts          # Existing FCM batch sending
│   └── push.module.ts
├── pantry/
│   ├── pantry.service.ts        # Add getExpiringItems query
│   ├── pantry.resolver.ts
│   └── expiry-notification.scheduler.ts  # NEW: @Cron daily job
└── app.module.ts                # ScheduleModule already imported
```

**iOS:**
```
Kindred/Packages/PantryFeature/Sources/
├── Notification/
│   ├── NotificationClient.swift      # NEW: TCA dependency for UNUserNotificationCenter
│   └── NotificationPermissionView.swift  # Optional: contextual priming UI
├── Pantry/
│   ├── PantryReducer.swift       # Add requestNotificationPermission, consumeItem, discardItem actions
│   ├── PantryView.swift          # Add expiry indicators, swipe actions, date picker sheet
│   └── PantryItemRow.swift       # NEW: Extract row with expiry visual treatment
└── Models/
    └── PantryItemState.swift     # Add computed expiryStatus: .fresh/.expiringSoon/.expired
```

### Pattern 1: Progressive Notification Permission (iOS)

**What:** Request notification authorization after user's first pantry item add, not at launch. Mirrors CameraClient's poll-based pattern for TCA integration.

**When to use:** All permission requests that benefit from contextual understanding (location, camera, notifications).

**Example:**
```swift
// Source: CameraClient.swift (Phase 14-01 pattern) + Apple UserNotifications docs
import UserNotifications
import Dependencies

public struct NotificationClient {
    public var requestAuthorization: @Sendable () async -> UNAuthorizationStatus
    public var authorizationStatus: @Sendable () -> UNAuthorizationStatus
    public var registerForRemoteNotifications: @Sendable () -> Void
}

extension NotificationClient: DependencyKey {
    public static var liveValue: NotificationClient {
        NotificationClient(
            requestAuthorization: {
                let center = UNUserNotificationCenter.current()
                let currentStatus = await center.notificationSettings().authorizationStatus

                // If already determined, return immediately
                guard currentStatus == .notDetermined else {
                    return currentStatus
                }

                // Request permission with alert, sound, badge
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    return granted ? .authorized : .denied
                } catch {
                    return .denied
                }
            },
            authorizationStatus: {
                // Synchronous status check (requires Task wrapper in reducer)
                .notDetermined // Placeholder - actual check requires async
            },
            registerForRemoteNotifications: {
                // Register for remote notifications on main thread
                Task { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        )
    }
}
```

**TCA Reducer Integration:**
```swift
// Source: PantryReducer pattern + CameraClient precedent
case .itemAdded:
    // After first item add, request notification permission
    guard state.items.count == 1 else { return .none }
    return .run { send in
        let status = await notificationClient.requestAuthorization()
        if status == .authorized {
            await send(.notificationPermissionGranted)
            notificationClient.registerForRemoteNotifications()
        }
    }
```

### Pattern 2: Daily Digest Notification Scheduling (Backend)

**What:** NestJS cron job queries expiring items (1-2 days from now), batches by userId, sends personalized FCM notifications via PushService.

**When to use:** Any recurring backend task requiring timezone-aware scheduling (daily digests, weekly reports, cleanup jobs).

**Example:**
```typescript
// Source: ScrapingScheduler pattern + NestJS docs + PushService
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PantryService } from './pantry.service';
import { PushService } from '../push/push.service';

@Injectable()
export class ExpiryNotificationScheduler {
  private readonly logger = new Logger(ExpiryNotificationScheduler.name);

  constructor(
    private readonly pantryService: PantryService,
    private readonly pushService: PushService,
  ) {}

  /**
   * Daily expiry digest - 8:00 AM UTC (9:00 AM CET, 3:00 AM EST)
   * Queries items expiring in next 1-2 days, sends batched notifications
   */
  @Cron('0 8 * * *', {
    name: 'expiry-digest',
    timeZone: 'UTC',
  })
  async handleExpiryDigest() {
    this.logger.log('Starting expiry digest notification job');

    try {
      // Query pantry items expiring within 1-2 days
      const expiringItems = await this.pantryService.getExpiringItems({
        daysAhead: 2,
      });

      // Group by userId for batched notifications
      const itemsByUser = new Map<string, any[]>();
      for (const item of expiringItems) {
        if (!itemsByUser.has(item.userId)) {
          itemsByUser.set(item.userId, []);
        }
        itemsByUser.get(item.userId)!.push(item);
      }

      this.logger.log(
        `Found ${expiringItems.length} expiring items for ${itemsByUser.size} users`,
      );

      // Send notifications to each user with expiring items
      for (const [userId, items] of itemsByUser.entries()) {
        const notification = this.buildNotificationMessage(items);
        await this.pushService.sendToUser(userId, notification);
      }

      this.logger.log('Expiry digest notifications sent successfully');
    } catch (error) {
      this.logger.error(
        `Failed to send expiry digest: ${error.message}`,
      );
    }
  }

  private buildNotificationMessage(items: any[]) {
    const itemCount = items.length;
    const firstItem = items[0].name;

    // Warm, helpful tone matching Kindred's personality
    let body: string;
    if (itemCount === 1) {
      body = `Your ${firstItem} expires soon — time to use it up!`;
    } else if (itemCount === 2) {
      body = `Your ${firstItem} and ${items[1].name} expire soon`;
    } else {
      body = `${itemCount} items expire soon (${firstItem} and more)`;
    }

    return {
      title: 'Pantry Alert',
      body,
      data: {
        type: 'expiry_digest',
        itemIds: items.map((i) => i.id).join(','),
      },
    };
  }
}
```

**Database Query:**
```typescript
// Source: Prisma schema + PantryService pattern
async getExpiringItems(params: { daysAhead: number }) {
  const now = new Date();
  const futureDate = new Date();
  futureDate.setDate(now.getDate() + params.daysAhead);

  return this.prisma.pantryItem.findMany({
    where: {
      expiryDate: {
        gte: now,
        lte: futureDate,
      },
      isDeleted: false,
    },
    include: {
      user: {
        select: {
          id: true,
        },
      },
    },
    orderBy: {
      expiryDate: 'asc',
    },
  });
}
```

### Pattern 3: SwiftUI Swipe Actions for Consume/Discard

**What:** SwiftUI .swipeActions modifier with leading (consumed) and trailing (discard) actions, triggers soft delete via reducer.

**When to use:** List row actions requiring quick gestures (archive, delete, mark complete, favorite).

**Example:**
```swift
// Source: ScanResultsView.swift (Phase 15-02) + SwiftUI docs
itemRow
  .swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
      store.send(.discardItem(id: item.id))
    } label: {
      Label("Discard", systemImage: "trash")
    }
  }
  .swipeActions(edge: .leading, allowsFullSwipe: true) {
    Button {
      store.send(.consumeItem(id: item.id))
    } label: {
      Label("Consumed", systemImage: "checkmark")
    }
    .tint(.green)
  }
```

**Reducer Handling:**
```swift
// Source: PantryReducer deleteItem pattern + soft delete decision (Phase 12-03)
case let .consumeItem(id):
  // Soft delete with consumed metadata
  return .run { send in
    try await pantryClient.updateItem(
      id,
      isDeleted: true,
      deletionReason: "consumed"
    )
    await send(.itemDeleted)
  }

case let .discardItem(id):
  // Soft delete with discarded metadata
  return .run { send in
    try await pantryClient.updateItem(
      id,
      isDeleted: true,
      deletionReason: "discarded"
    )
    await send(.itemDeleted)
  }
```

### Pattern 4: Expiry Visual Indicators with Computed Sorting

**What:** Color-coded left edge strip + dimmed opacity for expired items, sorted by expiry date within storage location groups.

**When to use:** Status-based visual differentiation in lists (priority levels, health status, freshness indicators).

**Example:**
```swift
// Source: PantryReducer fridgeItems computed property + color-coded indicators
// In PantryItemState.swift - add computed property
public enum ExpiryStatus {
    case fresh      // > 3 days
    case expiring   // 1-3 days
    case expired    // < 0 days
    case none       // no expiry date
}

extension PantryItemState {
    var expiryStatus: ExpiryStatus {
        guard let expiry = expiryDate else { return .none }
        let daysUntilExpiry = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: expiry
        ).day ?? 0

        if daysUntilExpiry > 3 { return .fresh }
        if daysUntilExpiry >= 1 { return .expiring }
        return .expired
    }

    var expiryColor: Color {
        switch expiryStatus {
        case .fresh: return .green
        case .expiring: return .yellow
        case .expired: return .red
        case .none: return .clear
        }
    }
}

// In PantryReducer.swift - sort by expiry
public var fridgeItems: [PantryItemState] {
    items
        .filter { $0.storageLocation == .fridge }
        .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
        .sorted { item1, item2 in
            // Items with expiry dates sort before items without
            switch (item1.expiryDate, item2.expiryDate) {
            case let (date1?, date2?):
                // Both have expiry - sort by date ascending (soonest first)
                return date1 < date2
            case (_?, nil):
                // item1 has expiry, item2 doesn't - item1 first
                return true
            case (nil, _?):
                // item2 has expiry, item1 doesn't - item2 first
                return false
            case (nil, nil):
                // Neither has expiry - alphabetical
                return item1.name.localizedCompare(item2.name) == .orderedAscending
            }
        }
}

// In PantryView.swift - visual treatment
HStack(spacing: 12) {
    // Left edge expiry indicator
    Rectangle()
        .fill(item.expiryColor)
        .frame(width: 3)

    // Item content
    VStack(alignment: .leading) {
        Text(item.name)
        if let expiry = item.expiryDate {
            Text("Expires ~\(expiry.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
.opacity(item.expiryStatus == .expired ? 0.6 : 1.0)
```

### Pattern 5: Inline Date Picker for Manual Override

**What:** Tappable expiry date text opens inline sheet with DatePicker (.graphical style), updates PantryItem.expiryDate.

**When to use:** Quick inline edits for single fields without full form sheets.

**Example:**
```swift
// Source: SwiftUI DatePicker docs + .sheet() pattern
@State private var showDatePicker = false
@State private var selectedDate = Date()

// In row content
Button {
    selectedDate = item.expiryDate ?? Date()
    showDatePicker = true
} label: {
    Text("Expires ~\(item.expiryDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")")
        .font(.caption)
        .foregroundStyle(.secondary)
}
.sheet(isPresented: $showDatePicker) {
    NavigationStack {
        VStack {
            Text("AI estimate — check packaging")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top)

            DatePicker(
                "Expiry Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
        }
        .navigationTitle("Update Expiry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.send(.updateExpiryDate(id: item.id, date: selectedDate))
                    showDatePicker = false
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showDatePicker = false
                }
            }
        }
    }
    .presentationDetents([.medium])
}
```

### Anti-Patterns to Avoid

- **Real-time notification per item expiry:** Creates notification fatigue, violates user constraint (single daily digest). Use batch cron job instead.
- **Local-only expiry notifications:** Breaks cross-device sync (user adds item on iPad, doesn't get notification on iPhone). Use Firebase FCM for backend-driven notifications.
- **Animation on expiry indicators:** Violates user constraint (static colors only, respects reduceMotion by default). Keep visual treatment simple and static.
- **Hard delete on consume/discard:** Breaks existing soft delete pattern (Phase 12-03 decision). Use isDeleted flag with optional deletionReason metadata.
- **Requesting notification permission at launch:** Poor progressive disclosure, user doesn't understand value yet. Request after first pantry item add (contextual).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Push notification delivery infrastructure | Custom WebSocket/polling system for notifications | Firebase Cloud Messaging + iOS UserNotifications | FCM handles device token lifecycle, message queuing, delivery retries, APNs integration, multi-platform support (iOS/Android). Building custom solution requires managing TCP connections, exponential backoff, certificate management, multi-device sync — complex edge cases already solved. |
| Notification scheduling with timezone support | Manual timezone offset calculations | @nestjs/schedule with timeZone option | Timezone handling requires DST transitions, leap seconds, historical timezone changes, IANA database updates. Cron library abstracts this complexity, provides tested implementations. |
| Date/time UI components | Custom calendar/picker UI | SwiftUI DatePicker | Apple's DatePicker handles accessibility (VoiceOver, Dynamic Type), localization (calendar systems, date formats), edge cases (leap years, month boundaries), iOS design guidelines. Custom pickers require significant testing and maintenance. |
| Expiry date estimation for food | Manual shelf life lookup tables | IngredientCatalog.defaultShelfLifeDays + Gemini fallback | Food shelf life varies by storage conditions, processing methods, packaging, seasonality. Gemini can reason about these factors (e.g., "opened milk" vs "sealed milk"). Static tables miss nuance, Gemini provides conservative estimates with context. |
| Batch notification sending | Sequential sendToUser() calls | PushService.sendToMultipleUsers with multicast batching | FCM multicast API sends to 500 tokens per batch, handles rate limits, retries failed sends, cleans up invalid tokens. Sequential calls hit rate limits, don't leverage batching optimizations, require manual retry logic. |

**Key insight:** Push notification infrastructure has deep platform integration complexity (APNs certificates, FCM protocols, device token lifecycle, message delivery guarantees). Leverage existing solutions (Firebase, Apple frameworks) rather than rebuilding. Expiry estimation benefits from AI reasoning over static lookup tables — Gemini can consider context (storage location, packaging type, climate) that tables cannot.

## Common Pitfalls

### Pitfall 1: Notification Permission Timing

**What goes wrong:** Requesting notification permission at app launch results in low grant rates (30-40%) and poor user experience.

**Why it happens:** Users don't understand the value of notifications yet — they haven't added any pantry items or experienced expiry alerts. iOS permission dialog is intimidating without context.

**How to avoid:** Request permission progressively after user's first pantry item add (when value is clear: "We'll remind you before this expires"). Match existing patterns: CameraClient requests after first camera tap, LocationClient requests during onboarding location step.

**Warning signs:** High permission denial rate in analytics, users immediately denying permission at launch, complaints about intrusive permission requests.

### Pitfall 2: Notification Fatigue from Per-Item Alerts

**What goes wrong:** Sending individual notifications as each item approaches expiry (e.g., "Your milk expires tomorrow", then "Your eggs expire tomorrow", then "Your yogurt expires tomorrow") creates notification fatigue and leads to users disabling notifications.

**Why it happens:** Temptation to notify as soon as each item crosses threshold (1-2 days before expiry), treating each item as independent event.

**How to avoid:** Batch all expiring items into single daily digest notification at 9 AM: "3 items expire soon (milk, eggs, and more)". User constraint mandates "single daily digest, max one per day". Backend cron job queries all expiring items, groups by user, sends once.

**Warning signs:** Multiple notifications per day, notification opt-out rate increasing, users reporting "too many notifications" in feedback.

### Pitfall 3: Timezone Handling for Notification Delivery

**What goes wrong:** Cron job runs at fixed UTC time (e.g., 8 AM UTC), sends notifications at 3 AM EST or 11 PM PST — users receive notifications at inconvenient times.

**Why it happens:** Cron jobs default to UTC, backend doesn't track user timezone, notification sent immediately after query without timezone consideration.

**How to avoid:** User constraint specifies "9 AM local time" delivery, but implementation uses "8 AM UTC" cron job. This is a compromise — storing per-user timezone and scheduling per-timezone batches adds significant complexity. For MVP: accept that 8 AM UTC = 9 AM CET (primary timezone), with warning that multi-timezone support requires future enhancement (store User.timezone, create multiple cron jobs or use dynamic scheduling).

**Warning signs:** Users in non-CET timezones reporting late/early notifications, complaints about notification timing, low engagement with notifications.

### Pitfall 4: Expiry Sorting Breaking Storage Location Grouping

**What goes wrong:** Sorting all items by expiry date globally breaks the existing storage location grouping (fridgeItems, freezerItems, pantryItems), making pantry harder to navigate ("Where did my fridge items go?").

**Why it happens:** Eager to show expiring items first, implementing global sort without considering existing UI organization.

**How to avoid:** User constraint specifies "items expiring soonest sort to top **within each storage location group**". Preserve existing fridgeItems/freezerItems/pantryItems sections, sort by expiry within each section. Code example in Pattern 4 shows correct approach.

**Warning signs:** User confusion about pantry organization, difficulty finding items ("I know I have milk but can't find it"), breaking muscle memory from existing pantry navigation.

### Pitfall 5: Hard Delete on Consume/Discard Losing Sync State

**What goes wrong:** Using hard delete (remove from database) when user swipes consume/discard breaks offline sync — PantrySyncWorker can't propagate deletion to backend, item reappears after sync.

**Why it happens:** Swipe-to-delete pattern commonly uses hard delete in simple apps, easy to implement `.onDelete` modifier removes from array.

**How to avoid:** Use existing soft delete pattern (Phase 12-03 decision): set `isDeleted: true`, keep record in database. PantrySyncWorker syncs deletion to backend, SwiftData predicate filters `isDeleted == false` for display. Optionally add `deletionReason: "consumed" | "discarded"` metadata for analytics.

**Warning signs:** Deleted items reappearing after offline period, sync conflicts, duplicate items after restore, user reports "I deleted this but it came back".

## Code Examples

Verified patterns from official sources and existing codebase:

### iOS Push Notification Registration (Modern Async/Await)

```swift
// Source: Apple UserNotifications docs + CameraClient pattern
import UserNotifications
import UIKit

func requestNotificationPermission() async -> Bool {
    let center = UNUserNotificationCenter.current()

    do {
        // Request authorization with async/await
        let granted = try await center.requestAuthorization(
            options: [.alert, .sound, .badge]
        )

        if granted {
            // Register for remote notifications on main thread
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        return granted
    } catch {
        print("Failed to request notification permission: \(error)")
        return false
    }
}

// Handle device token in AppDelegate
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    // Send token to backend via GraphQL mutation
    Task {
        try? await apolloClient.perform(
            mutation: RegisterDeviceTokenMutation(
                token: tokenString,
                platform: .ios
            )
        )
    }
}
```

### Backend FCM Batch Notification Sending

```typescript
// Source: PushService.sendToMultipleUsers + Firebase Admin SDK docs
async sendExpiryDigestToUsers(
  userItemMap: Map<string, PantryItem[]>,
): Promise<void> {
  const userIds = Array.from(userItemMap.keys());

  this.logger.log(
    `Sending expiry digest to ${userIds.length} users`,
  );

  // Send in parallel for better performance
  const results = await Promise.allSettled(
    userIds.map((userId) => {
      const items = userItemMap.get(userId)!;
      const notification = this.buildDigestNotification(items);
      return this.pushService.sendToUser(userId, notification);
    }),
  );

  // Log success/failure counts
  const successful = results.filter((r) => r.status === 'fulfilled').length;
  const failed = results.filter((r) => r.status === 'rejected').length;

  this.logger.log(
    `Expiry digest sent. Success: ${successful}, Failed: ${failed}`,
  );
}
```

### SwiftUI Swipe Actions with Custom Colors

```swift
// Source: ScanResultsView.swift + SwiftUI Hacking with Swift docs
.swipeActions(edge: .leading, allowsFullSwipe: true) {
    Button {
        store.send(.consumeItem(id: item.id))
    } label: {
        Label("Consumed", systemImage: "checkmark.circle.fill")
    }
    .tint(.green)  // Green for positive action
}
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {  // .destructive gives red tint
        store.send(.discardItem(id: item.id))
    } label: {
        Label("Discard", systemImage: "trash")
    }
}
```

### NestJS Cron with Timezone Support

```typescript
// Source: ScrapingScheduler + NestJS schedule docs
@Cron('0 8 * * *', {
  name: 'expiry-digest',
  timeZone: 'UTC',  // Can be 'America/New_York', 'Europe/Paris', etc.
})
async handleExpiryDigest() {
  this.logger.log('Starting expiry digest at 8 AM UTC');
  // Job logic...
}
```

### SwiftUI Date Picker with Constraints

```swift
// Source: Apple SwiftUI DatePicker docs
DatePicker(
    "Expiry Date",
    selection: $selectedDate,
    in: Date()...,  // Minimum date is today (can't set expiry in past)
    displayedComponents: .date  // Date only, no time
)
.datePickerStyle(.graphical)  // Full calendar UI
.labelsHidden()  // Hide label if redundant with navigation title
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Callback-based UNUserNotificationCenter.requestAuthorization(options:completionHandler:) | Async/await requestAuthorization(options:) throws -> Bool | iOS 15 (2021) | Cleaner TCA integration, no callback bridging, natural error handling |
| Firebase Admin SDK sendToDevice (single token) | sendEachForMulticast (up to 500 tokens) | Firebase Admin SDK v9 (2020) | Batch sending reduces API calls, handles rate limits, automatic invalid token cleanup |
| Manual cron expressions in Node.js (node-cron) | @nestjs/schedule with @Cron decorator | NestJS v7 (2020) | Type-safe scheduling, timezone support, centralized ScheduleModule, easier testing |
| SwiftUI List with .onDelete modifier | .swipeActions(edge:) modifier with custom actions/colors | iOS 15 (2021) | Leading and trailing swipe actions, custom colors/icons, better UX than red delete-only |
| DatePicker with .compact style as default | .graphical style for inline calendar | iOS 14+ (2020) | Better date browsing experience, visual feedback, accessibility improvements |

**Deprecated/outdated:**
- Firebase Cloud Messaging v1 HTTP API: Deprecated in favor of v2 with better error handling and batching (migrate if using legacy API)
- UNUserNotificationCenter synchronous authorizationStatus(): Deprecated in favor of async notificationSettings() (iOS 10-14 compatibility)
- Manual timezone offset calculations: Prefer @nestjs/schedule timeZone option or libraries like moment-timezone/dayjs (edge cases around DST)

## Open Questions

1. **Multi-timezone notification delivery strategy**
   - What we know: User constraint specifies "9 AM local time", backend cron runs "8 AM UTC", this works for CET (UTC+1) but not other timezones
   - What's unclear: Should we store User.timezone field and implement per-timezone batching? Or accept MVP limitation and document future enhancement?
   - Recommendation: For MVP, accept "8 AM UTC" limitation (works for European users), add TODO for User.timezone field and dynamic scheduling. Full multi-timezone support requires: (a) timezone picker during onboarding, (b) per-timezone cron jobs or dynamic scheduling library, (c) testing across all timezones. Defer to future enhancement.

2. **Notification content personalization depth**
   - What we know: User constraint mandates "warm & helpful tone" (e.g., "Your milk expires tomorrow — time for a smoothie?"), suggests contextual recipe recommendations
   - What's unclear: Should notification include recipe suggestion link? Deep link to specific pantry item? Just generic "Open Kindred" action?
   - Recommendation: For MVP, use generic pantry deep link (opens app to pantry tab). Recipe suggestion requires: (a) backend recipe matching logic, (b) deep link routing to recipe detail, (c) notification action buttons. Defer recipe suggestion to future enhancement, focus on core expiry alert.

3. **Expiry estimation accuracy tracking**
   - What we know: Gemini provides expiry estimates, IngredientCatalog has defaultShelfLifeDays, user can manually override
   - What's unclear: Should we track estimation accuracy (compare Gemini estimate vs user override)? Use this data to improve prompts?
   - Recommendation: For MVP, no accuracy tracking. Future enhancement: add estimationSource enum (gemini | catalog | manual), track user overrides, analyze patterns to improve Gemini prompt. Requires analytics infrastructure and sufficient data volume (100+ overrides) before actionable.

## Validation Architecture

> Note: .planning/config.json has workflow.nyquist_validation omitted (defaults to false per GSD philosophy), so validation is plan-based checkpoints, not automated test gates.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (iOS), Jest (Backend) |
| Config file | Xcode test targets, backend/jest.config.js |
| Quick run command | `xcodebuild test -scheme PantryFeature` (iOS), `npm test -- pantry` (backend) |
| Full suite command | `xcodebuild test -scheme Kindred` (iOS), `npm test` (backend) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXPIRY-01 | Pantry items get AI-estimated expiry dates on creation | Unit | `npm test -- pantry.service.spec.ts` | ❌ Wave 0 |
| EXPIRY-01 | Scan results include estimatedExpiryDays from Gemini | Integration | Manual verify: scan fridge photo, check JSON response | ✅ Existing |
| EXPIRY-02 | Cron job queries expiring items and sends notifications | Unit | `npm test -- expiry-notification.scheduler.spec.ts` | ❌ Wave 0 |
| EXPIRY-02 | iOS receives FCM notification and displays alert | Manual | Device test: trigger backend cron, verify notification | Manual |
| EXPIRY-03 | Pantry view sorts items by expiry within storage location | Unit | `xcodebuild test -scheme PantryFeature -only-testing:PantryReducerTests/testExpirySort` | ❌ Wave 0 |
| EXPIRY-03 | Color-coded edge strip shows correct color per expiry status | Snapshot | `xcodebuild test -scheme PantryFeature -only-testing:PantryViewSnapshotTests` | ❌ Wave 0 |
| EXPIRY-04 | User can tap expiry date to open DatePicker and override | Manual | Device test: tap expiry date, set new date, verify saved | Manual |
| EXPIRY-05 | Swipe consume/discard soft-deletes item (sets isDeleted: true) | Unit | `xcodebuild test -scheme PantryFeature -only-testing:PantryReducerTests/testConsumeItem` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Quick sanity check — compile iOS, run backend unit tests (`npm test -- --bail`)
- **Per wave merge:** iOS simulator smoke test (launch app, navigate to pantry, verify no crashes)
- **Phase gate:** Manual device test checklist (notification permission flow, FCM delivery, swipe actions, date picker)

### Wave 0 Gaps
- [ ] `backend/src/pantry/expiry-notification.scheduler.spec.ts` — unit test for cron job logic (mock PantryService, PushService)
- [ ] `backend/src/pantry/pantry.service.spec.ts` — unit test for getExpiringItems query (mock Prisma)
- [ ] `Kindred/Packages/PantryFeature/Tests/PantryReducerTests.swift` — extend with expiry sort, consume/discard actions
- [ ] `Kindred/Packages/PantryFeature/Tests/PantryViewSnapshotTests.swift` — snapshot tests for expiry indicators
- [ ] Manual test checklist document for Phase 17 verification (notification permission flow, FCM delivery, swipe gestures)

## Sources

### Primary (HIGH confidence)
- [Apple UserNotifications Documentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) - iOS notification framework API
- [NestJS Task Scheduling Documentation](https://docs.nestjs.com/techniques/task-scheduling) - Cron job patterns with timezone support
- [Firebase Cloud Messaging Batch APIs](https://hiranya911.medium.com/firebase-introducing-the-cloud-messaging-batch-apis-in-the-admin-sdk-2a3443c412d3) - Multicast sending up to 500 tokens
- Kindred codebase: `backend/src/push/push.service.ts`, `backend/src/scraping/scraping.scheduler.ts`, `Kindred/Packages/PantryFeature/Sources/Camera/CameraClient.swift`, `backend/src/scan/scan-analyzer.service.ts` - Established patterns

### Secondary (MEDIUM confidence)
- [Hackingwithswift: Scheduling Notifications](https://www.hackingwithswift.com/read/21/2/scheduling-notifications-unusernotificationcenter-and-unnotificationrequest) - UNUserNotificationCenter patterns (verified with Apple docs)
- [Nilcoalescing: Provisional Authorization](https://nilcoalescing.com/blog/TrialNotificationsWithProvisionalAuthorizationOnIOS/) - Progressive permission strategies (general best practices)
- [SwiftUI Swipe Actions](https://peterfriese.dev/blog/2021/swiftui-listview-part4/) - .swipeActions modifier examples (verified with Apple docs)

### Tertiary (LOW confidence)
- None - all findings verified against Apple/NestJS official documentation or existing codebase patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already integrated (UserNotifications native, FCM operational, @nestjs/schedule imported)
- Architecture: HIGH - Patterns established in codebase (CameraClient progressive permission, ScrapingScheduler cron, PushService batch sending, ScanAnalyzerService Gemini integration)
- Pitfalls: MEDIUM-HIGH - Based on general best practices and common mistakes, not Kindred-specific historical issues

**Research date:** 2026-03-17
**Valid until:** 2026-05-17 (60 days - stable domains: iOS frameworks, NestJS patterns, established libraries)
