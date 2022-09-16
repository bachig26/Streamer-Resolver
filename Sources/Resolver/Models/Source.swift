import Foundation

public struct Source: Codable, Hashable {
    public let id: String
    public let hostURL: URL
    public init(hostURL: URL) {
        self.id = hostURL.absoluteString.toBase64URL()
        self.hostURL = hostURL
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hostURL)
    }
}
