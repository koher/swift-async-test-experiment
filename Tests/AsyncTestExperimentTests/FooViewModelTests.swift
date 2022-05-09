import XCTest
import AsyncTestExperiment

@MainActor
final class FooViewModelTests: XCTestCase {
    func testLoad() async throws {
        await XCTContext.runActivityAsync(named: "成功") { _ in
            await XCTContext.runActivityAsync(named: "isLoading") { _ in
                let viewModel: FooViewModel<FooService> = .init(id: "abc")

                XCTAssertFalse(viewModel.isLoading)

                async let result: Void = viewModel.load()
                await Task.yield()

                XCTAssertTrue(viewModel.isLoading)

                FooService.fetchFooContinuation?.resume(returning: Foo(id: "abc", value: 42))
                await result

                XCTAssertFalse(viewModel.isLoading)
            }
        }
    }
}

private enum FooService: FooServiceProtocol {
    static var fetchFooContinuation: CheckedContinuation<Foo, Error>?

    static func fetchFoo(for id: Foo.ID) async throws -> Foo {
        try await withCheckedThrowingContinuation { continuation in
            fetchFooContinuation = continuation
        }
    }
}
