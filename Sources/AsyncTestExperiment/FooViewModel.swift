import Combine

@MainActor
public final class FooViewModel<FooService: FooServiceProtocol>: ObservableObject {
    public let id: Foo.ID

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var foo: Foo?
    @Published public private(set) var error: Error?

    public init(id: Foo.ID) {
        self.id = id
    }

    public func load() async {
        isLoading = true
        do {
            foo = try await FooService.fetchFoo(for: id)
            isLoading = false
        } catch  {
            isLoading = false
            self.error = error
        }
    }
}
