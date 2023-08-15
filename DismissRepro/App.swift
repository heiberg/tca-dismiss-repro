import ComposableArchitecture
import SwiftUI

let store = Store(
    initialState: Root.State(),
    reducer: Root.init
)

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}

// MARK: - Root

struct Root: Reducer {
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
    }
    
    enum Action: Equatable {
        case presentChild
        case destination(PresentationAction<Destination.Action>)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .presentChild:
                state.destination = .child(.init(destination: .firstGrandchild(.init())))
                return .none
            case .destination:
                return .none
            }
        }.ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }._printChanges()
    }
    
    struct Destination: Reducer {
        enum State: Equatable {
            case child(Child.State)
        }
        
        enum Action: Equatable {
            case child(Child.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.child, action: /Action.child) {
                Child()
            }
        }
    }
}

struct RootView: View {
    let store: StoreOf<Root>
    
    var body: some View {
        let destinationStore = store.scope(
            state: \.$destination,
            action: Root.Action.destination
        )
        
        VStack {
            Text("Root")
                .font(.headline)

            Button("Present Child") {
                store.send(.presentChild)
            }
        }
        .sheet(
            store: destinationStore,
            state: /Root.Destination.State.child,
            action: Root.Destination.Action.child,
            content: ChildView.init
        )
    }
}

// MARK: - Child

struct Child: Reducer {
    struct State: Equatable {
        @PresentationState var destination: Destination.State?
        
        init(destination: Destination.State?) {
            self.destination = destination
        }
    }
    
    enum Action: Equatable {
        case presentFirstGrandchild
        case presentSecondGrandchild
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .presentFirstGrandchild:
                state.destination = .firstGrandchild(.init())
                return .none
            case .presentSecondGrandchild:
                state.destination = .secondGrandchild(.init())
                return .none
            case .destination(.dismiss):
                switch state.destination {
                case .firstGrandchild:
                    return .run { send in
//                        try await Task.sleep(for: .seconds(2))
                        await send(.presentSecondGrandchild)
                    }
                case .secondGrandchild:
                    return .none
                case .none:
                    return .none
                }
            case .destination(.presented):
                return .none
            }
        }.ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
    
    struct Destination: Reducer {
        enum State: Equatable {
            case firstGrandchild(FirstGrandchild.State)
            case secondGrandchild(SecondGrandchild.State)
        }
        
        enum Action: Equatable {
            case firstGrandchild(FirstGrandchild.Action)
            case secondGrandchild(SecondGrandchild.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.firstGrandchild, action: /Action.firstGrandchild) {
                FirstGrandchild()
            }
            Scope(state: /State.secondGrandchild, action: /Action.secondGrandchild) {
                SecondGrandchild()
            }
        }
    }
}

struct ChildView: View {
    let store: StoreOf<Child>
    
    var body: some View {
        let destinationStore = store.scope(
            state: \.$destination,
            action: Child.Action.destination
        )
        
        VStack {
            Text("Child")
                .font(.headline)
        }
        .sheet(
            store: destinationStore,
            state: /Child.Destination.State.firstGrandchild,
            action: Child.Destination.Action.firstGrandchild,
            content: FirstGrandchildView.init
        )
        .sheet(
            store: destinationStore,
            state: /Child.Destination.State.secondGrandchild,
            action: Child.Destination.Action.secondGrandchild,
            content: SecondGrandchildView.init
        )
    }
}

// MARK: - First Grandchild

struct FirstGrandchild: Reducer {
    struct State: Equatable {}
    
    enum Action: Equatable {
        case task
        case tappedDismiss
    }
    
    @Dependency(\.dismiss) var dismiss
    
    enum CancelID {
        case task
    }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .none
            case .tappedDismiss:
                return .run { _ in await dismiss() }
            }
        }
    }
}

struct FirstGrandchildView: View {
    let store: StoreOf<FirstGrandchild>
    
    var body: some View {
        VStack {
            Text("First Grandchild")
                .font(.headline)
            
            Button("Dismiss") {
                store.send(.tappedDismiss)
            }
        }
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - Second Grandchild

struct SecondGrandchild: Reducer {
    struct State: Equatable {}
    
    enum Action: Equatable {
        case tappedDismiss
    }
    
    @Dependency(\.dismiss) var dismiss
    
    enum CancelID {
        case task
    }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tappedDismiss:
                return .run { _ in await dismiss() }
            }
        }
    }
}

struct SecondGrandchildView: View {
    let store: StoreOf<SecondGrandchild>
    
    var body: some View {
        VStack {
            Text("Second Grandchild")
                .font(.headline)
            
            Button("Dismiss") {
                store.send(.tappedDismiss)
            }
        }
    }
}
