import Foundation
import SwiftSoup

public class StreamingCommunityProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "it_IT")
    }

    public var type: ProviderType = .streamingCommunity

    public let title: String = "StreamingCommunity"
    public let langauge: String = "🇮🇹"
    public var subtitle: String = ""
    public var moviesURL: URL {
        baseURL.appendingPathComponent("film")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("serie-tv")
    }
    public var baseURL: URL {
        if let path = UserDefaults.standard.string(forKey: "streamingcommunity_url"), let url = URL(string: path) {
            return url
        } else {
            return URL(staticString: "https://streamingcommunity.actor")
        }
    }
    public init() {}

    public func parsePage(url: URL) async throws -> [MediaContent] {
        return try await parsePage(url: url, isSearch: false)
    }

    func parsePage(url: URL, isSearch: Bool = false) async throws -> [MediaContent] {
        let page = Int(url.lastPathComponent) ?? 0
        let from = page * 10
        let results = isSearch ?  try await parseSearch(url: url): try await parse(url: url.deletingLastPathComponent())

        return try await results
            .map { $0.1 }
            .flatMap { $0 }
            .dropFirst(from)
            .prefix(10)
            .asyncMap { searchr in
                let id = searchr.id
                let name = searchr.slug
                let img = searchr.images.first!
                let number = translatenumber(num: img.server_id)
                let ip = translateip(num: img.proxy_id)
                let detailURL = baseURL.appendingPathComponent("/api/titles/preview/\(id)")
                let detailsData = try await Utilities.requestData(url: detailURL, httpMethod: "POST", extraHeaders: ["referer": baseURL.absoluteString])
                let details = try JSONCoder.decoder.decode(Details.self, from: detailsData)
                let posterurl = try URL("https://\(ip)/images/\(number)/\(img.url)")
                let videourl = baseURL.appendingPathComponent("titles/\(id)-\(name)")
                return MediaContent(title: details.name, webURL: videourl, posterURL: posterurl, type: details.type == "movie" ? .movie : .tvShow, provider: .streamingCommunity)
            }
    }

    func parseSearch(url: URL) async throws -> [(String, [Slider])] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let films = try document.select("the-search-page").attr("records-json")
        let json = try JSONCoder.decoder.decode([Slider].self, from: films.data(using: .utf8)!)
        return [("results", json)]
    }

    func parse(url: URL) async throws -> [(String, [Slider])] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("slider-title")
        return try await rows.array().prefix(3).asyncMap { slider -> (String, [Slider])? in
            let name = try slider.attr("slider-name")
            guard name != "In arrivo" else {
                return nil
            }
            let films = try slider.attr("titles-json")
            let json = try JSONCoder.decoder.decode([Slider].self, from: films.data(using: .utf8)!)
            return (name, json)
        }
        .compactMap { $0 }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appendingPathComponent(page))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appendingPathComponent(page))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)

        let title = try document.select("div > div > h1").text()
        let sourcePath = try document.select("a.play-hitzone").attr("href")
        let sourceURL = try URL(sourcePath)

        let posterPath = try document.select("[property=og:image]").first()?.attr("content").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let posterURL = try URL(posterPath)

        return Movie(title: title, webURL: url, posterURL: posterURL, sources: [.init(hostURL: sourceURL)])

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let title = try document.select("season-select").attr("title-json")
        let titleJson = try JSONCoder.decoder.decode(TitleDetails.self, from: title.data(using: .utf8)!)

        let details = try document.select("season-select").attr("seasons")
        let json = try JSONCoder.decoder.decode([SSeason].self, from: details.data(using: .utf8)!)
        let seasons = json.map { season -> Season in
            let episodes = season.episodes.map {
                return Episode(number: $0.number, sources: [.init(hostURL: baseURL.appendingPathComponent("/watch/\(season.title_id)").appending("e", value: "\($0.id)"))])
            }.sorted()
            var seasonURL = url
            if url.absoluteString.contains("stagione-") {
                seasonURL.deleteLastPathComponent()
            }
            seasonURL = seasonURL.appendingPathComponent("stagione-\(season.number)")
            return .init(seasonNumber: season.number, webURL: seasonURL, episodes: episodes)
        }

        let img = titleJson.images.first!
        let number = translatenumber(num: img.server_id)
        let ip = translateip(num: img.proxy_id)
        let posterURL = try URL("https://\(ip)/images/\(number)/\(img.url)")
        return TVshow(title: titleJson.original_name ?? titleJson.name, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let pageURL = baseURL.appendingPathComponent("/search").appending("q", value: "\(keyword)")
        return try await parsePage(url: pageURL, isSearch: true)
    }

    public func home() async throws -> [MediaContentSection] {
        return try await parse(url: baseURL).asyncMap { (name, items) -> MediaContentSection in
            let media = try await items.prefix(5).asyncMap { searchr -> MediaContent in
                let id = searchr.id
                let name = searchr.slug
                let img = searchr.images.first!
                let number = translatenumber(num: img.server_id)
                let ip = translateip(num: img.proxy_id)
                let detailURL = baseURL.appendingPathComponent("/api/titles/preview/\(id)")
                let detailsData = try await Utilities.requestData(url: detailURL, httpMethod: "POST", extraHeaders: ["referer": baseURL.absoluteString])
                let details = try JSONCoder.decoder.decode(Details.self, from: detailsData)

                let posterurl = try URL("https://\(ip)/images/\(number)/\(img.url)")
                let videourl = baseURL.appendingPathComponent("titles/\(id)-\(name)")
                return MediaContent(title: details.name, webURL: videourl, posterURL: posterurl, type: details.type == "movie" ? .movie : .tvShow, provider: .streamingCommunity)
            }
            return .init(title: name, media: media)
        }
    }

    struct Slider: Codable {
        var id: Int
        var slug: String
        var images: [Image]
    }

    // MARK: - Image
    struct Image: Codable {
        var server_id: Int
        var proxy_id: Int
        var url: String
    }

    private func translatenumber(num: Int) -> Int {
        switch num {
        case 67: return 1
        case 71: return 2
        case 72: return 3
        case 73: return 4
        case 74: return 5
        case 75: return 6
        case 76: return 7
        case 77: return 8
        case 78: return 9
        case 79: return 10
        case 13: return 11
        default : return 11
        }
    }

    private func translateip(num: Int) -> String {
        switch num {
        case 16  : return "sc-b1-01.scws-content.net"
        case 17  : return "sc-b1-02.scws-content.net"
        case 18  : return "sc-b1-03.scws-content.net"
        case 85  : return "sc-b1-04.scws-content.net"
        case 95  : return "sc-b1-05.scws-content.net"
        case 117 : return "sc-b1-06.scws-content.net"
        case 141 : return "sc-b1-07.scws-content.net"
        case 142 : return "sc-b1-08.scws-content.net"
        case 143 : return "sc-b1-09.scws-content.net"
        case 144 : return "sc-b1-10.scws-content.net"
        default: return "sc-b1-10.scws-content.net"
        }
    }

    struct Details: Decodable {
        let name: String
        let type: String
    }

    struct SSeason: Decodable {
        let number: Int
        let title_id: Int
        let episodes: [SEpisode]
    }

    struct SEpisode: Decodable {
        let id: Int
        let number: Int
    }

    struct TitleDetails: Decodable {
        let original_name: String?
        let name: String
        let images: [Image]
    }
}
