import ComposableArchitecture
import DesignSystem
import MonetizationFeature
import SwiftUI
import UIKit

public struct PantryView: View {
    @Bindable var store: StoreOf<PantryReducer>

    public init(store: StoreOf<PantryReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            mainContent
                .alert($store.scope(state: \.alert, action: \.alert))
                .sheet(item: $store.scope(state: \.addEditForm, action: \.addEditForm)) { formStore in
                    AddEditItemFormView(store: formStore)
                }
                .fullScreenCover(item: $store.scope(state: \.scanUpload, action: \.scanUpload)) { uploadStore in
                    ScanUploadView(store: uploadStore)
                }
                .sheet(item: $store.scope(state: \.scanResults, action: \.scanResults)) { resultsStore in
                    ScanResultsView(store: resultsStore)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .fullScreenCover(item: $store.scope(state: \.receiptScanner, action: \.receiptScanner)) { scannerStore in
                    ReceiptScannerView(store: scannerStore)
                }
                .sheet(isPresented: Binding(
                    get: { store.showDatePicker },
                    set: { if !$0 { store.send(.datePickerDismissed) } }
                )) {
                    NavigationStack {
                        VStack {
                            Text(String(localized: "pantry.expiry.disclaimer", defaultValue: "AI estimate — check packaging", bundle: .main))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top)

                            DatePicker(
                                "Expiry Date",
                                selection: Binding(
                                    get: { store.datePickerDate },
                                    set: { store.send(.setDatePickerDate($0)) }
                                ),
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                        }
                        .navigationTitle(String(localized: "pantry.expiry.update_title", defaultValue: "Update Expiry", bundle: .main))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(String(localized: "common.save", defaultValue: "Save", bundle: .main)) {
                                    store.send(.datePickerSaved)
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button(String(localized: "common.cancel", defaultValue: "Cancel", bundle: .main)) {
                                    store.send(.datePickerDismissed)
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
        }
        .overlay(alignment: .bottomTrailing) { fabOverlay }
        .contentShape(Rectangle())
        .onTapGesture { handleBackgroundTap() }
        .onAppear { store.send(.onAppear) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.send(.appEnteredForeground)
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.showCamera },
            set: { if !$0 { store.send(.cameraDismissed) } }
        )) {
            cameraWrapperView
        }
        .alert(cameraPermissionAlertTitle, isPresented: Binding(
            get: { store.showSettingsRedirect },
            set: { if !$0 { store.send(.settingsRedirectDismissed) } }
        )) {
            Button(cameraPermissionSettingsButton) { openSettings() }
            Button(cameraPermissionCancelButton, role: .cancel) { store.send(.settingsRedirectDismissed) }
        } message: {
            Text(cameraPermissionMessage)
        }
    }

    private var mainContent: some View {
        NavigationStack {
            contentGroup
                .navigationTitle(String(localized: "pantry.title", bundle: .main))
                .searchable(text: $store.searchText.sending(\.searchTextChanged), prompt: String(localized: "pantry.search.prompt", defaultValue: "Search items", bundle: .main))
                .toolbar { toolbarContent }
                .safeAreaInset(edge: .top, spacing: 0) { bannerStack }
        }
    }

    @ViewBuilder
    private var contentGroup: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.isEmpty {
                PantryEmptyStateView(
                    isGuest: store.userId == nil,
                    onAddTapped: { store.send(.addItemTapped) },
                    onSignInTapped: { store.send(.delegate(.authGateRequested)) }
                )
            } else {
                pantryList
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if store.isSyncing {
            ToolbarItem(placement: .topBarTrailing) {
                ProgressView()
                    .controlSize(.small)
            }
        }

        if store.isOffline {
            ToolbarItem(placement: .topBarLeading) {
                Label {
                    Text(String(localized: "pantry.offline", defaultValue: "Offline", bundle: .main))
                } icon: {
                    Image(systemName: "wifi.slash")
                }
                .font(.caption2)
                .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var fabOverlay: some View {
        if store.userId != nil {
            ExpandableFAB(
                isExpanded: Binding(
                    get: { store.isFABExpanded },
                    set: { _ in store.send(.fabToggled) }
                ),
                onAddManual: { store.send(.addItemTapped) },
                onScanItems: { store.send(.scanItemsTapped) },
                onScanReceipt: { store.send(.receiptScanTapped) },
                showProBadge: shouldShowProBadge(store: store)
            )
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private var cameraWrapperView: some View {
        CameraViewWrapper(
            onDismissed: { store.send(.cameraDismissed) },
            onPhotoReady: { image, scanType in
                store.send(.cameraPhotoReady(image, scanType))
            }
        )
    }

    private func handleBackgroundTap() {
        if store.isFABExpanded {
            withAnimation {
                store.send(.fabToggled)
            }
        }
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private var cameraPermissionAlertTitle: String {
        String(localized: "pantry.camera.permission.title", defaultValue: "Camera Access Required", bundle: .main)
    }

    private var cameraPermissionSettingsButton: String {
        String(localized: "pantry.camera.permission.settings", defaultValue: "Open Settings", bundle: .main)
    }

    private var cameraPermissionCancelButton: String {
        String(localized: "common.cancel", defaultValue: "Cancel", bundle: .main)
    }

    private var cameraPermissionMessage: String {
        String(localized: "pantry.camera.permission.message", defaultValue: "Kindred needs camera access to scan your ingredients. Please enable it in Settings.", bundle: .main)
    }

    @ViewBuilder
    private var bannerStack: some View {
        VStack(spacing: 0) {
            if store.showSyncFailureBanner {
                syncFailureBanner
            }
            if store.showUploadCompleteBanner {
                uploadCompleteBanner
            }
        }
    }

    @ViewBuilder
    private var syncFailureBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(String(localized: "pantry.sync.failure", defaultValue: "Unable to sync. Will retry.", bundle: .main))
                .font(.footnote)
            Spacer()
            Button {
                store.send(.dismissSyncBanner)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
    }

    @ViewBuilder
    private var uploadCompleteBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(String(localized: "scan.upload.success_banner", defaultValue: "Scan uploaded successfully", bundle: .main))
                .font(.footnote)
            Spacer()
            Button {
                store.send(.dismissUploadCompleteBanner)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.1))
        .onAppear {
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                store.send(.dismissUploadCompleteBanner)
            }
        }
    }

    @ViewBuilder
    private var pantryList: some View {
        List {
            if !store.fridgeItems.isEmpty {
                Section {
                    ForEach(store.fridgeItems) { item in
                        Button {
                            store.send(.editItemTapped(item.id))
                        } label: {
                            PantryItemRow(item: item, onExpiryTapped: { store.send(.expiryDateTapped(item.id)) })
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                store.send(.consumeItem(item.id))
                            } label: {
                                Label(String(localized: "pantry.action.consumed", defaultValue: "Consumed", bundle: .main), systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.discardItem(item.id))
                            } label: {
                                Label(String(localized: "pantry.action.discard", defaultValue: "Discard", bundle: .main), systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.fridgeItems[index]
                            store.send(.confirmDeleteItem(item.id))
                        }
                    }
                } header: {
                    Label {
                        Text("\(StorageLocation.fridge.displayName) (\(store.fridgeItems.count) \(String(localized: "pantry.section.items_label", defaultValue: "items", bundle: .main)))")
                    } icon: {
                        Image(systemName: StorageLocation.fridge.iconName)
                    }
                }
            }

            if !store.freezerItems.isEmpty {
                Section {
                    ForEach(store.freezerItems) { item in
                        Button {
                            store.send(.editItemTapped(item.id))
                        } label: {
                            PantryItemRow(item: item, onExpiryTapped: { store.send(.expiryDateTapped(item.id)) })
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                store.send(.consumeItem(item.id))
                            } label: {
                                Label(String(localized: "pantry.action.consumed", defaultValue: "Consumed", bundle: .main), systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.discardItem(item.id))
                            } label: {
                                Label(String(localized: "pantry.action.discard", defaultValue: "Discard", bundle: .main), systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.freezerItems[index]
                            store.send(.confirmDeleteItem(item.id))
                        }
                    }
                } header: {
                    Label {
                        Text("\(StorageLocation.freezer.displayName) (\(store.freezerItems.count) \(String(localized: "pantry.section.items_label", defaultValue: "items", bundle: .main)))")
                    } icon: {
                        Image(systemName: StorageLocation.freezer.iconName)
                    }
                }
            }

            if !store.pantryItems.isEmpty {
                Section {
                    ForEach(store.pantryItems) { item in
                        Button {
                            store.send(.editItemTapped(item.id))
                        } label: {
                            PantryItemRow(item: item, onExpiryTapped: { store.send(.expiryDateTapped(item.id)) })
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                store.send(.consumeItem(item.id))
                            } label: {
                                Label(String(localized: "pantry.action.consumed", defaultValue: "Consumed", bundle: .main), systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.discardItem(item.id))
                            } label: {
                                Label(String(localized: "pantry.action.discard", defaultValue: "Discard", bundle: .main), systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.pantryItems[index]
                            store.send(.confirmDeleteItem(item.id))
                        }
                    }
                } header: {
                    Label {
                        Text("\(StorageLocation.pantry.displayName) (\(store.pantryItems.count) \(String(localized: "pantry.section.items_label", defaultValue: "items", bundle: .main)))")
                    } icon: {
                        Image(systemName: StorageLocation.pantry.iconName)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            store.send(.refreshTriggered)
        }
    }

    /// Determine if Pro badge should be shown on Scan items button
    private func shouldShowProBadge(store: StoreOf<PantryReducer>) -> Bool {
        // This is a simplified check - in real implementation, we'd check subscription status
        // For now, always show Pro badge to indicate it's a premium feature
        return true
    }
}

private struct CameraViewWrapper: View {
    let onDismissed: () -> Void
    let onPhotoReady: (UIImage, ScanType) -> Void
    @State private var cameraStore: StoreOf<CameraReducer>

    init(
        onDismissed: @escaping () -> Void,
        onPhotoReady: @escaping (UIImage, ScanType) -> Void
    ) {
        self.onDismissed = onDismissed
        self.onPhotoReady = onPhotoReady
        self._cameraStore = State(initialValue: Store(initialState: CameraReducer.State()) {
            CameraReducer()
        })
    }

    var body: some View {
        CameraView(store: cameraStore)
            .onChange(of: cameraStore.selectedScanType) { _, scanType in
                if let scanType, let image = cameraStore.capturedImage {
                    onPhotoReady(image, scanType)
                }
            }
            .onDisappear {
                if cameraStore.selectedScanType == nil {
                    onDismissed()
                }
            }
    }
}

private struct PantryItemRow: View {
    let item: PantryItemState
    var onExpiryTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            // Left edge expiry indicator (only visible when item has expiry)
            if item.expiryStatus != .none {
                Rectangle()
                    .fill(item.expiryColor)
                    .frame(width: 3)
            }

            // Existing content with left padding
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body)

                    HStack(spacing: 4) {
                        Text(item.quantity)
                        if let unit = item.unit {
                            Text(unit)
                        }
                        if let category = item.foodCategory {
                            Text("·")
                            Text(category.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Subtitle: expiry date and/or notes
                    if let subtitle = subtitleText {
                        if let expiry = item.expiryDate, onExpiryTapped != nil {
                            Button(action: { onExpiryTapped?() }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(String(localized: "pantry.item.expires_prefix", defaultValue: "Expires", bundle: .main)) ~\(expiry.formatted(.dateTime.month(.abbreviated).day()))")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text(String(localized: "pantry.expiry.disclaimer", defaultValue: "AI estimate — check packaging", bundle: .main))
                                        .font(.caption2)
                                        .foregroundStyle(.quaternary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                if !item.isSynced {
                    Image(systemName: "icloud.slash")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(String(localized: "accessibility.pantry.not_synced", bundle: .main))
                }
            }
            .padding(.leading, item.expiryStatus != .none ? 8 : 0)
        }
        .opacity(item.expiryStatus == .expired ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)
    }

    private var subtitleText: String? {
        var parts: [String] = []
        if let expiry = item.expiryDate {
            let expiresLabel = String(localized: "pantry.item.expires_prefix", defaultValue: "Expires", bundle: .main)
            parts.append("\(expiresLabel) ~\(expiry.formatted(.dateTime.month(.abbreviated).day()))")
        }
        if let notes = item.notes, !notes.isEmpty {
            let firstLine = notes.components(separatedBy: .newlines).first ?? notes
            parts.append(firstLine)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
