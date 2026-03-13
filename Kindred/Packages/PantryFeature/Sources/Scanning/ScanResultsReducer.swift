import ComposableArchitecture
import Dependencies
import Foundation
import SwiftUI

@Reducer
public struct ScanResultsReducer {
    @ObservableState
    public struct State: Equatable {
        public var userId: String
        public var scanType: ScanType
        public var photoUrl: String?
        public var detectedItems: IdentifiedArrayOf<DetectedItemState>
        public var isAdding: Bool = false
        public var addSuccess: Bool = false
        public var addedCount: Int = 0
        public var errorMessage: String?
        public var isAddingNewItem: Bool = false
        public var newItemName: String = ""

        public var checkedCount: Int {
            detectedItems.filter(\.isChecked).count
        }

        public init(
            userId: String,
            scanType: ScanType,
            photoUrl: String?,
            detectedItems: [DetectedItem]
        ) {
            self.userId = userId
            self.scanType = scanType
            self.photoUrl = photoUrl
            self.detectedItems = IdentifiedArray(
                uniqueElements: detectedItems.map { DetectedItemState(from: $0) }
            )
        }
    }

    @ObservableState
    public struct DetectedItemState: Equatable, Identifiable {
        public let id: UUID
        public var name: String
        public var quantity: String
        public var category: FoodCategory
        public var storageLocation: StorageLocation
        public var estimatedExpiryDays: Int
        public var confidence: Int
        public var isChecked: Bool
        public var isEditing: Bool = false

        public var badgeColor: Color {
            if confidence >= 90 {
                return .green
            } else if confidence >= 70 {
                return .yellow
            } else {
                return .red
            }
        }

        public init(from detectedItem: DetectedItem) {
            self.id = detectedItem.id
            self.name = detectedItem.name
            self.quantity = detectedItem.quantity
            self.category = detectedItem.category
            self.storageLocation = detectedItem.storageLocation
            self.estimatedExpiryDays = detectedItem.estimatedExpiryDays
            self.confidence = detectedItem.confidence
            // Auto-check items with confidence >= 70
            self.isChecked = detectedItem.confidence >= 70
        }

        public init(
            id: UUID = UUID(),
            name: String,
            quantity: String,
            category: FoodCategory,
            storageLocation: StorageLocation,
            estimatedExpiryDays: Int,
            confidence: Int,
            isChecked: Bool = true,
            isEditing: Bool = false
        ) {
            self.id = id
            self.name = name
            self.quantity = quantity
            self.category = category
            self.storageLocation = storageLocation
            self.estimatedExpiryDays = estimatedExpiryDays
            self.confidence = confidence
            self.isChecked = isChecked
            self.isEditing = isEditing
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case itemToggled(id: UUID)
        case itemEditTapped(id: UUID)
        case itemFieldChanged(id: UUID, name: String?, quantity: String?, category: FoodCategory?, storageLocation: StorageLocation?)
        case itemRemoved(id: UUID)
        case addNewItemTapped
        case newItemConfirmed
        case bulkAddTapped
        case bulkAddCompleted(Result<Int, Error>)
        case dismissTapped
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case itemsAdded(count: Int, itemNames: [String])
        case dismissed
    }

    @Dependency(\.pantryClient) var pantryClient

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .itemToggled(id):
                state.detectedItems[id: id]?.isChecked.toggle()
                return .none

            case let .itemEditTapped(id):
                state.detectedItems[id: id]?.isEditing.toggle()
                return .none

            case let .itemFieldChanged(id, name, quantity, category, storageLocation):
                guard var item = state.detectedItems[id: id] else { return .none }
                if let name = name {
                    item.name = name
                }
                if let quantity = quantity {
                    item.quantity = quantity
                }
                if let category = category {
                    item.category = category
                }
                if let storageLocation = storageLocation {
                    item.storageLocation = storageLocation
                }
                state.detectedItems[id: id] = item
                return .none

            case let .itemRemoved(id):
                state.detectedItems.remove(id: id)
                return .none

            case .addNewItemTapped:
                state.isAddingNewItem = true
                state.newItemName = ""
                return .none

            case .newItemConfirmed:
                guard !state.newItemName.trimmingCharacters(in: .whitespaces).isEmpty else {
                    state.isAddingNewItem = false
                    return .none
                }

                let newItem = DetectedItemState(
                    name: state.newItemName.trimmingCharacters(in: .whitespaces),
                    quantity: "1",
                    category: .produce,
                    storageLocation: state.scanType == .fridge ? .fridge : .pantry,
                    estimatedExpiryDays: 7,
                    confidence: 100,
                    isChecked: true,
                    isEditing: true
                )
                state.detectedItems.append(newItem)
                state.isAddingNewItem = false
                state.newItemName = ""
                return .none

            case .bulkAddTapped:
                state.isAdding = true
                state.errorMessage = nil

                let checkedItems = state.detectedItems.filter(\.isChecked)
                guard !checkedItems.isEmpty else {
                    state.isAdding = false
                    return .none
                }

                let userId = state.userId
                let source: ItemSource = state.scanType == .fridge ? .fridgeScan : .receiptScan

                let inputs = checkedItems.map { item -> PantryItemInput in
                    let expiryDate = Calendar.current.date(
                        byAdding: .day,
                        value: item.estimatedExpiryDays,
                        to: Date()
                    )

                    return PantryItemInput(
                        userId: userId,
                        name: item.name,
                        quantity: item.quantity,
                        unit: nil,
                        storageLocation: item.storageLocation,
                        foodCategory: item.category,
                        normalizedName: nil,
                        notes: nil,
                        source: source,
                        expiryDate: expiryDate
                    )
                }

                let itemNames = checkedItems.map(\.name)

                return .run { send in
                    do {
                        let count = try await pantryClient.bulkAddScannedItems(userId, inputs)
                        // Trigger success haptic on main actor
                        await MainActor.run {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        await send(.bulkAddCompleted(.success(count)))
                    } catch {
                        await send(.bulkAddCompleted(.failure(error)))
                    }
                }

            case let .bulkAddCompleted(.success(count)):
                state.isAdding = false
                state.addSuccess = true
                state.addedCount = count
                let itemNames = state.detectedItems.filter(\.isChecked).map(\.name)
                return .send(.delegate(.itemsAdded(count: count, itemNames: itemNames)))

            case let .bulkAddCompleted(.failure(error)):
                state.isAdding = false
                state.errorMessage = error.localizedDescription
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
