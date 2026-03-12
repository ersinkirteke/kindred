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
                            PantryItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.fridgeItems[index]
                            store.send(.confirmDeleteItem(item.id))
                        }
                    }
                } header: {
                    Label {
                        Text("\(StorageLocation.fridge.displayName) (\(store.fridgeItems.count) items)")
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
                            PantryItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.freezerItems[index]
                            store.send(.confirmDeleteItem(item.id))
                        }
                    }
                } header: {
                    Label {
                        Text("\(StorageLocation.freezer.displayName) (\(store.freezerItems.count) items)")
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
                            PantryItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.pantryItems[index]
                            store.send(.confirmDeleteItem(item.id))
                        }
                    }
                } header: {
                    Label {
                        Text("\(StorageLocation.pantry.displayName) (\(store.pantryItems.count) items)")
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.body)
                    if let badge = expiryBadge {
                        Text(badge.text)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.15), in: Capsule())
                            .foregroundStyle(badge.color)
                    }
                }

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
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
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
        .accessibilityElement(children: .combine)
    }

    private var expiryBadge: (text: String, color: Color)? {
        guard let expiry = item.expiryDate else { return nil }
        let now = Date()
        if expiry < now {
            return (String(localized: "pantry.badge.expired", defaultValue: "Expired", bundle: .main), .red)
        }
        let threeDays = Calendar.current.date(byAdding: .day, value: 3, to: now)!
        if expiry < threeDays {
            return (String(localized: "pantry.badge.expiring_soon", defaultValue: "Exp. soon", bundle: .main), .orange)
        }
        return nil
    }

    private var subtitleText: String? {
        var parts: [String] = []
        if let expiry = item.expiryDate {
            parts.append("Exp: \(expiry.formatted(.dateTime.month(.abbreviated).day()))")
        }
        if let notes = item.notes, !notes.isEmpty {
            let firstLine = notes.components(separatedBy: .newlines).first ?? notes
            parts.append(firstLine)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
