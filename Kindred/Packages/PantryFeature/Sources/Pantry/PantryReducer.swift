import ComposableArchitecture
import Foundation

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

        // Group items by storage location for list display with search filter and alphabetical sort
        public var fridgeItems: [PantryItemState] {
            items
                .filter { $0.storageLocation == .fridge }
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
        public var freezerItems: [PantryItemState] {
            items
                .filter { $0.storageLocation == .freezer }
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
        public var pantryItems: [PantryItemState] {
            items
                .filter { $0.storageLocation == .pantry }
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
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
                return .send(.onAppear)

            case .addEditForm(.presented(.delegate(.cancelled))):
                state.addEditForm = nil
                return .send(.onAppear)

            case let .addEditForm(.presented(.delegate(.itemDeleted(id)))):
                state.addEditForm = nil
                state.items.remove(id: id)
                return .send(.onAppear)

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

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$addEditForm, action: \.addEditForm) {
            AddEditItemReducer()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
