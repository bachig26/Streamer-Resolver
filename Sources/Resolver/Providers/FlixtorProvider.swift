import Foundation
import SwiftSoup

public class FlixtorProvider: Provider {
    public let type: ProviderType
    public let title: String
    public var subtitle: String = "English content with multi-language subtitles. Slow updating"
    public let baseURL: URL
    public var moviesURL: URL {
        baseURL.appendingPathComponent("movies")
    }
    public var tvShowsURL: URL {
        baseURL.appendingPathComponent("tv-series")
    }
    public var homeURL: URL {
        baseURL.appendingPathComponent("home")
    }
    public let langauge: String = "🇺🇸"

    let nineAnimeKey = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    var cipherKey: String {
        if let key = UserDefaults.standard.string(forKey: "flixtor_provider_cipher_key") {
            return key
        } else {
            return "DZmuZuXqa9O0z3b7"
        }
    }

    enum FlixtorProvidereError: Error {
        case posterNotFound

    }

    public init(title: String, baseURL: URL, type: ProviderType) {
        self.title = title
        self.baseURL = baseURL
        self.type = type

    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        let content = try await  Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select(".filmlist > .item")
        return try rows.array().compactMap { row -> MediaContent? in
            let content = try row.select("a")
            let path = try content.attr("href")
            let isMovie = path.contains("/movie/")
            let title: String = try content.attr("title")
            let posterPath: String = try content.select("img").attr("src")
            guard let posterURL = URL(string: posterPath) else {
                return nil
            }
            let webURL = baseURL.appendingPathComponent(path)
            return MediaContent(title: title, webURL: webURL, posterURL: posterURL, type: isMovie ? .movie : .tvShow, provider: .flixtor)
        }
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: moviesURL.appending("page", value: String(page)))
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        return try await parsePage(url: tvShowsURL.appending("page", value: String(page)))
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let title = try pageDocument.select("h1[class=title]").text()
        let posterPath = try pageDocument.select(".info > .poster > span > img").attr("src")
        let posterURL = URL(string: posterPath)!

        let requestUrl = baseURL.appendingPathComponent("ajax/film/servers")
        let mediaID = url.absoluteString.components(separatedBy: "-").last!
        let vrf = encodeVrf(text: mediaID)

        let data = try await Utilities.requestData(url: requestUrl, parameters: ["id": mediaID, "vrf": vrf, "token": ""])
        let content = try JSONCoder.decoder.decode(Response.self, from: data)
        let document = try SwiftSoup.parse(content.html)
        let rows: Elements = try document.select(".episode > a")

        let sources = try await rows.array().asyncMap { row -> [Source] in
            let data: String = try row.attr("data-ep")
            let json = try JSONCoder.decoder.decode([Int: String].self, from: data.data(using: .utf8)!)
            return  json.map { _, value -> Source in
                let url = self.baseURL.appendingPathComponent("ajax/episode/info").appending("id", value: value)
                return Source(hostURL: url)
            }
        }
            .flatMap { $0 }

        return Movie(title: title, webURL: url, posterURL: posterURL, sources: sources, subtitles: nil)
    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let title = try pageDocument.select("h1[class=title]").text()
        let posterPath = try pageDocument.select(".info > .poster > span > img").attr("src")
        guard let posterURL = URL(string: posterPath) else {
            throw FlixtorProvidereError.posterNotFound
        }

        let requestUrl = baseURL.appendingPathComponent("ajax/film/servers")
        let mediaID = url.absoluteString.components(separatedBy: "-").last!
        let vrf = encodeVrf(text: mediaID)

        let data = try await Utilities.requestData(url: requestUrl, parameters: ["id": mediaID, "vrf": vrf])
        let content = try JSONCoder.decoder.decode(Response.self, from: data)
        let document = try SwiftSoup.parse(content.html)
        let rows: Elements = try document.select(".episode > a")

        var seasons: [Season] = []

        try rows.array().forEach { row in
            let data: String = try row.attr("data-ep")
            let json = try JSONCoder.decoder.decode([Int: String].self, from: data.data(using: .utf8)!)

            let episodeInfo = try row.attr("data-kname").components(separatedBy: "-")
            let seasonNumber = Int(episodeInfo.first ?? "1") ?? 1
            let episodeNumber = Int(episodeInfo.last ?? "1") ?? 1

            let index = seasons.firstIndex(where: { $0.seasonNumber == seasonNumber}) ?? seasons.count
            if index == seasons.count {
                let season = Season(seasonNumber: seasonNumber, webURL: url, episodes: [])
                seasons.append(season)
            }

            let sources = json.map { _, value -> Source in
                let url = baseURL.appendingPathComponent("ajax/episode/info").appending("id", value: value)
                return Source(hostURL: url)
            }
            let episode = Episode(number: episodeNumber, sources: sources, subtitles: nil)
            seasons[index].episodes?.append(episode)
        }

        return TVshow(title: title, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let query = keyword.replacingOccurrences(of: " ", with: "+")
        let url = baseURL.appendingPathComponent("search")
            .appending("keyword", value: query)
            .appending("vrf", value: encodeVrf(text: keyword))
        return try await parsePage(url: url)
    }

    public func home() async throws -> [MediaContentSection] {
        var items = try await parsePage(url: homeURL)
        guard items.count >= 88 else {
            return []
        }
        let recommendedMovies = MediaContentSection(title: NSLocalizedString("Recommended Movies", comment: "") ,
                                                    media: Array(items.prefix(24)))
        items.removeFirst(24)
        let recommendedTVShows = MediaContentSection(title: NSLocalizedString("Recommended TV shows", comment: ""),
                                                     media: Array(items.prefix(24)))
        items.removeFirst(24)
        let trending = MediaContentSection(title: NSLocalizedString("Trending", comment: ""),
                                           media: Array(items.prefix(24)))
        items.removeFirst(24)
        let latestMovies = MediaContentSection(title: NSLocalizedString("Latest Movies", comment: ""),
                                               media: Array(items.prefix(16)))
        items.removeFirst(16)
        let latestTVSeries = MediaContentSection(title: NSLocalizedString("Latest TV Series", comment: ""),
                                                 media: items)
        return [recommendedMovies, recommendedTVShows, trending, latestMovies, latestTVSeries]
    }
}

private extension FlixtorProvider {
    struct Response: Codable {
        let html: String
    }

    func encodeVrf(text: String) -> String {
        let xxx = cipher(key: cipherKey, text: text.encodeURIComponent())
        return encryptss(input: xxx, key: nineAnimeKey)
            .encodeURIComponent()
    }
}
