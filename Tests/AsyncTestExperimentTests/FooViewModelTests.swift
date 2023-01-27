import XCTest
import Combine
import AsyncTestExperiment

@MainActor
final class FooViewModelTests: XCTestCase {
    func testLoad() async throws {
        await XCTContext.runActivityAsync(named: "成功") { _ in
            await XCTContext.runActivityAsync(named: "isLoading") { _ in
                let viewModel: FooViewModel<FooService> = .init(id: "abc")

                XCTAssertFalse(viewModel.isLoading)

                async let result: Void = viewModel.load()

                while FooService.fetchFooContinuation == nil {
                    await Task.yield()
                }

                XCTAssertTrue(viewModel.isLoading)

                FooService.fetchFooContinuation!.resume(returning: Foo(id: "abc", value: 42))
                FooService.fetchFooContinuation = nil
                await result

                XCTAssertFalse(viewModel.isLoading)
            }

            await XCTContext.runActivityAsync(named: "loadSuccess") { _ in
                let viewModel: FooViewModel<FooService> = .init(id: "abc")
                var cancellables: Set<AnyCancellable> = []

                var loadSuccessCount = 0
                viewModel.loadSuccess
                    .sink { _ in
                        loadSuccessCount += 1
                    }
                    .store(in: &cancellables)

                XCTAssertEqual(loadSuccessCount, 0)

                async let result: Void = viewModel.load()

                while FooService.fetchFooContinuation == nil {
                    await Task.yield()
                }

                XCTAssertEqual(loadSuccessCount, 0)

                FooService.fetchFooContinuation!.resume(returning: Foo(id: "abc", value: 42))
                FooService.fetchFooContinuation = nil
                await result

                XCTAssertEqual(loadSuccessCount, 1)
            }
        }

        await XCTContext.runActivityAsync(named: "失敗") { _ in
            await XCTContext.runActivityAsync(named: "isLoading") { _ in
                let viewModel: FooViewModel<FooService> = .init(id: "abc")

                XCTAssertFalse(viewModel.isLoading)

                async let result: Void = viewModel.load()

                while FooService.fetchFooContinuation == nil {
                    await Task.yield()
                }

                XCTAssertTrue(viewModel.isLoading)

                FooService.fetchFooContinuation!.resume(throwing: GeneralError(value: -1))
                FooService.fetchFooContinuation = nil
                await result

                XCTAssertFalse(viewModel.isLoading)
            }

            await XCTContext.runActivityAsync(named: "loadFailure") { _ in
                let viewModel: FooViewModel<FooService> = .init(id: "abc")
                var cancellables: Set<AnyCancellable> = []

                var loadFailureCount = 0
                viewModel.loadFailure
                    .sink { _ in
                        loadFailureCount += 1
                    }
                    .store(in: &cancellables)

                XCTAssertEqual(loadFailureCount, 0)

                async let result: Void = viewModel.load()

                while FooService.fetchFooContinuation == nil {
                    await Task.yield()
                }

                XCTAssertEqual(loadFailureCount, 0)

                FooService.fetchFooContinuation!.resume(throwing: GeneralError(value: -1))
                FooService.fetchFooContinuation = nil
                await result

                XCTAssertEqual(loadFailureCount, 1)
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
