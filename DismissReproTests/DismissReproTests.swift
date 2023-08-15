@testable import DismissRepro
import ComposableArchitecture
import XCTest

@MainActor
final class DismissReproTests: XCTestCase {
    func testNestedDismissal() async throws {
        let store = TestStore(
            initialState: Root.State.init(),
            reducer: Root.init
        )

        await store.send(.presentChild) {
            $0.destination = .child(.init(destination: .firstGrandchild(.init())))
        }

        let task = await store.send(.destination(.presented(.child(.destination(.presented(.firstGrandchild(.task)))))))

        await store.send(.destination(.presented(.child(.destination(.presented(.firstGrandchild(.tappedDismiss)))))))
        
        await task.cancel()

        await store.receive(.destination(.presented(.child(.destination(.dismiss))))) {
            $0.destination = .child(.init(
                destination: nil
            ))
        }

        await store.receive(.destination(.presented(.child(.presentSecondGrandchild)))) {
            $0.destination = .child(.init(
                destination: .secondGrandchild(.init())
            ))
        }
        
        await store.send(.destination(.presented(.child(.destination(.presented(.secondGrandchild(.tappedDismiss)))))))

        await store.receive(.destination(.presented(.child(.destination(.dismiss))))) {
            $0.destination = .child(.init(
                destination: nil
            ))
        }
    }
}
