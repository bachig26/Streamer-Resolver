import Foundation
import SwiftSoup

public class SeriesYonkisProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "es_ES")
    }

    public var type: ProviderType = .seriesYonkis

    public var title: String = "SeriesYonkis.io"
    public let langauge: String = "🇪🇸"
    public var subtitle: String = "Spanish content"

    public var moviesURL: URL = URL(staticString: "https://seriesyonkis.nu/peliculas/")
    public var tvShowsURL: URL = URL(staticString: "https://seriesyonkis.nu/")
    public var homeURL: URL = URL(staticString: "https://seriesyonkis.nu")
    public let baseURL: URL = URL(staticString: "https://seriesyonkis.nu")

    public init() { }

    enum SeriesYonkisProviderError: Error {
        case missingMovieInformation
    }
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".MovieList .TPostMv > article > a")
        return try rows.array().map { row in
            let url = try row.attr("href")
            let title: String = try row.select("h3").text()
            let posterPath: String = try row.select("img").attr("src")
            let posterURL = URL(string: "https:"+posterPath)!
            let webURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            let type: MediaContent.MediaContentType = url.contains("/movie/") ? .movie :  .tvShow
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: .flix)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent("page").appendingPathComponent("\(page)"))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent("page").appendingPathComponent("\(page)"))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let title = try pageDocument.select("header .Title").text()
        let posterPath = try pageDocument.select("header .Image img").attr("src")
        let posterURL = URL(string: "https:" + posterPath)!
        let path = try pageDocument.select(".TPlayer iframe").attr("src")
        guard let sourceURL = URL(string: path) else {
            throw SeriesYonkisProviderError.missingMovieInformation
        }
        return Movie(title: title, webURL: url, posterURL: posterURL, sources: [Source(hostURL: sourceURL)])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let title = try pageDocument.select("header .Title").text()
        let posterPath = try pageDocument.select("header .Image img").attr("src")
        let posterURL = URL(string: "https:" + posterPath)!

        let seasonsRows: Elements = try pageDocument.select(".Wdgt.AABox")
        let seasons = try seasonsRows.array().compactMap { seasonRow -> Season? in
            let seasonNumberString: String = try seasonRow.select(".Title.AA-Season").attr("data-tab")
            let episodes = try seasonRow.select("tr").array().compactMap { row -> Episode? in
                let number = try row.select(".Num").text()
                let path = try row.select(".MvTbPly a").attr("href")
                guard let sourceURL = URL(string: path) else {
                    return nil
                }

                return Episode(number: Int(number) ?? 1,
                               sources: [Source(hostURL: sourceURL)])
            }
            if episodes.count == 0 {
                return nil
            } else {
                return Season(seasonNumber: Int(seasonNumberString) ?? 1, webURL: url, episodes: episodes)
            }
        }
        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "+")
        let pageURL = baseURL.appendingPathComponent("page")
            .appendingPathComponent("\(page)")
            .appending("s", value: keyword)
        return try await parsePage(url: pageURL)

    }
    public func home() async throws -> [MediaContentSection] {
        let media = try await parsePage(url: .init(staticString: "https://seriesyonkis.nu/mas-vistas/"))
        return [MediaContentSection(title: "Most viewed", media: media)]
    }
}
