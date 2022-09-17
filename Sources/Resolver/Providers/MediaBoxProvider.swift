import Foundation
import SwiftSoup

public class MediaBoxProvider: Provider {
    public var type: ProviderType = .mediabox

    public var title: String = "Mediabox"
    public let langauge: String = "🇺🇸"
    public var subtitle: String = "English content"

    public var moviesURL: URL = URL(staticString: "https://api.themoviedb.org/3/discover/movie/")
    public var tvShowsURL: URL = URL(staticString: "https://api.themoviedb.org/3/discover/tv/")
    public var homeURL: URL = URL(staticString: "https://api.themoviedb.org")
    public let baseURL: URL = URL(staticString: "https://2embed.to")

    public init() {
        TMDbAPI.setAPIKey(Constants.TMDbAPIKey)
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        return []
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        let respone = try await requestPage(path: "movies", type: "movie", sort: "last added", page: page)
        return respone.map { movie in
            let webURL = moviesURL.appendingPathComponent(movie.id)
            let posterURL = movie.images?.poster ?? URL(staticString: "https://feelagain.ca/images/placeholder-poster-sm.png")
            return MediaContent(title: movie.title, webURL: webURL, posterURL: posterURL, type: .movie, provider: .mediabox)
        }
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        let respone = try await requestPage(path: "shows", type: "tv", sort: "updated", page: page)
        return respone.map { show in
            let webURL = tvShowsURL.appendingPathComponent(show.id).appendingPathComponent(show.imdb_id)
            let posterURL = show.images?.poster ?? URL(staticString: "https://feelagain.ca/images/placeholder-poster-sm.png")
            return MediaContent(title: show.title, webURL: webURL, posterURL: posterURL, type: .tvShow, provider: .mediabox)
        }
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let id = url.lastPathComponent
        let respone = try await TMDbAPI.shared.movies.details(forMovie: Int(id) ?? 0)


        return Movie(title: respone.title, webURL: url, posterURL: respone.posterMediumURL!, sources: Self.generateSourcesFor(movieID: Int(id) ?? 0))

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        var mutableUrl = url
        let imdbID = mutableUrl.lastPathComponent
        mutableUrl.deleteLastPathComponent()
        let id = mutableUrl.lastPathComponent
        let respone = try await requestEpisodes(id: imdbID)
        let numberOfSeasons  = respone.episodes.map { $0.season}.uniqued().sorted()
        let seasons = numberOfSeasons.map { seasonNumber -> Season in
            let url = tvShowsURL.appendingPathComponent("\(seasonNumber)")
            let episodes = respone.episodes.filter { $0.season == seasonNumber }.compactMap { episode -> Episode? in
                let sources = Self.generateSourcesFor(tvShowID: Int(id) ?? 0, seasonNumber: episode.season, episodeNumber: episode.episode)
                return Episode(number: episode.episode, sources: sources)
            }.sorted()
            return Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
        }
        let posterURL = respone.images?.poster ?? URL(staticString: "https://feelagain.ca/images/placeholder-poster-sm.png")

        return TVshow(title: respone.title, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        let response = try await requestSearch(query: keyword)
        return response.compactMap { media in
            var webURL = tvShowsURL.appendingPathComponent(media.id)
            if media.type == 2 {
                webURL = webURL.appendingPathComponent(media.imdb_id)
            }
            let posterURL = media.images?.poster ?? URL(staticString: "https://feelagain.ca/images/placeholder-poster-sm.png")
            return MediaContent(title: media.title, webURL: webURL, posterURL: posterURL, type: media.type == 1 ? .movie : .tvShow, provider: .mediabox)
        }
    }

    public func home() async throws -> [MediaContentSection] {

        let response = try await requestDiscover()

        return response.articles.map { article -> MediaContentSection in
            let mediaContents = article.contents.map { media -> MediaContent in
                var webURL = tvShowsURL.appendingPathComponent(media.id)
                if media.type == 2 {
                    webURL = webURL.appendingPathComponent(media.imdb_id)
                }
                let posterURL = media.images?.poster ?? URL(staticString: "https://feelagain.ca/images/placeholder-poster-sm.png")
                return MediaContent(title: media.title, webURL: webURL, posterURL: posterURL, type: media.type == 1 ? .movie : .tvShow, provider: .mediabox)
            }
            return MediaContentSection(title: article.title, media: mediaContents)
        }

    }

    public static func generateSourcesFor(movieID: Int) -> [Source] {
        let embedURL = URL(staticString: "https://2embed.to").appendingPathComponent("embed/tmdb/movie").appendingQueryItem(name: "id", value: movieID)
        let vidsrcURL = URL(staticString: "https://v2.vidsrc.me/embed/").appendingPathComponent(movieID)
        let olgPlayURL = URL(staticString: "https://olgply.xyz/").appendingPathComponent(movieID)

        return [.init(hostURL: embedURL), .init(hostURL: vidsrcURL), .init(hostURL: olgPlayURL)]
    }

    public static func generateSourcesFor(tvShowID: Int, seasonNumber: Int, episodeNumber: Int) -> [Source] {
        let embedURL = URL(staticString: "https://2embed.to").appendingPathComponent("embed/tmdb/tv")
            .appendingQueryItem(name: "id", value: tvShowID)
            .appendingQueryItem(name: "s", value: seasonNumber)
            .appendingQueryItem(name: "e", value: episodeNumber)
        let vidsrcURL = URL(staticString: "https://v2.vidsrc.me/embed/").appendingPathComponent(tvShowID).appendingPathComponent("\(seasonNumber)-\(episodeNumber)")
        let olgPlayURL = URL(staticString: "https://olgply.xyz/").appendingPathComponent(tvShowID).appendingPathComponent(seasonNumber).appendingPathComponent(episodeNumber)

        return [.init(hostURL: embedURL), .init(hostURL: vidsrcURL), .init(hostURL: olgPlayURL)]
    }
    private func requestPage(path: String, type: String, sort: String, page: Int) async throws -> [MediaBoxMediaContent] {
        let params = [
            "act": "top",
            "genre": "all",
            "kidmode": "false",
            "sort": sort,
            "type": type
        ]
        let data = try await request(path: "\(path)/\(page)", params: params)
        let media = try? JSONDecoder().decode([MediaBoxMediaContent].self, from: data)
        return media ?? []
    }

    private func requestEpisodes(id: String) async throws -> MediaBoxEpisodesRespose {
        let params = [
            "act": "detail",
            "id": id
        ]
        let data = try await request(path: "show/\(id)", params: params)
        return try JSONDecoder().decode(MediaBoxEpisodesRespose.self, from: data)
    }

    private func requestDiscover() async throws -> DiscoverResponse {
        let params = [
            "act": "discovers"
        ]
        let data = try await request(path: "discovers", params: params)
        return try JSONDecoder().decode(DiscoverResponse.self, from: data)
    }

    private func requestSearch(query: String) async throws -> [MediaBoxMediaContent] {
        let params = [
            "act": "search",
            "genre": "all",
            "kidmode": "false",
            "keywords": query,
            "q": query
        ]
        let data = try await request(path: "movies/1", params: params)
        let media = try? JSONDecoder().decode([MediaBoxMediaContent].self, from: data)
        return media ?? []
    }

    private let deviceId = UUID().uuidString
    private func request(path: String, params: [String: String]) async throws -> Data {
        var appParams = [
            "aa": "media.box.hd.\(randomString(length: 10))",
            "appversion": "2.5",
            "device": "iPhone 12",
            "deviceid": deviceId,
            "os": "ios",
            "osversion": "15.5"
        ]
        params.forEach { key, value in
            appParams[key] = value
        }
        let url = URL(staticString: "https://qazwsxedcrfvtgb.info/").appendingPathComponent(path)
        return try await Utilities.requestData(url: url, parameters: appParams)
    }

    private struct MediaBoxMediaContent: Codable {
        let id: Int
        let imdb_id: String
        let title: String
        let type: Int
        let images: MediaBoxImages?
    }

    private struct MediaBoxImages: Codable {
        let poster: URL
    }

    private struct MediaBoxEpisodesRespose: Codable {
        let title: String
        let images: MediaBoxImages?
        let episodes: [MediaBoxEpisode]
    }

    // MARK: - Episode
    private struct MediaBoxEpisode: Codable {
        let episode: Int
        let season: Int
    }

    // MARK: - Welcome
    private struct DiscoverResponse: Codable {
        let articles: [Article]
    }

    // MARK: - Article
    private struct Article: Codable {
        let id: Int
        let title: String
        let contents: [MediaBoxMediaContent]
    }

}
