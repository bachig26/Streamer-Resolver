import Foundation

public struct Episode: Codable, Comparable, Identifiable, Hashable {
    public var id: Int { number }
    public let number: Int
    public let screenshot: URL?
    public var sources: [Source]?
    public var subtitles: [Subtitle]?

    public init(number: Int, screenshot: URL? = nil, sources: [Source]? = nil, subtitles: [Subtitle]? = nil) {
        self.number = number
        self.sources = sources
        self.subtitles = subtitles
        self.screenshot = screenshot
    }

    public static func <(lhs: Episode, rhs: Episode) -> Bool {
        lhs.number < rhs.number
    }

    public static func == (lhs: Episode, rhs: Episode) -> Bool {
        lhs.number == rhs.number
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }

}
