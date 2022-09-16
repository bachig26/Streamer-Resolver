import Foundation

/// Property wrapper to be used in arrays where, during the decode process, we don't want to fail the whole array if an element is invalid.
@propertyWrapper
public struct FailableDecodableArray<Element: Decodable>: Decodable {
    public var wrappedValue: [Element]

    private struct ElementWrapper: Decodable {
        var element: Element?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                element = try container.decode(Element.self)
            } catch {
                element = nil
                print("FailableDecodableArray - Invalid element: \(error)")
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let wrappers = try container.decode([ElementWrapper].self)
        self.wrappedValue = wrappers.compactMap(\.element)
    }

    public init(wrappedValue: [Element]) {
        self.wrappedValue = wrappedValue
    }
}
