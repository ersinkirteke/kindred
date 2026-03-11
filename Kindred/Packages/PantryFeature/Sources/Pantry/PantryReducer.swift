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

        // Group items by storage location for list display
        public var fridgeItems: [PantryItemState] {
            items.filter { $0.storageLocation == .fridge }
        }
        public var freezerItems: [PantryItemState] {
            items.filter { $0.storageLocation == .freezer }
        }
        public var pantryItems: [PantryItemState] {
            items.filter { $0.storageLocation == .pantry }
        }

        public init() {}
    }

    public enum Action {
        case onAppear
        case itemsLoaded([PantryItem])
        case expiringCountLoaded(Int)
        case addItemTapped
        case deleteItem(UUID)
        case itemDeleted
        case authStateUpdated(String?)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {}

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
                guard state.userId != nil else {
                    return .send(.delegate(.authGateRequested))
                }
                // Phase 13 will implement full AddItem flow
                state.alert = AlertState {
                    TextState(String(localized: "pantry.coming_soon_title", bundle: .main))
                } message: {
                    TextState(String(localized: "pantry.coming_soon_message", bundle: .main))
                }
                return .none

            case .alert:
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
        .ifLet(\.$alert, action: \.alert)
    }
}
