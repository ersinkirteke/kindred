import ComposableArchitecture
import Foundation
import UIKit

/// Suggestion item for autocomplete
public struct AutocompleteSuggestion: Equatable, Sendable {
    public let name: String
    public let unit: String?
    public let category: FoodCategory?
}

@Reducer
public struct AddEditItemReducer {
    public enum Mode: Equatable {
        case add
        case edit(UUID)
    }

    @ObservableState
    public struct State: Equatable {
        public var mode: Mode
        public var userId: String

        // Form fields
        public var name: String = ""
        public var quantity: String = "1"
        public var unit: String? = nil
        public var storageLocation: StorageLocation = .pantry
        public var foodCategory: FoodCategory? = nil
        public var expiryDate: Date? = nil
        public var notes: String = ""
        public var showNotesField: Bool = false

        // UI state
        public var isSubmitting: Bool = false
        public var suggestions: [AutocompleteSuggestion] = []
        public var duplicateWarning: String? = nil
        public var suggestedCategory: FoodCategory? = nil

        // Alerts
        @Presents public var confirmDiscard: AlertState<Action.Alert>?
        @Presents public var confirmDelete: AlertState<Action.Alert>?

        // Original values for isDirty detection
        var originalName: String = ""
        var originalQuantity: String = "1"
        var originalUnit: String? = nil
        var originalStorageLocation: StorageLocation = .pantry
        var originalFoodCategory: FoodCategory? = nil
        var originalExpiryDate: Date? = nil
        var originalNotes: String = ""

        public var isValid: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty
        }

        public var isDirty: Bool {
            name != originalName ||
            quantity != originalQuantity ||
            unit != originalUnit ||
            storageLocation != originalStorageLocation ||
            foodCategory != originalFoodCategory ||
            expiryDate != originalExpiryDate ||
            notes != originalNotes
        }

        public init(
            mode: Mode,
            userId: String,
            name: String = "",
            quantity: String = "1",
            unit: String? = nil,
            storageLocation: StorageLocation = .pantry,
            foodCategory: FoodCategory? = nil,
            expiryDate: Date? = nil,
            notes: String = ""
        ) {
            self.mode = mode
            self.userId = userId
            self.name = name
            self.quantity = quantity
            self.unit = unit
            self.storageLocation = storageLocation
            self.foodCategory = foodCategory
            self.expiryDate = expiryDate
            self.notes = notes
            self.showNotesField = !notes.isEmpty

            // Store original values
            self.originalName = name
            self.originalQuantity = quantity
            self.originalUnit = unit
            self.originalStorageLocation = storageLocation
            self.originalFoodCategory = foodCategory
            self.originalExpiryDate = expiryDate
            self.originalNotes = notes
        }
    }

    public enum Action {
        case nameChanged(String)
        case quantityChanged(String)
        case unitChanged(String?)
        case storageLocationChanged(StorageLocation)
        case foodCategoryChanged(FoodCategory?)
        case expiryDateChanged(Date?)
        case showNotesFieldTapped
        case notesChanged(String)
        case suggestionTapped(AutocompleteSuggestion)
        case suggestionsLoaded([AutocompleteSuggestion])
        case categorySuggested(FoodCategory)
        case clearSuggestedCategory
        case duplicateCheckResult(String?)
        case submitTapped
        case itemAdded(StorageLocation)
        case cancelTapped
        case deleteTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {
            case confirmDiscard
            case confirmDelete
        }

        public enum Delegate {
            case itemSaved
            case itemDeleted(UUID)
            case cancelled
        }
    }

    @Dependency(\.pantryClient) var pantryClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss

    private enum CancelID { case debounce }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .nameChanged(text):
                state.name = text
                guard text.count >= 2 else {
                    state.suggestions = []
                    state.duplicateWarning = nil
                    state.suggestedCategory = nil
                    return .cancel(id: CancelID.debounce)
                }

                // Debounce suggestions, duplicate check, and category search
                return .run { [userId = state.userId, storage = state.storageLocation] send in
                    try await clock.sleep(for: .milliseconds(300))

                    // Fetch autocomplete suggestions
                    let suggestions = await pantryClient.fetchSuggestions(userId, text)
                    let autocompleteSuggestions = suggestions.map {
                        AutocompleteSuggestion(name: $0.name, unit: $0.unit, category: $0.category)
                    }
                    await send(.suggestionsLoaded(autocompleteSuggestions))

                    // Check for duplicates
                    let isDuplicate = await pantryClient.checkDuplicate(userId, text, storage)
                    if isDuplicate {
                        let warning = String(
                            localized: "pantry.add.duplicate_warning",
                            defaultValue: "You already have \(text) in \(storage.displayName)",
                            bundle: .main
                        )
                        await send(.duplicateCheckResult(warning))
                    } else {
                        await send(.duplicateCheckResult(nil))
                    }

                    // Search for category suggestion
                    if let category = await pantryClient.searchIngredientCategory(text) {
                        await send(.categorySuggested(category))
                    }
                }
                .cancellable(id: CancelID.debounce)

            case let .quantityChanged(text):
                state.quantity = text
                return .none

            case let .unitChanged(unit):
                state.unit = unit
                return .none

            case let .storageLocationChanged(location):
                state.storageLocation = location
                // Re-check duplicate when storage location changes
                guard state.name.count >= 2 else { return .none }
                return .run { [userId = state.userId, name = state.name] send in
                    let isDuplicate = await pantryClient.checkDuplicate(userId, name, location)
                    if isDuplicate {
                        let warning = String(
                            localized: "pantry.add.duplicate_warning",
                            defaultValue: "You already have \(name) in \(location.displayName)",
                            bundle: .main
                        )
                        await send(.duplicateCheckResult(warning))
                    } else {
                        await send(.duplicateCheckResult(nil))
                    }
                }

            case let .foodCategoryChanged(category):
                state.foodCategory = category
                // Clear suggested category when user manually sets one
                state.suggestedCategory = nil
                return .none

            case let .expiryDateChanged(date):
                state.expiryDate = date
                return .none

            case .showNotesFieldTapped:
                state.showNotesField = true
                return .none

            case let .notesChanged(text):
                state.notes = text
                return .none

            case let .suggestionTapped(suggestion):
                state.name = suggestion.name
                state.unit = suggestion.unit
                if state.foodCategory == nil, let category = suggestion.category {
                    state.foodCategory = category
                }
                state.suggestions = []
                state.duplicateWarning = nil
                return .none

            case let .suggestionsLoaded(suggestions):
                state.suggestions = suggestions
                return .none

            case let .categorySuggested(category):
                // Only set suggested category if user hasn't manually set one
                if state.foodCategory == nil {
                    state.suggestedCategory = category
                }
                return .none

            case .clearSuggestedCategory:
                state.suggestedCategory = nil
                return .none

            case let .duplicateCheckResult(warning):
                state.duplicateWarning = warning
                return .none

            case .submitTapped:
                guard state.isValid else { return .none }
                state.isSubmitting = true

                let input = PantryItemInput(
                    userId: state.userId,
                    name: state.name.trimmingCharacters(in: .whitespaces),
                    quantity: state.quantity,
                    unit: state.unit,
                    storageLocation: state.storageLocation,
                    foodCategory: state.foodCategory,
                    normalizedName: nil,
                    notes: state.notes.isEmpty ? nil : state.notes,
                    source: .manual,
                    expiryDate: state.expiryDate
                )

                return .run { [mode = state.mode, storage = state.storageLocation] send in
                    do {
                        switch mode {
                        case .add:
                            try await pantryClient.addItem(input)
                            // Haptic feedback
                            await MainActor.run {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                            await send(.itemAdded(storage))

                        case let .edit(id):
                            try await pantryClient.updateItem(id, input)
                            await send(.delegate(.itemSaved))
                        }
                    } catch {
                        // TODO: Handle error
                        print("Failed to save item: \(error)")
                    }
                }

            case let .itemAdded(retainStorage):
                // Batch add mode: clear fields but keep storage location
                state.name = ""
                state.quantity = "1"
                state.unit = nil
                state.foodCategory = nil
                state.expiryDate = nil
                state.notes = ""
                state.showNotesField = false
                state.storageLocation = retainStorage
                state.isSubmitting = false
                state.suggestions = []
                state.duplicateWarning = nil
                state.suggestedCategory = nil
                return .none

            case .cancelTapped:
                if state.isDirty {
                    state.confirmDiscard = AlertState {
                        TextState(String(localized: "pantry.add.discard_title", defaultValue: "Discard changes?", bundle: .main))
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDiscard) {
                            TextState(String(localized: "pantry.add.discard_confirm", defaultValue: "Discard", bundle: .main))
                        }
                        ButtonState(role: .cancel) {
                            TextState(String(localized: "pantry.add.discard_cancel", defaultValue: "Cancel", bundle: .main))
                        }
                    } message: {
                        TextState(String(localized: "pantry.add.discard_message", defaultValue: "Your changes will be lost.", bundle: .main))
                    }
                    return .none
                } else {
                    return .send(.delegate(.cancelled))
                }

            case .deleteTapped:
                state.confirmDelete = AlertState {
                    TextState(String(localized: "pantry.edit.delete_title", defaultValue: "Delete \(state.name)?", bundle: .main))
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState(String(localized: "pantry.edit.delete_confirm", defaultValue: "Delete", bundle: .main))
                    }
                    ButtonState(role: .cancel) {
                        TextState(String(localized: "pantry.edit.delete_cancel", defaultValue: "Cancel", bundle: .main))
                    }
                } message: {
                    TextState(String(localized: "pantry.edit.delete_message", defaultValue: "This item will be removed from your pantry.", bundle: .main))
                }
                return .none

            case .alert(.presented(.confirmDiscard)):
                return .send(.delegate(.cancelled))

            case .alert(.presented(.confirmDelete)):
                guard case let .edit(id) = state.mode else { return .none }
                return .run { send in
                    try await pantryClient.deleteItem(id)
                    await send(.delegate(.itemDeleted(id)))
                }

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$confirmDiscard, action: \.alert)
        .ifLet(\.$confirmDelete, action: \.alert)
    }
}
