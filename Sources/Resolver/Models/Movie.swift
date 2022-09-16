import Foundation

public struct Movie: Codable, Identifiable, Comparable, Hashable {
    public let id: String
    public let title: String
    public let webURL: URL
    public let posterURL: URL
    public let sources: [Source]?
    public let subtitles: [Subtitle]?

    public init(title: String, webURL: URL, posterURL: URL, sources: [Source]? = nil, subtitles: [Subtitle]? = nil) {
        self.id = webURL.absoluteString.base64Encoded() ?? ""
        self.title = title
        self.webURL = webURL
        self.posterURL = posterURL
        self.sources = sources
        self.subtitles = subtitles
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
