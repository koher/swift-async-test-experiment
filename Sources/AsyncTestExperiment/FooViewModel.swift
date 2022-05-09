import Combine

@MainActor
public final class FooViewModel<FooService: FooServiceProtocol>: ObservableObject {
    public let id: Foo.ID

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var foo: Foo?
    @Published public private(set) var error: Error?

    private let _loadSuccess: PassthroughSubject<Void, Never> = .init()
    public var loadSuccess: AnyPublisher<Void, Never> { _loadSuccess.eraseToAnyPublisher() }

    private let _loadFailure: PassthroughSubject<Void, Never> = .init()
    public var loadFailure: AnyPublisher<Void, Never> { _loadFailure.eraseToAnyPublisher() }

    public init(id: Foo.ID) {
        self.id = id
    }

    public func load() async {
        isLoading = true
        do {
            foo = try await FooService.fetchFoo(for: id)
            isLoading = false
            _loadSuccess.send()
        } catch  {
            isLoading = false
            self.error = error
            _loadFailure.send()
        }
    }
}
