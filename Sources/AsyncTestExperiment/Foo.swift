public struct Foo: Identifiable, Sendable {
    public let id: ID
    public var value: Int

    public init(id: ID, value: Int) {
        self.id = id
        self.value = value
    }

    public struct ID: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }
    }
}
