import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct AddEditItemFormView: View {
    @Bindable var store: StoreOf<AddEditItemReducer>

    public init(store: StoreOf<AddEditItemReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            formContent
                .navigationTitle(navigationTitle)
                .toolbar {
                    toolbarContent
                }
                .alert($store.scope(state: \.confirmDiscard, action: \.alert))
                .alert($store.scope(state: \.confirmDelete, action: \.alert))
        }
    }

    private var formContent: some View {
        Form {
            itemDetailsSection
            storageLocationSection
            categorySection
            expiryDateSection
            notesSection
            if case .edit = store.mode {
                deleteSection
            }
        }
    }

    private var navigationTitle: String {
        store.mode == .add
            ? String(localized: "pantry.add.title", defaultValue: "Add Item", bundle: .main)
            : String(localized: "pantry.edit.title", defaultValue: "Edit Item", bundle: .main)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "pantry.add.cancel", defaultValue: "Cancel", bundle: .main)) {
                store.send(.cancelTapped)
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            if store.isSubmitting {
                ProgressView()
            } else {
                Button(submitButtonTitle) {
                    store.send(.submitTapped)
                }
                .disabled(!store.isValid)
            }
        }
    }

    private var submitButtonTitle: String {
        store.mode == .add
            ? String(localized: "pantry.add.add", defaultValue: "Add", bundle: .main)
            : String(localized: "pantry.edit.save", defaultValue: "Save", bundle: .main)
    }

    // MARK: - Sections

    private var itemDetailsSection: some View {
        Section {
            nameField
            quantityAndUnitRow
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(
                String(localized: "pantry.add.name_placeholder", defaultValue: "Item name", bundle: .main),
                text: $store.name.sending(\.nameChanged)
            )
            .textInputAutocapitalization(.words)

            if !store.suggestions.isEmpty {
                suggestionsScrollView
            }

            if let warning = store.duplicateWarning {
                duplicateWarningView(warning)
            }
        }
    }

    private var suggestionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.suggestions, id: \.name) { suggestion in
                    suggestionChip(suggestion)
                }
            }
        }
    }

    private func suggestionChip(_ suggestion: AutocompleteSuggestion) -> some View {
        Button {
            store.send(.suggestionTapped(suggestion))
        } label: {
            Text(suggestion.name)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
    }

    private func duplicateWarningView(_ warning: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(warning)
                .font(.caption)
        }
        .foregroundStyle(.orange)
    }

    private var quantityAndUnitRow: some View {
        HStack {
            quantityField
            unitPicker
        }
    }

    private var quantityField: some View {
        TextField(
            String(localized: "pantry.add.quantity_placeholder", defaultValue: "Qty", bundle: .main),
            text: $store.quantity.sending(\.quantityChanged)
        )
        .keyboardType(.decimalPad)
        .frame(maxWidth: 100)
    }

    private var unitPicker: some View {
        Picker(
            String(localized: "pantry.add.unit_label", defaultValue: "Unit", bundle: .main),
            selection: $store.unit.sending(\.unitChanged)
        ) {
            Text("—").tag(nil as String?)
            Text("kg").tag("kg" as String?)
            Text("g").tag("g" as String?)
            Text("L").tag("L" as String?)
            Text("ml").tag("ml" as String?)
            Text("pcs").tag("pcs" as String?)
            Text(String(localized: "pantry.add.unit_bunch", defaultValue: "bunch", bundle: .main)).tag("bunch" as String?)
            Text(String(localized: "pantry.add.unit_can", defaultValue: "can", bundle: .main)).tag("can" as String?)
            Text(String(localized: "pantry.add.unit_bottle", defaultValue: "bottle", bundle: .main)).tag("bottle" as String?)
            Text(String(localized: "pantry.add.unit_bag", defaultValue: "bag", bundle: .main)).tag("bag" as String?)
        }
        .pickerStyle(.menu)
    }

    private var storageLocationSection: some View {
        Section {
            Picker(
                String(localized: "pantry.add.storage_label", defaultValue: "Storage", bundle: .main),
                selection: $store.storageLocation.sending(\.storageLocationChanged)
            ) {
                ForEach(StorageLocation.allCases, id: \.self) { location in
                    Label(location.displayName, systemImage: location.iconName)
                        .tag(location)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var categorySection: some View {
        Section {
            if let suggested = store.suggestedCategory, store.foodCategory == nil {
                categorySuggestionRow(suggested)
            } else if let category = store.foodCategory {
                categorySelectedRow(category)
            } else {
                categoryPickerRow
            }
        }
    }

    private func categorySuggestionRow(_ suggested: FoodCategory) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "pantry.add.suggested_category", defaultValue: "Suggested", bundle: .main))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(suggested.displayName)
                    .font(.body)
            }
            Spacer()
            Button(String(localized: "pantry.add.accept", defaultValue: "Accept", bundle: .main)) {
                store.send(.foodCategoryChanged(suggested))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button(String(localized: "pantry.add.skip", defaultValue: "Skip", bundle: .main)) {
                store.send(.clearSuggestedCategory)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func categorySelectedRow(_ category: FoodCategory) -> some View {
        HStack {
            Text(String(localized: "pantry.add.category_label", defaultValue: "Category", bundle: .main))
            Spacer()
            Text(category.displayName)
                .foregroundStyle(.secondary)
            Button(String(localized: "pantry.add.change", defaultValue: "Change", bundle: .main)) {
                store.send(.foodCategoryChanged(nil))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var categoryPickerRow: some View {
        Picker(
            String(localized: "pantry.add.set_category", defaultValue: "Set category", bundle: .main),
            selection: $store.foodCategory.sending(\.foodCategoryChanged)
        ) {
            Text("—").tag(nil as FoodCategory?)
            ForEach(FoodCategory.allCases, id: \.self) { category in
                Text(category.displayName).tag(category as FoodCategory?)
            }
        }
    }

    private var expiryDateSection: some View {
        Section {
            expiryShortcuts
            expiryDatePicker
        } header: {
            Text(String(localized: "pantry.add.expiry_section", defaultValue: "Expiry Date", bundle: .main))
        }
    }

    private var expiryShortcuts: some View {
        HStack(spacing: 8) {
            Button(String(localized: "pantry.add.expiry_tomorrow", defaultValue: "Tomorrow", bundle: .main)) {
                store.send(.expiryDateChanged(.tomorrow))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(String(localized: "pantry.add.expiry_3days", defaultValue: "3 days", bundle: .main)) {
                store.send(.expiryDateChanged(.daysFromNow(3)))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(String(localized: "pantry.add.expiry_1week", defaultValue: "1 week", bundle: .main)) {
                store.send(.expiryDateChanged(.oneWeekFromNow))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(String(localized: "pantry.add.expiry_1month", defaultValue: "1 month", bundle: .main)) {
                store.send(.expiryDateChanged(.oneMonthFromNow))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var expiryDatePicker: some View {
        Group {
            if let expiry = store.expiryDate {
                HStack {
                    DatePicker(
                        String(localized: "pantry.add.expiry_custom", defaultValue: "Custom date", bundle: .main),
                        selection: Binding(
                            get: { expiry },
                            set: { store.send(.expiryDateChanged($0)) }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    Button(String(localized: "pantry.add.expiry_clear", defaultValue: "Clear", bundle: .main)) {
                        store.send(.expiryDateChanged(nil))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                DatePicker(
                    String(localized: "pantry.add.expiry_custom", defaultValue: "Custom date", bundle: .main),
                    selection: Binding(
                        get: { Date.tomorrow },
                        set: { store.send(.expiryDateChanged($0)) }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
            }
        }
    }

    private var notesSection: some View {
        Section {
            if store.showNotesField {
                TextField(
                    String(localized: "pantry.add.notes_placeholder", defaultValue: "Notes", bundle: .main),
                    text: $store.notes.sending(\.notesChanged),
                    axis: .vertical
                )
                .lineLimit(3...6)
            } else {
                Button(String(localized: "pantry.add.add_notes", defaultValue: "Add notes", bundle: .main)) {
                    store.send(.showNotesFieldTapped)
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                store.send(.deleteTapped)
            } label: {
                HStack {
                    Spacer()
                    Text(String(localized: "pantry.edit.delete", defaultValue: "Delete Item", bundle: .main))
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Date Extensions for Expiry Shortcuts
extension Date {
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    static var oneWeekFromNow: Date { daysFromNow(7) }

    static var oneMonthFromNow: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }
}
