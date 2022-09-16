import Foundation
import SwiftSoup

public class AkwamProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "ar_SA")
    }
    public var type: ProviderType = .akwam
    public var title: String = "Akwam.to"
    public let langauge: String = "🇸🇦"
    public var subtitle: String = "Arabic content"

    public var moviesURL: URL = URL(staticString: "https://akwam.to/movies")
    public var tvShowsURL: URL = URL(staticString: "https://akwam.to/series")
    public var homeURL: URL = URL(staticString: "https://akwam.to/one")
    public let baseURL: URL = URL(string: "https://akwam.to/")!

    public init() { }

    enum AkwamProviderError: Error {
        case missingMovieInformation
    }
    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".entry-box")
        return try rows.array().map { row in
            let content = try row.select(".entry-image > a")
            let url = try content.attr("href")
            let title: String = try row.select("picture > img").attr("alt")
            let posterPath: String = try row.select("picture > img").attr("data-src")
            let posterURL = URL(string: posterPath)!
            let webURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            let type: MediaContent.MediaContentType = url.contains("/movie/") ? .movie :  .tvShow
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: .akwam)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        guard let posterPath = try document.select("a > picture > img").first()?.attr("src"),
              let posterURL = URL(string: posterPath),
              let title = try document.select("[property=og:title]").first()?.attr("content").replacingOccurrences(of: "| اكوام", with: "") else {
            throw AkwamProviderError.missingMovieInformation
        }

        return Movie(title: title, webURL: url, posterURL: posterURL, sources: [Source(hostURL: url)])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".widget-body .row .row a")
        let rowsCount = rows.array().count
        let episodes = try rows.array().enumerated().map { (index, row) -> Episode in
            let eposideNumber: Int = rowsCount - index
            let path: String = try row.attr("href")
            let screenshotPath = try row.select("img").attr("src")
            let screenshotURL = URL(string: screenshotPath)
            let url = URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            return Episode(number: eposideNumber, screenshot: screenshotURL, sources: [Source(hostURL: url)])
        }.sorted()

        guard let posterPath = try document.select("a > picture > img").first()?.attr("src"),
              let posterURL = URL(string: posterPath),
              let title = try document.select("[property=og:title]").first()?.attr("content").replacingOccurrences(of: "| اكوام", with: "") else {
            throw AkwamProviderError.missingMovieInformation
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = .init(identifier: "ar_EG")

        let components = title.components(separatedBy: "الموسم")
        let query = components.dropLast().first ?? title
        var seasonNumber: Int = 1
        if let season = components.last {
            seasonNumber = Int(truncating: formatter.number(from: season) ?? 1)
        }
        let season = Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)

        let overview = try document.select("div.widget-body > h2 > div > p").html()
        let trailer = try document.select("a.btn.btn-light.btn-pill.d-flex.align-items-center").attr("href")
        let trailerURL = URL(string: trailer)

        let actors = try document.select(".entry-box.entry-box-3.h-100").array().map { row -> Actor in
            let name =  try row.select(".entry-title.text-center").html() // .entry-title.text-center
            let profilePath = try row.select("img").attr("src").replacingOccurrences(of: "54x54", with: "200x200")
            let profileURL = URL(string: profilePath)
            return Actor(name: name, profileURL: profileURL)
        }
        return TVshow(title: query,
                      webURL: url,
                      posterURL: posterURL,
                      overview: overview,
                      trailer: trailerURL,
                      seasons: [season],
                      actors: actors)

    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let keyword = keyword.replacingOccurrences(of: " ", with: "+")
        let pageURL = baseURL.appendingPathComponent("search")
            .appending("section", value: "series")
            .appending("page", value: "\(page)")
            .appending("q", value: keyword)
        return try await parsePage(url: pageURL)

    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.downloadPage(url: homeURL)
        let document = try SwiftSoup.parse(content)
        let sectionRows: Elements = try document.select(".widget")
        return try sectionRows.array().compactMap { section -> MediaContentSection?  in
            let title = try section.select(".header-title").text()
            let rows: Elements = try section.select(".entry-box")
            let media = try rows.array().compactMap { row  -> MediaContent? in
                let content = try row.select(".entry-image > a")
                let url = try content.attr("href")
                let title: String = try row.select("picture > img").attr("alt")
                let posterPath: String = try row.select("picture > img").attr("data-src")
                guard let posterURL = URL(string: posterPath),
                      let path =  url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let webURL = URL(string: path) else { return nil }

                let type: MediaContent.MediaContentType
                if url.contains("/movie/") {
                    type = .movie
                } else if url.contains("/series/") || url.contains("/shows/") {
                    type = .tvShow
                } else {
                    return nil
                }
                return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: .akwam)
            }

            if media.isEmpty {
                return nil
            } else {
                return MediaContentSection(title: title, media: media.unique())
            }
        }

    }

}
