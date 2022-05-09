public protocol FooServiceProtocol {
    static func fetchFoo(for id: Foo.ID) async throws -> Foo
}
