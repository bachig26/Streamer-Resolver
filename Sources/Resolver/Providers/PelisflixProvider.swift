import Foundation
import SwiftSoup

public class PelisflixProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "es_ES")
    }

    public var type: ProviderType = .pelisflix

    public var title: String = "Pelisflix.uno"
    public let langauge: String = "🇪🇸"
    public var subtitle: String = "Spanish content"

    public var moviesURL: URL = URL(staticString: "https://pelisflix.uno/peliculas-online/")
    public var tvShowsURL: URL = URL(staticString: "https://pelisflix.uno/series-online/")
    public var homeURL: URL = URL(staticString: "https://pelisflix.uno")
    public let baseURL: URL = URL(staticString: "https://pelisflix.uno")

    public init() { }

    enum PelisflixProviderError: Error {
        case missingMovieInformation

    }
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url, encoding: .isoLatin1)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".MovieList .TPostMv > article > a")
        return try rows.array().map { row in
            let url = try row.attr("href")
            let title: String = try row.select("h2").text()
            let posterPath: String = try row.select("img").attr("data-src")
            let posterURL = URL(string: "https:"+posterPath)!
            let webURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            let type: MediaContent.MediaContentType = url.contains("pelicula") ? .movie :  .tvShow
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
        let title = try pageDocument.select(".TPMvCn .Title").text()
        let posterPath = try pageDocument.select(".TPostBg").attr("src")
        let posterURL = URL(string: "https:" + posterPath)!
        return Movie(title: title, webURL: url, posterURL: posterURL, sources: [.init(hostURL: url)])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let title = try pageDocument.select(".TPMvCn .Title").text().replacingOccurrences(of: "Serie", with: "")
        let posterPath = try pageDocument.select(".TPostBg").attr("src")
        let posterURL = URL(string: "https:" + posterPath)!

        let seasonsRows: Elements = try pageDocument.select(".SeasonBx.AACrdn a")
        let seasons = try await seasonsRows.array().asyncMap { seasonRow -> Season in
            let seasonNumberString: String = try seasonRow.select("span").text()
            let seasonPath: String = try seasonRow.attr("href")
            let seasonURL = URL(string: seasonPath)!

            let pageContent = try await Utilities.downloadPage(url: seasonURL)
            let pageDocument = try SwiftSoup.parse(pageContent)

            let episodes = try pageDocument.select(".Viewed").array().map { row -> Episode in
                let number = try row.select(".Num").text()
                let path = try row.select(".MvTbPly a").attr("href")
                guard let sourceURL = URL(string: path) else {
                    throw PelisflixProviderError.missingMovieInformation
                }

                return Episode(number: Int(number) ?? 1,
                               sources: [Source(hostURL: sourceURL)])
            }
            return Season(seasonNumber: Int(seasonNumberString) ?? 1, webURL: seasonURL, episodes: episodes)
        }
        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "+")
        let pageURL = baseURL.appending("s", value: keyword)
        return try await parsePage(url: pageURL)

    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 48 else {
            return []
        }

        let recommendedMovies = MediaContentSection(title: "Latest Movies", media: Array(items.prefix(24)))
        items.removeFirst(24)
        let recommendedTVShows = MediaContentSection(title: "Latest TV shows", media: Array(items.prefix(24)))
        return [recommendedMovies, recommendedTVShows]

    }
}
