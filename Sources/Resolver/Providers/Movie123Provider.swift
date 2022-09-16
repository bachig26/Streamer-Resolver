import Foundation
import SwiftSoup

public class Movie123Provider: Provider {
    public var type: ProviderType = .movie123

    public let title: String = "123moviesfree.so"
    public let langauge: String = "🇺🇸"
    public var subtitle: String = "English content with english subtitles. Fast updating"
    public let moviesURL: URL = URL(staticString: "https://123moviesfree.so/movie/filter/movie/all/all/all/all/latest/")
    public let tvShowsURL: URL = URL(staticString: "https://123moviesfree.so/movie/filter/series/all/all/all/all/latest/")
    public let baseURL = URL(staticString: "https://123moviesfree.so")
    private let subtitleBaseURL = URL(staticString: "https://sub.movie-series.net")
    private let homeURL = URL(staticString: "https://123moviesfree.so/123movies")
    public init() {}

    enum Movie123ProviderError: Error {
        case posterURLNotFound
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("div.ml-item > a")
        return try rows.array().map { row in
            let path: String = try row.attr("href")
            let url = baseURL.appendingPathComponent(path)
            let title: String = try row.attr("title")
            let posterPath: String = try row.select("img").attr("data-original")
            let posterURL = URL(string: "https:\(posterPath)")!
            let latestEpisodeNumber = try row.select(".mli-eps").text()
            let type: MediaContent.MediaContentType = latestEpisodeNumber.isEmpty ? .movie :  .tvShow
            return MediaContent(title: title, webURL: url, posterURL: posterURL, type: type, provider: .movie123)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let pageURL = url.appendingPathComponent("watching.html")
        let content = try await Utilities.downloadPage(url: pageURL)
        let document = try SwiftSoup.parse(content)
        let title = try document.select(".mvic-desc > h3").html()
        let posterPath = try document.select("[property=og:image]").first()?.attr("content") ?? ""
        let rows: Elements = try document.select("[player-data]")
        let sources = try rows.array().compactMap { row -> Source? in
            var path: String = try row.attr("player-data")
            if !path.hasPrefix("https") {
                path = "https:" + path
            }
            guard let url = URL(string: path) else {
                return nil
            }
            return Source(hostURL: url)
        }

        var subtitles: [Subtitle] = []
        if let subtitlePath = try rows.first()?.attr("sub-dow"), !subtitlePath.isEmpty {
            let subtitleURL = subtitleBaseURL.appendingPathComponent(subtitlePath)
            subtitles.append(Subtitle(url: subtitleURL, language: .english))
        }

        guard let posterURL = URL(string: "https:" + posterPath) else {
            throw Movie123ProviderError.posterURLNotFound
        }

        return Movie(title: title, webURL: url, posterURL: posterURL, sources: sources, subtitles: subtitles)

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageURL = url.appendingPathComponent("watching.html")
        let content = try await Utilities.downloadPage(url: pageURL)
        let document = try SwiftSoup.parse(content)
        let details = try document.select(".mvic-desc > h3").text()
        let components = details.components(separatedBy: "-")
        let title = components.dropLast().joined(separator: "-").trimmingCharacters(in: .whitespaces)
        let seasonNumber = components.last?.replacingOccurrences(of: "Season", with: "").trimmingCharacters(in: .whitespaces) ?? ""
        let posterPath = try document.select("[property=og:image]").first()?.attr("content") ?? ""

        let episodesRows: Elements = try document.select("[episode-data]")
        var episodes = try episodesRows.array().map { epRow -> Episode in
            let number: String = try epRow.attr("episode-data")
            return Episode(number: Int(number) ?? 1)
        }.unique().sorted()

        let rows: Elements = try document.select("[player-data]")
        try rows.array().forEach { row in
            let number: String = try row.attr("episode-data")
            var path: String = try row.attr("player-data")
            if !path.hasPrefix("https") {
                path = "https:" + path
            }
            guard let url = URL(string: path),
                  let episodeNumber = Int(number),
                  let episodeIndex = episodes.firstIndex(where: { $0.number == episodeNumber }) else {
                return
            }
            let subtitlePath = try row.attr("sub-dow")
            if !subtitlePath.isEmpty {
                let subtitleURL = subtitleBaseURL.appendingPathComponent(subtitlePath)
                episodes[episodeIndex].subtitles = [Subtitle(url: subtitleURL, language: .english)]
            }
            if episodes[episodeIndex].sources == nil {
                episodes[episodeIndex].sources = []
            }
            episodes[episodeIndex].sources?.append(Source(hostURL: url))

        }

        let season = Season(seasonNumber: Int(seasonNumber) ?? 1, webURL: url, episodes: episodes)
        guard let posterURL = URL(string: "https:" + posterPath) else {
            throw Movie123ProviderError.posterURLNotFound
        }
        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: [season])
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "-")
        let pageURL = baseURL.appendingPathComponent("/movie/search/\(keyword)").appending("page", value: "\(page)")
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 64 else {
            return []
        }

        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Cinema Movies", comment: ""), media: Array(items.prefix(16)))
        items.removeFirst(16)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("Featued Series", comment: ""), media: Array(items.prefix(16)))
        items.removeFirst(16)
        let trending = MediaContentSection(title: NSLocalizedString("Top IMDB", comment: ""), media: Array(items.prefix(16)))
        items.removeFirst(16)
        let latestMovies = MediaContentSection(title: NSLocalizedString("Latest Movies", comment: ""), media: Array(items.prefix(16)))
        items.removeFirst(16)
        let latestTVSeries = MediaContentSection(title: NSLocalizedString("Latest TV Series", comment: ""), media: items)
        return [recommendedMovies, recommendedTVShows, trending, latestMovies, latestTVSeries]
    }

}
