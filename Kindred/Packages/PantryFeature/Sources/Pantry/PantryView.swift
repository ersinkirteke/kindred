import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct PantryView: View {
    @Bindable var store: StoreOf<PantryReducer>

    public init(store: StoreOf<PantryReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
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
            .navigationTitle(String(localized: "pantry.title", bundle: .main))
            .searchable(text: $store.searchText.sending(\.searchTextChanged), prompt: String(localized: "pantry.search.prompt", defaultValue: "Search items", bundle: .main))
            .toolbar {
                // Sync indicator in toolbar
                if store.isSyncing {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                // Offline indicator
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
            .safeAreaInset(edge: .top, spacing: 0) {
                if store.showSyncFailureBanner {
                    syncFailureBanner
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating + button per user decision
            if store.userId != nil && !store.isEmpty {
                Button {
                    store.send(.addItemTapped)
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor, in: Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .accessibilityLabel(String(localized: "accessibility.pantry.add_item", bundle: .main))
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.send(.appEnteredForeground)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.addEditForm, action: \.addEditForm)) { formStore in
            AddEditItemFormView(store: formStore)
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
