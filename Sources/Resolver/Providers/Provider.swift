import Foundation

public protocol Provider {
    var locale: Locale { get }
    var type: ProviderType { get }
    var title: String { get }
    var langauge: String { get }
    var subtitle: String { get }
    var baseURL: URL { get }
    var moviesURL: URL { get }
    var tvShowsURL: URL { get }

    func latestMovies(page: Int) async throws -> [MediaContent]
    func latestTVShows(page: Int) async throws -> [MediaContent]
    func fetchMovieDetails(for url: URL) async throws -> Movie
    func fetchTVShowDetails(for url: URL) async throws -> TVshow
    func fetchStream(for source: Source) async throws -> [Stream]
    func search(keyword: String, page: Int) async throws -> [MediaContent]
    func home() async throws -> [MediaContentSection]

}

extension Provider {
    public var locale: Locale {
        return Locale(identifier: "en_US_POSIX")
    }
    public func home() async throws -> [MediaContentSection] {
        return []
    }
    public func fetchStream(for source: Source) async throws -> [Stream] {
        return try await HostsResolver.resloveURL(url: source.hostURL)
    }

}

public enum ProviderError: Error, Equatable {
    case noContent
    case wrongURL
}

public enum ProviderType: String, Codable, CaseIterable {

    case flixtor
    case movie123
    case sflix
    case mediabox
    case akwam
    case fmoviesTo
    case cimaNow
    case kinokiste
    case seriesYonkis
    case pelisflix
    case flix
    case zoro = "zoro"
    case streamingCommunity
    public var provider: Provider {
        switch self {
        case .akwam:
            return AkwamProvider()
        case .flixtor:
            return FlixtorProvider(title: "Flixtor.video", baseURL: .init(staticString: "https://flixtor.video"), type: .flixtor)
        case .sflix:
            return FlixtorProvider(title: "Sflix.pro", baseURL: .init(staticString: "https://sflix.pro"), type: .sflix)
        case .fmoviesTo:
            return FlixtorProvider(title: "Fmovies.to", baseURL: .init(staticString: "https://fmovies.to"), type: .fmoviesTo)
        case .flix:
            return FlixProvider()
        case .cimaNow:
            return CimaNowProvider()
        case .movie123:
            return Movie123Provider()
        case .kinokiste:
            return KinokisteProvider()
        case .streamingCommunity:
            return StreamingCommunityProvider()
        case .zoro:
            return ZoroAnimeProvider()
        case .seriesYonkis:
            return SeriesYonkisProvider()
        case .pelisflix:
            return PelisflixProvider()
        case .mediabox:
            return MediaBoxProvider()
        }

    }
}
