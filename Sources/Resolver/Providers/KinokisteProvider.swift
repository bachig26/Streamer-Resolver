import Foundation
import SwiftSoup

public class KinokisteProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "de_DE")
    }

    public var type: ProviderType = .kinokiste

    public let title: String = "KinoKiste"
    public let langauge: String = "🇩🇪"
    public var subtitle: String = "German content"
    public let moviesURL: URL = URL(staticString: "https://api.kinokiste.club/data/browse/?lang=2&type=movies")
    public let tvShowsURL: URL = URL(staticString: "https://api.kinokiste.club/data/browse/?lang=2&type=tvseries")
    public let baseURL = URL(staticString: "https://kinokiste.club")

    let posterBaseURL = URL(staticString: "https://image.tmdb.org/t/p/w342/")

    public init() {}

    enum KinokisteProvider: Error {
        case idNotFound
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.requestData(url: url)
        let response = try JSONCoder.decoder.decode(KinoResponse.self, from: content)
        return response.movies.map { movie in

            //https://streamcloud.at/{id}/{original_title}/{season}
            let url = baseURL.appending("id", value: movie._id).appending("title", value: movie.original_title ?? movie.title)
            let title: String = movie.title
            let posterURL = posterBaseURL.appendingPathComponent(movie.poster_path)
            let type: MediaContent.MediaContentType = movie.tv == 1 ? .tvShow :  .movie
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: .kinokiste)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("order_by", value: "releases").appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("order_by", value: "releases").appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        guard let _id = url.queryParameters?["id"] else {
            throw KinokisteProvider.idNotFound
        }

        let requestURL = URL(staticString: "https://api.kinokiste.club/data/watch/").appending("_id", value: _id)
        let content = try await Utilities.requestData(url: requestURL)
        let response = try JSONCoder.decoder.decode(KinoDetails.self, from: content)
        let sources = response.streams.sorted {
            $0.added > $1.added
        }.prefix(20).compactMap { $0.stream }.map { Source(hostURL: $0)}
        let posterURL = posterBaseURL.appendingPathComponent(response.poster_path)
        return Movie(title: response.original_title ?? response.title, webURL: url, posterURL: posterURL, sources: Array(sources))

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {

        //https://streamcloud.at/{id}/{original_title}
        guard let _id = url.queryParameters?["id"] else {
            throw KinokisteProvider.idNotFound
        }

        let requestURL = URL(staticString: "https://api.kinokiste.club/data/watch/").appending("_id", value: _id)
        let content = try await Utilities.requestData(url: requestURL)
        let response = try JSONCoder.decoder.decode(KinoDetails.self, from: content)

        guard let original_title = url.queryParameters?["title"] else {
            throw KinokisteProvider.idNotFound
        }
        let seasonsURL = URL(staticString: "https://api.kinokiste.club/data/seasons/?lang=2").appending("original_title", value: original_title)
        let seasonsData = try await Utilities.requestData(url: seasonsURL)

        let seasonsResponse = try JSONCoder.decoder.decode([KinoDetails].self, from: seasonsData)

        let seasons = seasonsResponse.map { seasonResponse -> Season in
            let episodesNumber = seasonResponse.streams
                .compactMap { $0.e }
                .uniqued()

            let episodes = episodesNumber.map { ep -> Episode in
                let sources = seasonResponse.streams.filter { $0.e == ep}.compactMap { $0.stream }.map { Source(hostURL: $0)}
                return Episode(number: ep, sources: sources)
            }
            return Season(seasonNumber: seasonResponse.s ?? 1, webURL: url, episodes: episodes)
        }

        let posterURL = posterBaseURL.appendingPathComponent(response.poster_path)
        return TVshow(title: response.original_title ?? response.title, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let url = URL(staticString: "https://api.kinokiste.club/data/browse/?lang=2")
            .appending("keyword", value: keyword.replacingOccurrences(of: " ", with: "+"))
            .appending("page", value: String(page))
        return try await parsePage(url: url)

    }

    public func home() async throws -> [MediaContentSection] {
        let trendingMovies =  try await parsePage(url: moviesURL.appending("order_by", value: "trending").appending("page", value: "1"))
        let trendingTVShows =  try await parsePage(url: tvShowsURL.appending("order_by", value: "trending").appending("page", value: "1"))
        return [.init(title: "Trending Filme", media: trendingMovies), .init(title: "Trending Serien", media: trendingTVShows)]
    }

    // MARK: - Welcome
    struct KinoResponse: Decodable {
        @FailableDecodableArray var movies: [KinoMovie]
    }

    // MARK: - Movie
    struct KinoMovie: Decodable {
        var _id: String
        var tv: Int
        var title: String
        var original_title: String?
        var poster_path: String
        var streams: [KinoStream]
    }

    // MARK: - Welcome
    struct KinoDetails: Decodable {
        var s: Int?
        var title: String
        var original_title: String?
        var poster_path: String
        @FailableDecodableArray var streams: [KinoStream]
    }

    // MARK: - Stream
    struct KinoStream: Decodable {
        var stream: URL?
        var e: Int?
        var added: Date
    }

}
