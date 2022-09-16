import Foundation

public struct TVshow: Codable, Identifiable, Comparable, Hashable {

    public let id: String
    public let title: String
    public let webURL: URL
    public let posterURL: URL
    public let overview: String?
    public let trailer: URL?
    public let actors: [Actor]?
    public let seasons: [Season]?

    public init(title: String, webURL: URL, posterURL: URL, overview: String? = nil, trailer: URL? = nil, seasons: [Season]? = nil, actors: [Actor]? = nil) {
        self.id = webURL.absoluteString.base64Encoded() ?? ""
        self.title = title
        self.webURL = webURL
        self.posterURL = posterURL
        self.overview = overview
        self.seasons = seasons
        self.trailer = trailer
        self.actors = actors
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.title < rhs.title
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.webURL == rhs.webURL
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(webURL)
        hasher.combine(posterURL)
    }
}

public struct Actor: Codable {
    public let name: String
    public let profileURL: URL?

}
