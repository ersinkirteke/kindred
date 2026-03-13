import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct ScanResultsView: View {
    @Bindable var store: StoreOf<ScanResultsReducer>
    @AccessibilityFocusState private var isConfidenceFocused: UUID?

    public init(store: StoreOf<ScanResultsReducer>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                // Background photo (dimmed) if available
                if let photoUrl = store.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(0.3)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .ignoresSafeArea()
                }

                // Bottom sheet with scan results
                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "scan.results.title", bundle: .main))
                                .font(.title2.bold())

                            Text(String(
                                format: String(localized: "scan.results.item_count", bundle: .main),
                                store.detectedItems.count
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            store.send(.dismissTapped)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(String(localized: "common.close", bundle: .main))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    Divider()

                    // Checklist
                    if store.detectedItems.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(store.detectedItems) { item in
                                    itemRow(item: item)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)

                                    if item.id != store.detectedItems.last?.id {
                                        Divider()
                                            .padding(.leading, 70)
                                    }
                                }

                                // Add item AI missed
                                addMissedItemRow
                            }
                            .padding(.top, 8)
                        }
                    }

                    Divider()

                    // Bulk add button
                    bulkAddButton
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Item Row

    @ViewBuilder
    private func itemRow(item: ScanResultsReducer.DetectedItemState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button {
                store.send(.itemToggled(id: item.id))
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? Color.accentColor : Color.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(item.isChecked ? String(localized: "accessibility.checked", bundle: .main) : String(localized: "accessibility.unchecked", bundle: .main))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    // Confidence badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.badgeColor)
                            .frame(width: 8, height: 8)

                        Text("\(item.confidence)%")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.badgeColor.opacity(0.15))
                    .clipShape(Capsule())
                    .accessibilityLabel(confidenceLabel(for: item.confidence))
                    .accessibilityFocused($isConfidenceFocused, equals: item.id)

                    Spacer()

                    // Edit button
                    Button {
                        store.send(.itemEditTapped(id: item.id))
                    } label: {
                        Image(systemName: item.isEditing ? "checkmark" : "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(item.isEditing ? String(localized: "common.done", bundle: .main) : String(localized: "common.edit", bundle: .main))
                }

                if item.isEditing {
                    // Edit mode
                    VStack(alignment: .leading, spacing: 12) {
                        TextField(String(localized: "pantry.form.name", bundle: .main), text: Binding(
                            get: { item.name },
                            set: { newName in
                                store.send(.itemFieldChanged(id: item.id, name: newName, quantity: nil, category: nil, storageLocation: nil))
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.body.weight(.medium))

                        HStack(spacing: 12) {
                            TextField(String(localized: "pantry.form.quantity", bundle: .main), text: Binding(
                                get: { item.quantity },
                                set: { newQty in
                                    store.send(.itemFieldChanged(id: item.id, name: nil, quantity: newQty, category: nil, storageLocation: nil))
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)

                            Picker(String(localized: "pantry.form.category", bundle: .main), selection: Binding(
                                get: { item.category },
                                set: { newCat in
                                    store.send(.itemFieldChanged(id: item.id, name: nil, quantity: nil, category: newCat, storageLocation: nil))
                                }
                            )) {
                                ForEach(FoodCategory.allCases, id: \.self) { category in
                                    Text(category.displayName).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Picker(String(localized: "pantry.form.location", bundle: .main), selection: Binding(
                            get: { item.storageLocation },
                            set: { newLoc in
                                store.send(.itemFieldChanged(id: item.id, name: nil, quantity: nil, category: nil, storageLocation: newLoc))
                            }
                        )) {
                            ForEach(StorageLocation.allCases, id: \.self) { location in
                                Label(location.displayName, systemImage: location.iconName).tag(location)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    // Display mode
                    Text(item.name)
                        .font(.body.weight(.medium))

                    HStack(spacing: 8) {
                        Text(item.quantity)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(item.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            store.send(.itemEditTapped(id: item.id))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.send(.itemRemoved(id: item.id))
            } label: {
                Label(String(localized: "common.remove", bundle: .main), systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(String(localized: "pantry.form.quantity", bundle: .main)): \(item.quantity), \(confidenceLabel(for: item.confidence)), \(item.isChecked ? String(localized: "accessibility.checked", bundle: .main) : String(localized: "accessibility.unchecked", bundle: .main))")
        .accessibilityHint(String(localized: "scan.results.item_hint", bundle: .main))
    }

    // MARK: - Add Missed Item Row

    @ViewBuilder
    private var addMissedItemRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            if store.isAddingNewItem {
                HStack(spacing: 12) {
                    TextField(String(localized: "scan.results.new_item_placeholder", bundle: .main), text: $store.newItemName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit {
                            store.send(.newItemConfirmed)
                        }

                    Button {
                        store.send(.newItemConfirmed)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                    .accessibilityLabel(String(localized: "common.add", bundle: .main))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            } else {
                Button {
                    store.send(.addNewItemTapped)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)

                        Text(String(localized: "scan.results.add_missed", bundle: .main))
                            .font(.body)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(String(localized: "scan.results.no_items", bundle: .main))
                .font(.title3.bold())

            Text(String(localized: "scan.results.empty_message", bundle: .main))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Bulk Add Button

    @ViewBuilder
    private var bulkAddButton: some View {
        VStack(spacing: 12) {
            if let errorMessage = store.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)

                    Spacer()

                    Button(String(localized: "scan.results.retry", bundle: .main)) {
                        store.send(.bulkAddTapped)
                    }
                    .font(.subheadline.bold())
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            if store.addSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(String(
                        format: String(localized: "scan.results.added_count", bundle: .main),
                        store.addedCount
                    ))
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Button {
                store.send(.bulkAddTapped)
            } label: {
                HStack(spacing: 8) {
                    if store.isAdding {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }

                    Text(String(
                        format: String(localized: "scan.results.add_items", bundle: .main),
                        store.checkedCount
                    ))
                    .font(.body.bold())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(store.checkedCount == 0 ? Color.secondary : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(store.checkedCount == 0 || store.isAdding)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .accessibilityLabel(String(
                format: String(localized: "scan.results.add_items", bundle: .main),
                store.checkedCount
            ))
            .accessibilityValue("\(store.checkedCount) \(String(localized: "scan.results.items_selected", bundle: .main))")
        }
    }

    // MARK: - Helpers

    private func confidenceLabel(for confidence: Int) -> String {
        if confidence >= 90 {
            return String(localized: "scan.results.high_confidence", bundle: .main)
        } else if confidence >= 70 {
            return String(localized: "scan.results.medium_confidence", bundle: .main)
        } else {
            return String(localized: "scan.results.low_confidence", bundle: .main)
        }
    }
}
