import Foundation

public struct Subtitle: Codable, Hashable, Identifiable {

    public var id: String { url.absoluteString }
    public let url: URL
    public let language: SubtitlesLangauge

    public init(url: URL, language: SubtitlesLangauge) {
        self.url = url
        self.language = language
    }

}
