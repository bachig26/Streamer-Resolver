import Foundation

public struct MediaContentSection: Codable, Identifiable, Comparable, Hashable {
    public var id: String {
        title
    }

    public static func < (lhs: MediaContentSection, rhs: MediaContentSection) -> Bool {
        lhs.title < lhs.title
    }

    public let title: String
    public let media: [MediaContent]

    init(title: String, media: [MediaContent]) {
        self.title = title
        self.media = media
    }
}

public struct MediaContent: Codable, Identifiable, Comparable, Hashable {
    public enum MediaContentType: String, Codable {
        case tvShow
        case movie
    }

    public let title: String
    public let webURL: URL
    public let posterURL: URL
    public let type: MediaContentType
    public let provider: ProviderType?

    public init(title: String, webURL: URL, posterURL: URL, type: MediaContent.MediaContentType, provider: ProviderType? = nil) {
        self.title = title
        self.webURL = webURL
        self.posterURL = posterURL
        self.type = type
        self.provider = provider
    }
}

extension MediaContent {
    public var id: String {
        return webURL.absoluteString.base64Encoded() ?? ""
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.title < rhs.title
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var deeplink: URL? {
        guard  let data = try? JSONEncoder().encode(self),
               let content = String(data: data, encoding: .utf8)?.base64Encoded(),
               let url = URL(string: "streamer://details?content=\(content)") else {
            return nil
        }
        return url
    }

}

public extension MediaContent {
    init(tvShow: TVshow, provider: ProviderType? = nil) {
        self.title = tvShow.title
        self.webURL = tvShow.webURL
        self.posterURL = tvShow.posterURL
        self.type = .tvShow
        self.provider = provider
    }

    init(movie: Movie, provider: ProviderType? = nil) {
        self.title = movie.title
        self.webURL = movie.webURL
        self.posterURL = movie.posterURL
        self.type = .movie
        self.provider = provider
    }

}
