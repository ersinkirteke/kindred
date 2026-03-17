import Apollo
import AVFoundation
import ComposableArchitecture
import Foundation
import MonetizationFeature
import NetworkClient
import UIKit
import UserNotifications

@Reducer
public struct PantryReducer {
    @ObservableState
    public struct State: Equatable {
        public var items: IdentifiedArrayOf<PantryItemState> = []
        public var isLoading: Bool = false
        public var isEmpty: Bool { items.isEmpty && !isLoading }
        public var userId: String? = nil
        public var expiringCount: Int = 0
        @Presents public var alert: AlertState<Action.Alert>?
        @Presents public var addEditForm: AddEditItemReducer.State?
        public var searchText: String = ""
        public var itemToDelete: PantryItemState? = nil

        // Sync state
        public var isSyncing: Bool = false
        public var syncRetryCount: Int = 0
        public var showSyncFailureBanner: Bool = false
        public var isOffline: Bool = false

        // Camera and paywall state
        public var isFABExpanded: Bool = false
        public var showPaywall: Bool = false
        public var showSettingsRedirect: Bool = false
        public var showCamera: Bool = false
        public var cameraPermissionStatus: AVAuthorizationStatus? = nil
        @Presents public var scanUpload: ScanUploadReducer.State?
        public var showUploadCompleteBanner: Bool = false

        // Scan results and receipt scanner state
        @Presents public var scanResults: ScanResultsReducer.State?
        @Presents public var receiptScanner: ReceiptScannerReducer.State?
        public var showRecipeSuggestions: Bool = false
        public var scannedItemNames: [String] = []
        public var showUpgradeBanner: Bool = false
        public var isAnalyzingReceipt: Bool = false

        // Expiry and notification state
        public var showDatePicker: Bool = false
        public var datePickerItemId: UUID? = nil
        public var datePickerDate: Date = Date()
        public var notificationPermissionRequested: Bool = false

        // Group items by storage location for list display with search filter and expiry-based sort
        public var fridgeItems: [PantryItemState] {
            items
                .filter { $0.storageLocation == .fridge }
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { item1, item2 in
                    switch (item1.expiryDate, item2.expiryDate) {
                    case let (date1?, date2?):
                        return date1 < date2  // soonest first
                    case (_?, nil):
                        return true  // items with expiry before items without
                    case (nil, _?):
                        return false
                    case (nil, nil):
                        return item1.name.localizedCompare(item2.name) == .orderedAscending
                    }
                }
        }
        public var freezerItems: [PantryItemState] {
            items
                .filter { $0.storageLocation == .freezer }
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { item1, item2 in
                    switch (item1.expiryDate, item2.expiryDate) {
                    case let (date1?, date2?):
                        return date1 < date2  // soonest first
                    case (_?, nil):
                        return true  // items with expiry before items without
                    case (nil, _?):
                        return false
                    case (nil, nil):
                        return item1.name.localizedCompare(item2.name) == .orderedAscending
                    }
                }
        }
        public var pantryItems: [PantryItemState] {
            items
                .filter { $0.storageLocation == .pantry }
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { item1, item2 in
                    switch (item1.expiryDate, item2.expiryDate) {
                    case let (date1?, date2?):
                        return date1 < date2  // soonest first
                    case (_?, nil):
                        return true  // items with expiry before items without
                    case (nil, _?):
                        return false
                    case (nil, nil):
                        return item1.name.localizedCompare(item2.name) == .orderedAscending
                    }
                }
        }

        public init() {}
    }

    public enum Action {
        case onAppear
        case itemsLoaded([PantryItem])
        case expiringCountLoaded(Int)
        case addItemTapped
        case editItemTapped(UUID)
        case deleteItem(UUID)
        case confirmDeleteItem(UUID)
        case itemDeleted
        case authStateUpdated(String?)
        case searchTextChanged(String)
        case refreshTriggered
        case alert(PresentationAction<Alert>)
        case addEditForm(PresentationAction<AddEditItemReducer.Action>)

        // Sync actions
        case syncPendingItems
        case syncCompleted(SyncResult)
        case syncFailed
        case dismissSyncBanner
        case connectivityChanged(Bool)
        case appEnteredForeground

        // Camera and paywall actions
        case fabToggled
        case scanItemsTapped
        case receiptScanTapped
        case paywallDismissed
        case paywallPurchaseCompleted
        case checkCameraPermission
        case cameraPermissionResult(AVAuthorizationStatus)
        case settingsRedirectDismissed
        case cameraDismissed
        case cameraPhotoReady(UIImage, ScanType)
        case scanUpload(PresentationAction<ScanUploadReducer.Action>)
        case dismissUploadCompleteBanner

        // Scan results and receipt scanner actions
        case scanResults(PresentationAction<ScanResultsReducer.Action>)
        case receiptScanner(PresentationAction<ReceiptScannerReducer.Action>)
        case receiptAnalysisCompleted([DetectedItem])
        case receiptAnalysisFailed(String)
        case dismissRecipeSuggestions
        case dismissUpgradeBanner

        // Expiry actions
        case consumeItem(UUID)
        case discardItem(UUID)
        case expiryDateTapped(UUID)
        case datePickerDismissed
        case datePickerSaved
        case setDatePickerDate(Date)

        // Notification permission
        case requestNotificationPermission
        case registerForRemoteNotifications
        case notificationPermissionResult(UNAuthorizationStatus)

        public enum Alert: Equatable {
            case confirmDelete
        }

        // Delegate actions for parent reducer
        case delegate(Delegate)
        public enum Delegate {
            case authGateRequested
        }
    }

    @Dependency(\.pantryClient) var pantryClient
    @Dependency(\.apolloClient) var apolloClient
    @Dependency(\.cameraClient) var cameraClient
    @Dependency(\.subscriptionClient) var subscriptionClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.notificationClient) var notificationClient

    private enum CancelID { case syncRetry }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let userId = state.userId else {
                    // Guest user - show empty state with sign-in prompt
                    return .none
                }
                state.isLoading = true
                return .run { [userId] send in
                    let items = await pantryClient.fetchAllItems(userId)
                    await send(.itemsLoaded(items))
                    let count = await pantryClient.expiringItemCount(userId)
                    await send(.expiringCountLoaded(count))

                    // Check connectivity and trigger sync
                    let isConnected = await pantryClient.isNetworkAvailable()
                    await send(.connectivityChanged(isConnected))
                    await send(.syncPendingItems)
                }

            case let .itemsLoaded(items):
                state.isLoading = false
                state.items = IdentifiedArray(
                    uniqueElements: items.map { PantryItemState(from: $0) }
                )
                return .none

            case let .expiringCountLoaded(count):
                state.expiringCount = count
                return .none

            case .addItemTapped:
                guard let userId = state.userId else {
                    return .send(.delegate(.authGateRequested))
                }
                state.addEditForm = AddEditItemReducer.State(
                    mode: .add,
                    userId: userId,
                    storageLocation: .pantry
                )
                return .none

            case let .editItemTapped(id):
                guard let userId = state.userId,
                      let item = state.items[id: id] else { return .none }
                state.addEditForm = AddEditItemReducer.State(
                    mode: .edit(id),
                    userId: userId,
                    name: item.name,
                    quantity: item.quantity,
                    unit: item.unit,
                    storageLocation: item.storageLocation,
                    foodCategory: item.foodCategory,
                    expiryDate: item.expiryDate,
                    notes: item.notes ?? ""
                )
                return .none

            case let .searchTextChanged(text):
                state.searchText = text
                return .none

            case .refreshTriggered:
                return .send(.onAppear)

            case .alert(.presented(.confirmDelete)):
                guard let itemId = state.itemToDelete?.id else { return .none }
                state.itemToDelete = nil
                return .send(.deleteItem(itemId))

            case .alert:
                return .none

            case .addEditForm(.presented(.delegate(.itemSaved))):
                state.addEditForm = nil
                var effects: [Effect<Action>] = [
                    .send(.onAppear),
                    .send(.syncPendingItems)
                ]

                // Request notification permission after first item add
                if !state.notificationPermissionRequested {
                    effects.append(.send(.requestNotificationPermission))
                }

                return .merge(effects)

            case .addEditForm(.presented(.delegate(.cancelled))):
                state.addEditForm = nil
                return .send(.onAppear)

            case let .addEditForm(.presented(.delegate(.itemDeleted(id)))):
                state.addEditForm = nil
                state.items.remove(id: id)
                return .merge(
                    .send(.onAppear),
                    .send(.syncPendingItems)
                )

            case .addEditForm:
                return .none

            case let .confirmDeleteItem(id):
                guard let item = state.items[id: id] else { return .none }
                state.itemToDelete = item
                state.alert = AlertState {
                    TextState(String(localized: "pantry.delete.title", defaultValue: "Delete \(item.name)?", bundle: .main))
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState(String(localized: "pantry.delete.confirm", defaultValue: "Delete", bundle: .main))
                    }
                    ButtonState(role: .cancel) {
                        TextState(String(localized: "pantry.delete.cancel", defaultValue: "Cancel", bundle: .main))
                    }
                }
                return .none

            case let .deleteItem(id):
                guard state.userId != nil else { return .none }
                state.items.remove(id: id)
                return .run { send in
                    try await pantryClient.deleteItem(id)
                    await send(.itemDeleted)
                    await send(.syncPendingItems)
                }

            case .itemDeleted:
                return .none

            case let .authStateUpdated(userId):
                state.userId = userId
                if userId != nil {
                    return .send(.onAppear)
                } else {
                    state.items = []
                    state.expiringCount = 0
                }
                return .none

            case .syncPendingItems:
                guard let userId = state.userId, !state.isSyncing, !state.isOffline else {
                    return .none
                }
                state.isSyncing = true
                return .run { [userId, pantryClient, apolloClient] send in
                    do {
                        let result = try await PantrySyncWorker.performSync(
                            userId: userId,
                            pantryClient: pantryClient,
                            apolloClient: apolloClient
                        )
                        await send(.syncCompleted(result))
                    } catch {
                        print("Sync failed: \(error)")
                        await send(.syncFailed)
                    }
                }

            case let .syncCompleted(result):
                state.isSyncing = false
                state.syncRetryCount = 0
                state.showSyncFailureBanner = false
                if result.pulled > 0 {
                    // Server had changes - re-fetch local items to reflect merged data
                    return .send(.onAppear)
                }
                return .none

            case .syncFailed:
                state.isSyncing = false
                state.syncRetryCount += 1
                if state.syncRetryCount >= 3 {
                    state.showSyncFailureBanner = true
                }
                // Schedule retry with exponential backoff (30s, 60s, 120s max)
                let delay = Double(min(30 * Int(pow(2.0, Double(state.syncRetryCount - 1))), 120))
                return .run { send in
                    try await Task.sleep(for: .seconds(delay))
                    await send(.syncPendingItems)
                }
                .cancellable(id: CancelID.syncRetry, cancelInFlight: true)

            case .dismissSyncBanner:
                state.showSyncFailureBanner = false
                return .none

            case let .connectivityChanged(isConnected):
                state.isOffline = !isConnected
                var effects: [Effect<Action>] = []

                if isConnected && state.syncRetryCount > 0 {
                    // Back online - retry sync
                    effects.append(.send(.syncPendingItems))
                }

                // Auto-retry queued upload when connectivity returns
                if isConnected, let scanUpload = state.scanUpload, scanUpload.isOfflineQueued {
                    effects.append(.send(.scanUpload(.presented(.retryUpload))))
                }

                return effects.isEmpty ? .none : .merge(effects)

            case .appEnteredForeground:
                return .run { send in
                    let isConnected = await pantryClient.isNetworkAvailable()
                    await send(.connectivityChanged(isConnected))
                    await send(.syncPendingItems)
                }

            case .fabToggled:
                state.isFABExpanded.toggle()
                return .none

            case .scanItemsTapped:
                // Check subscription status first
                return .run { send in
                    let status = await subscriptionClient.currentEntitlement()
                    switch status {
                    case .free, .unknown:
                        await send(.paywallPurchaseCompleted) // For now, proceed to camera (paywall presentation TBD)
                    case .pro:
                        await send(.checkCameraPermission)
                    }
                }

            case .paywallDismissed:
                state.showPaywall = false
                state.isFABExpanded = false
                return .none

            case .paywallPurchaseCompleted:
                state.showPaywall = false
                return .send(.checkCameraPermission)

            case .checkCameraPermission:
                let currentStatus = cameraClient.authorizationStatus()
                state.cameraPermissionStatus = currentStatus

                switch currentStatus {
                case .authorized:
                    state.showCamera = true
                    return .none
                case .notDetermined:
                    // Request authorization
                    return .run { send in
                        let status = await cameraClient.requestAuthorization()
                        await send(.cameraPermissionResult(status))
                    }
                case .denied, .restricted:
                    state.showSettingsRedirect = true
                    return .none
                @unknown default:
                    state.showSettingsRedirect = true
                    return .none
                }

            case let .cameraPermissionResult(status):
                state.cameraPermissionStatus = status
                if status == .authorized {
                    state.showCamera = true
                    state.isFABExpanded = false
                } else {
                    state.showSettingsRedirect = true
                }
                return .none

            case .settingsRedirectDismissed:
                state.showSettingsRedirect = false
                return .none

            case .cameraDismissed:
                state.showCamera = false
                return .none

            case let .cameraPhotoReady(image, scanType):
                // Dismiss camera and create upload state
                state.showCamera = false
                guard let userId = state.userId else { return .none }

                // Create ScanUploadReducer state and present upload view
                state.scanUpload = ScanUploadReducer.State(
                    image: image,
                    scanType: scanType,
                    userId: userId
                )
                return .none

            case .scanUpload(.presented(.delegate(.dismissed))):
                state.scanUpload = nil
                return .none

            case let .scanUpload(.presented(.delegate(.uploadStarted(scanJob)))):
                // Upload completed - store scan job for future status tracking
                print("Scan job started: \(scanJob.id), status: \(scanJob.status)")
                return .none

            case let .scanUpload(.presented(.delegate(.analysisCompleted(items, scanJob)))):
                // Analysis completed - dismiss upload and present scan results
                state.scanUpload = nil
                guard let userId = state.userId else { return .none }
                state.scanResults = ScanResultsReducer.State(
                    userId: userId,
                    scanType: scanJob.scanType,
                    photoUrl: scanJob.photoUrl,
                    detectedItems: items
                )
                return .none

            case .scanUpload:
                return .none

            case .dismissUploadCompleteBanner:
                state.showUploadCompleteBanner = false
                return .none

            case let .scanResults(.presented(.delegate(.itemsAdded(count, itemNames)))):
                // Items added - dismiss results, show recipe suggestions, trigger sync
                state.scanResults = nil
                state.scannedItemNames = itemNames
                state.showRecipeSuggestions = true
                // TODO: Check if this was user's first scan -> show upgrade banner
                state.showUpgradeBanner = false // For now, disabled until quota tracking is implemented
                return .merge(
                    .send(.onAppear),
                    .send(.syncPendingItems)
                )

            case .scanResults(.presented(.delegate(.dismissed))):
                state.scanResults = nil
                return .none

            case .scanResults:
                return .none

            case .receiptScanTapped:
                // Present receipt scanner
                state.receiptScanner = ReceiptScannerReducer.State()
                state.isFABExpanded = false
                return .none

            case let .receiptScanner(.presented(.delegate(.receiptTextCaptured(text)))):
                // Receipt text captured - dismiss scanner and analyze
                state.receiptScanner = nil
                state.isAnalyzingReceipt = true
                guard let userId = state.userId else { return .none }
                return .run { [userId, apolloClient, clock] send in
                    do {
                        // 30-second timeout per locked user decision
                        let mutation = AnalyzeReceiptTextMutation(userId: userId, text: text)
                        let result = try await withThrowingTaskGroup(of: AnalyzeReceiptTextMutation.Data?.self) { group in
                            group.addTask {
                                let response = try await apolloClient.perform(mutation: mutation)
                                return response.data
                            }
                            group.addTask {
                                try await clock.sleep(for: .seconds(30))
                                return nil
                            }
                            guard let first = try await group.next() else {
                                group.cancelAll()
                                throw CancellationError()
                            }
                            group.cancelAll()
                            return first
                        }
                        guard let data = result else {
                            await send(.receiptAnalysisFailed("No response from analysis"))
                            return
                        }
                        let response = data.analyzeReceiptText
                        let items: [DetectedItem] = response.items.map { item in
                            DetectedItem(
                                name: item.name,
                                quantity: item.quantity,
                                category: FoodCategory(rawValue: item.category) ?? .produce,
                                storageLocation: StorageLocation(rawValue: item.storageLocation) ?? .fridge,
                                estimatedExpiryDays: item.estimatedExpiryDays,
                                confidence: item.confidence
                            )
                        }
                        await send(.receiptAnalysisCompleted(items))
                    } catch is CancellationError {
                        await send(.receiptAnalysisFailed("Analysis timed out. Please retry."))
                    } catch {
                        await send(.receiptAnalysisFailed(error.localizedDescription))
                    }
                }

            case let .receiptAnalysisCompleted(items):
                state.isAnalyzingReceipt = false
                guard let userId = state.userId else { return .none }
                state.scanResults = ScanResultsReducer.State(
                    userId: userId,
                    scanType: .receipt,
                    photoUrl: nil,
                    detectedItems: items
                )
                return .none

            case let .receiptAnalysisFailed(errorMessage):
                state.isAnalyzingReceipt = false
                // Show error alert
                state.alert = AlertState {
                    TextState(String(localized: "scan.failure.title", defaultValue: "Analysis Failed", bundle: .main))
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState(String(localized: "common.cancel", defaultValue: "Cancel", bundle: .main))
                    }
                } message: {
                    TextState(errorMessage)
                }
                return .none

            case .receiptScanner(.presented(.delegate(.cancelled))):
                state.receiptScanner = nil
                return .none

            case .receiptScanner:
                return .none

            case .dismissRecipeSuggestions:
                state.showRecipeSuggestions = false
                state.scannedItemNames = []
                return .none

            case .dismissUpgradeBanner:
                state.showUpgradeBanner = false
                return .none

            case let .consumeItem(id):
                guard state.userId != nil else { return .none }
                state.items.remove(id: id)
                return .run { send in
                    try await pantryClient.deleteItem(id)
                    await send(.itemDeleted)
                    await send(.syncPendingItems)
                }

            case let .discardItem(id):
                guard state.userId != nil else { return .none }
                state.items.remove(id: id)
                return .run { send in
                    try await pantryClient.deleteItem(id)
                    await send(.itemDeleted)
                    await send(.syncPendingItems)
                }

            case let .expiryDateTapped(id):
                guard let item = state.items[id: id] else { return .none }
                state.datePickerItemId = id
                state.datePickerDate = item.expiryDate ?? Date()
                state.showDatePicker = true
                return .none

            case let .setDatePickerDate(date):
                state.datePickerDate = date
                return .none

            case .datePickerDismissed:
                state.showDatePicker = false
                state.datePickerItemId = nil
                return .none

            case .datePickerSaved:
                guard let itemId = state.datePickerItemId,
                      let item = state.items[id: itemId],
                      let userId = state.userId else {
                    state.showDatePicker = false
                    state.datePickerItemId = nil
                    return .none
                }

                let newDate = state.datePickerDate
                state.showDatePicker = false
                state.datePickerItemId = nil

                return .run { send in
                    let input = PantryItemInput(
                        userId: userId,
                        name: item.name,
                        quantity: item.quantity,
                        unit: item.unit,
                        storageLocation: item.storageLocation,
                        foodCategory: item.foodCategory,
                        notes: item.notes,
                        source: item.source,
                        expiryDate: newDate
                    )
                    try await pantryClient.updateItem(itemId, input)
                    await send(.onAppear)
                    await send(.syncPendingItems)
                }

            case .requestNotificationPermission:
                guard !state.notificationPermissionRequested else { return .none }
                state.notificationPermissionRequested = true

                return .run { send in
                    let status = await notificationClient.requestAuthorization()
                    await send(.notificationPermissionResult(status))
                    if status == .authorized {
                        await send(.registerForRemoteNotifications)
                    }
                }

            case .registerForRemoteNotifications:
                return .run { _ in
                    await notificationClient.registerForRemoteNotifications()
                }

            case let .notificationPermissionResult(status):
                print("Notification permission result: \(status)")
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$addEditForm, action: \.addEditForm) {
            AddEditItemReducer()
        }
        .ifLet(\.$scanUpload, action: \.scanUpload) {
            ScanUploadReducer()
        }
        .ifLet(\.$scanResults, action: \.scanResults) {
            ScanResultsReducer()
        }
        .ifLet(\.$receiptScanner, action: \.receiptScanner) {
            ReceiptScannerReducer()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
