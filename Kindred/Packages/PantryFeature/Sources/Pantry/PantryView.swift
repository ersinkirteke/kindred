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
            .navigationTitle("Pantry")
            .toolbar {
                if store.userId != nil && !store.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            store.send(.addItemTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add pantry item")
                    }
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
                .accessibilityLabel("Add pantry item")
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    @ViewBuilder
    private var pantryList: some View {
        List {
            if !store.fridgeItems.isEmpty {
                Section {
                    ForEach(store.fridgeItems) { item in
                        PantryItemRow(item: item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.fridgeItems[index]
                            store.send(.deleteItem(item.id))
                        }
                    }
                } header: {
                    Label("Fridge", systemImage: StorageLocation.fridge.iconName)
                }
            }

            if !store.freezerItems.isEmpty {
                Section {
                    ForEach(store.freezerItems) { item in
                        PantryItemRow(item: item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.freezerItems[index]
                            store.send(.deleteItem(item.id))
                        }
                    }
                } header: {
                    Label("Freezer", systemImage: StorageLocation.freezer.iconName)
                }
            }

            if !store.pantryItems.isEmpty {
                Section {
                    ForEach(store.pantryItems) { item in
                        PantryItemRow(item: item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = store.pantryItems[index]
                            store.send(.deleteItem(item.id))
                        }
                    }
                } header: {
                    Label("Pantry", systemImage: StorageLocation.pantry.iconName)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// Simple item row - detailed editing deferred to Phase 13
private struct PantryItemRow: View {
    let item: PantryItemState

    var body: some View {
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
            }

            Spacer()

            if !item.isSynced {
                Image(systemName: "icloud.slash")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("Not synced")
            }
        }
        .accessibilityElement(children: .combine)
    }
}
