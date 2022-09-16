import Foundation
import SwiftSoup

public class CimaNowProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "ar_SA")
    }
    public var type: ProviderType = .cimaNow
    public var title: String = "CimaNow.cc"
    public let langauge: String = "🇸🇦"
    public var subtitle: String = "Arabic content"
    public let baseURL: URL = URL(staticString: "https://cimanow.cc/")
    public var moviesURL: URL = URL(staticString: "https://cimanow.cc/category/%D8%A7%D9%81%D9%84%D8%A7%D9%85-%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9")
    public var tvShowsURL: URL = URL(staticString: "https://cimanow.cc/category/%D9%85%D8%B3%D9%84%D8%B3%D9%84%D8%A7%D8%AA-%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9")
    public var homeURL: URL = URL(staticString: "https://cimanow.cc/home/")
    public init() {}

    enum CimaNowProviderError: Error {
        case missingMovieInformation
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("[aria-label=post]")
        return try rows.array().map { row in
            let content = try row.select("a")
            let url = try content.attr("href")
            let posterPath: String = try row.select("img").attr("data-src").addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)!
            let posterURL = URL(string: posterPath)!
            let webURL = URL(string: url)!
            let title: String = try content.select("[aria-label=title]").html().components(separatedBy: "<em>").first ?? ""
            let type: MediaContent.MediaContentType = url.contains("%d9%81%d9%8a%d9%84%d9%85") ? .movie :  .tvShow
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: .cimaNow)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent("page").appendingPathComponent("\(page)"))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent("page").appendingPathComponent("\(page)"))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        guard let posterPath = try document.select("[property=og:image]").first()?.attr("content").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let posterURL = URL(string: posterPath) else {
            throw CimaNowProviderError.missingMovieInformation
        }
        let components = url.lastPathComponent.components(separatedBy: "-")
        let title = components.dropLast().dropFirst().joined(separator: " ")

        return Movie(title: title, webURL: url, posterURL: posterURL, sources: [Source(hostURL: url.appendingPathComponent("watching"))])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("#eps > li > a")
        let episodes = try rows.array().reversed().enumerated().map { (index, row) -> Episode in
            let path: String = try row.attr("href")
            let url = URL(string: path)!.appendingPathComponent("watching")
            let eposideNumber: Int = index + 1
            return Episode(number: eposideNumber, sources: [Source(hostURL: url)])
        }

        guard let posterPath = try document.select("[property=og:image]").first()?.attr("content").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let posterURL = URL(string: posterPath) else {
            throw CimaNowProviderError.missingMovieInformation
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = .init(identifier: "ar_EG")

        let components = url.lastPathComponent.components(separatedBy: "-")
        let query = components.dropLast().dropFirst().joined(separator: " ")
        var seasonNumber: Int = 1
        if let season = components.last?.replacingOccurrences(of: "ج", with: "") {
            seasonNumber = Int(truncating: formatter.number(from: season) ?? 1)
        }
        let season = Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
        let overview = try document.select("#details > li:nth-child(1) > p").text()
        return TVshow(title: query,
                      webURL: url,
                      posterURL: posterURL,
                      overview: overview,
                      seasons: [season])
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let pageURL = baseURL.appendingPathComponent("page").appendingPathComponent("\(page)").appending("s", value: keyword)
        return try await parsePage(url: pageURL)
    }

    public func home() async throws -> [MediaContentSection] {
        let content = try await Utilities.downloadPage(url: homeURL)
        let document = try SwiftSoup.parse(content)
        let sectionRows: Elements = try document.select("section")
        return try sectionRows.array().compactMap { section -> MediaContentSection?  in
            let title = try section.select("span").text()
                .replacingOccurrences(of: "شاهد الكل", with: "")
                .replacingOccurrences(of: "جديد", with: "")
            let rows: Elements = try section.select(".owl-body a")

            let media = try rows.array().compactMap { row -> MediaContent? in
                let content = try row.select("a")
                let url = try content.attr("href")
                let posterPath: String = try row.select("img").attr("data-src").addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)!
                let posterURL = URL(string: posterPath)!
                let webURL = URL(string: url)!
                let title: String = try content.select("[aria-label=title]").html().components(separatedBy: "<em>").first ?? ""
                let type: MediaContent.MediaContentType
                if url.contains("%d9%81%d9%8a%d9%84%d9%85") {
                    type = .movie
                } else if url.contains("selary") {
                    type = .tvShow
                } else {
                    return nil
                }
                return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: type, provider: .cimaNow)
            }
            if media.isEmpty {
                return nil
            } else {
                return MediaContentSection(title: title, media: media)
            }
        }

    }

}
