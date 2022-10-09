import Foundation
import SwiftSoup

public class FlixProvider: Provider {
    public var locale: Locale {
        return Locale(identifier: "es_ES")
    }

    public var type: ProviderType = .flix

    public var title: String = "Peliculasgo"
    public let langauge: String = "🇪🇸"
    public var subtitle: String = "Spanish content"

    public var moviesURL: URL = URL(staticString: "https://peliculasflix.co/peliculas/")
    public var tvShowsURL: URL = URL(staticString: "https://peliculasflix.co/series-online/")
    public var homeURL: URL = URL(staticString: "https://peliculasflix.co")
    public let baseURL: URL = URL(staticString: "https://peliculasflix.co")
    let imagesBaseURL = URL(staticString: "https://image.tmdb.org/t/p/w342/")

    var token: String {
        let base = randomString(length: 10) + "_" + randomString(length: 12) + "_" + randomString(length: 5)
        let date = "\(Int(round(Date().timeIntervalSince1970)) + 43200)".toBase64URL() + "=="
        return base + date
    }
    public init() { }

    enum FlixProviderError: Error {
        case gqlError(error: Error)
    }

    public func parsePage(url: URL) async throws -> [MediaContent] {
        return []
    }

    public func latestMovies(page: Int) async throws -> [MediaContent] {
        let response: FilmListingResponse = try await executeGQL(gql: .listMovies(page: page, sort: "CREATEDAT_DESC"))

        return response.data.paginationFilm.items.map { film in
            let webURL = moviesURL.appendingPathComponent(film.slug)
            let posterURL = imagesBaseURL.appendingPathComponent(film.posterPath)
            let name = generateTitle(film.name, film.nameEs)
            return MediaContent(title: name, webURL: webURL, posterURL: posterURL, type: .movie, provider: .flix)
        }
    }

    public func latestTVShows(page: Int) async throws -> [MediaContent] {
        let response: SeriesListingResponse = try await executeGQL(gql: .listSeries(page: page, sort: "CREATEDAT_DESC"))

        return response.data.paginationSerie.items.map { show in
            let webURL = moviesURL.appendingPathComponent(show.slug)
            let posterURL = imagesBaseURL.appendingPathComponent(show.posterPath)
            let name = generateTitle(show.name, show.nameEs)
            return MediaContent(title: name, webURL: webURL, posterURL: posterURL, type: .tvShow, provider: .flix)
        }
    }

    public func fetchMovieDetails(for url: URL) async throws -> Movie {
        let slug = url.lastPathComponent
        let response: DetailFilmResponse = try await executeGQL(gql: .detailFilm(slug: slug))

        let film = response.data.detailFilm
        let posterURL = imagesBaseURL.appendingPathComponent(film.posterPath)
        let sources = film.linksOnline.map {
            return Source(hostURL: $0.link)
        }
        let name = generateTitle(film.name, film.nameEs)
        return Movie(title: name, webURL: url, posterURL: posterURL, sources: sources)

    }

    public func fetchTVShowDetails(for url: URL) async throws -> TVshow {
        let slug = url.lastPathComponent
        let response: DetailSerieResponse = try await executeGQL(gql: .detailSerie(id: slug))
        let detailSerie = response.data.detailSerie
        let posterURL = imagesBaseURL.appendingPathComponent(detailSerie.posterPath)
        let name = generateTitle(detailSerie.name, detailSerie.nameEs)

        let seasons = try await Array(1...detailSerie.numberOfSeasons).asyncMap { seasonNumber -> Season in
            let url = tvShowsURL.appendingPathComponent("\(seasonNumber)")
            let episodesResponse: ListEpisodesResponse = try await executeGQL(gql: .listEposides(tvshowID: detailSerie.id, season: seasonNumber))
            let episodes = episodesResponse.data.paginationEpisode.items.compactMap { episode -> Episode? in
                let sources = episode.linksOnline.map {
                    return Source(hostURL: $0.link)
                }
                if sources.count > 0 {
                    return Episode(number: episode.episodeNumber, sources: sources)
                } else {
                    return nil
                }
            }

            return Season(seasonNumber: seasonNumber, webURL: url, episodes: episodes)
        }
        return TVshow(title: name, webURL: url, posterURL: posterURL, seasons: seasons)
    }

    public func search(keyword: String, page: Int) async throws -> [MediaContent] {
        var results: [MediaContent] = []
        if let seriesResponse: SearchResponse = try? await executeGQL(gql: .searchSeries(query: keyword)) {
            let searchResults = seriesResponse.data.searchSerie?.map { show -> MediaContent in
                let webURL = tvShowsURL.appendingPathComponent(show.slug)
                let posterURL = imagesBaseURL.appendingPathComponent(show.posterPath)
                let name = generateTitle(show.name, show.nameEs)
                return MediaContent(title: name, webURL: webURL, posterURL: posterURL, type: .tvShow, provider: .flix)
            } ?? []
            results.append(contentsOf: searchResults)
        }
        if let filmResponse: SearchResponse = try? await executeGQL(gql: .searchFilms(query: keyword)) {
            let searchResults = filmResponse.data.searchFilm?.map { film -> MediaContent in
                let webURL = moviesURL.appendingPathComponent(film.slug)
                let posterURL = imagesBaseURL.appendingPathComponent(film.posterPath)
                let name = generateTitle(film.name, film.nameEs)
                return MediaContent(title: name, webURL: webURL, posterURL: posterURL, type: .movie, provider: .flix)
            } ?? []
            results.append(contentsOf: searchResults)
        }

        return results
    }

    func executeGQL<T: Decodable>(gql: GQL) async throws -> T {
        let url: URL
        if let path = UserDefaults.standard.string(forKey: "peliculasgo_gql_api"),
           let remoteURL = URL(string: path) {
            url = remoteURL
        } else {
            url = URL(staticString: "https://fluxcedene.net/api/gql")
        }
        let data = gql.query.data(using: .utf8)
        let responseData = try await Utilities.requestData(
            url: url,
            httpMethod: "POST",
            data: data,
            extraHeaders: [
                "authority": "fluxcedene.net",
                "accept": "*/*",
                "accept-language": "en-US,en;q=0.9,ar;q=0.8",
                "authorization": "Bear",
                "cache-control": "no-cache",
                "content-type": "application/json",
                "dnt": "1",
                "origin": "https://peliculasflix.co",
                "platform": "peliculasgo",
                "pragma": "no-cache",
                "referer": "https://peliculasflix.co/",
                "sec-ch-ua": "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"102\", \"Google Chrome\";v=\"102\"",
                "sec-ch-ua-mobile": "?0",
                "sec-ch-ua-platform": "\"macOS\"",
                "sec-fetch-dest": "empty",
                "sec-fetch-mode": "cors",
                "sec-fetch-site": "cross-site",
                "x-access-platform": token,
                "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36",
                "x-access-jwt-token": "",
                "x-requested-with": ""
            ]
        )

        do {
            let data = try JSONCoder.decoder.decode(T.self, from: responseData)
            return data
        } catch {
            throw FlixProviderError.gqlError(error: error)
        }
    }
    public func home() async throws -> [MediaContentSection] {

        let tvShowsResponse: SeriesListingResponse = try await executeGQL(gql: .listSeries(page: 1, sort: "POPULARITY_DESC"))

        let popularTVshows = tvShowsResponse.data.paginationSerie.items.map { show -> MediaContent in
            let webURL = moviesURL.appendingPathComponent(show.slug)
            let posterURL = imagesBaseURL.appendingPathComponent(show.posterPath)
            let name = generateTitle(show.name, show.nameEs)
            return MediaContent(title: name, webURL: webURL, posterURL: posterURL, type: .tvShow, provider: .flix)
        }
        let popularTVshowsSection = MediaContentSection(title: NSLocalizedString("Popular TV shows", comment: ""), media: popularTVshows)

        let filmResponse: FilmListingResponse = try await executeGQL(gql: .listMovies(page: 1, sort: "POPULARITY_DESC"))

        let popularFilms = filmResponse.data.paginationFilm.items.map { film -> MediaContent in
            let webURL = moviesURL.appendingPathComponent(film.slug)
            let posterURL = imagesBaseURL.appendingPathComponent(film.posterPath)
            let name = generateTitle(film.name, film.nameEs)
            return MediaContent(title: name, webURL: webURL, posterURL: posterURL, type: .movie, provider: .flix)
        }
        let popularFilmsSection = MediaContentSection(title: NSLocalizedString("Popular Movies", comment: ""), media: popularFilms)

        return [popularTVshowsSection, popularFilmsSection]
    }

    enum GQL {
        case listMovies(page: Int, sort: String)
        case detailFilm(slug: String)
        case listSeries(page: Int, sort: String)
        case listEposides(tvshowID: String, season: Int)
        case searchSeries(query: String)
        case searchFilms(query: String)
        case detailSerie(id: String)
        case trendingFilms

        var query: String {
            switch self {
            case .listMovies(let page, let sort):
                return
           """
              {
                  "operationName": "listMovies",
                  "variables": {
                      "perPage": 15,
                      "sort": "\(sort)",
                      "filter": {
                          "isPublish": true
                      },
                      "page": \(page)
                  },
                  "query": "query listMovies(\\n  $page: Int\\n  $perPage: Int\\n  $sort: SortFindManyFilmInput\\n  $filter: FilterFindManyFilmInput\\n) {\\n  paginationFilm(page: $page, perPage: $perPage, sort: $sort, filter: $filter) {\\n    count\\n    pageInfo {\\n      currentPage\\n      hasNextPage\\n      hasPreviousPage\\n      __typename\\n    }\\n    items {\\n      _id\\n      name\\n      name_es\\n      slug\\n      poster_path\\n      __typename\\n    }\\n    __typename\\n  }\\n}\\n"
              }
        """
            case .detailFilm(let slug):
                return
        """
        {
            "operationName": "detailFilm",
            "variables": {
                "slug": "\(slug)"
            },
            "query": "query detailFilm($slug: String!) {\\n  detailFilm(filter: { slug: $slug }) {\\n    name\\n    name\\n      name_es\\n    poster_path\\n    links_online {\\n      _id\\n      server\\n      lang\\n      link\\n      __typename\\n    }\\n    __typename\\n  }\\n}\\n"
        }
"""
            case .listSeries(let page, let sort):
                return
           """
             {
                 "operationName": "paginationSerie",
                 "variables": {
                     "perPage": 15,
                     "sort": "\(sort)",
                     "filter": {
                         "isDraft": false
                     },
                     "page": \(page)
                 },
                 "query": "query paginationSerie($page: Int, $perPage: Int, $sort: SortFindManySerieInput, $filter: FilterFindManySerieInput) {\\n  paginationSerie(page: $page, perPage: $perPage, sort: $sort, filter: $filter) {\\n    count\\n    pageInfo {\\n      currentPage\\n      hasNextPage\\n      hasPreviousPage\\n      __typename\\n    }\\n    items {\\n      _id\\n      name\\n      name_es\\n      slug\\n      overview\\n      premiere\\n      poster_path\\n      first_air_date\\n      episode_run_time\\n      poster\\n      __typename\\n    }\\n    __typename\\n  }\\n}\\n"
             }
        """

            case let .listEposides(tvshowID, season):
                return """
{
    "operationName": "listEpisodesPagination",
    "variables": {
        "serie_id": "\(tvshowID)",
        "season_number": \(season),
        "page": 1
    },
    "query": "query listEpisodesPagination($page: Int!, $serie_id: MongoID!, $season_number: Float!) {\\n  paginationEpisode(\\n    page: $page\\n    perPage: 40\\n    sort: NUMBER_ASC\\n    filter: {type_serie: \\\"serie\\\", serie_id: $serie_id, season_number: $season_number}\\n  ) {\\n    count\\n    items {\\n      _id\\n      name\\n      still_path\\n      episode_number\\n      season_number\\n      air_date\\n      slug\\n      serie_id\\n      links_online\\n      season_poster\\n      serie_poster\\n      poster\\n      backdrop\\n      __typename\\n    }\\n    pageInfo {\\n      hasNextPage\\n      __typename\\n    }\\n    __typename\\n  }\\n}\\n\"
}
"""
            case .searchSeries(let query):
                return """
{
    "operationName": "searchAll",
    "variables": {
        "input": "\(query)"
    },
    "query": "query searchAll($input: String!) {\\n  searchSerie(input: $input, limit: 5) {\\n    _id\\n    slug\\n    name\\n    name_es\\n    poster_path\\n    poster\\n    __typename\\n  }\\n}\\n"
}
"""
            case .searchFilms(let query):
                return """
{
    "operationName": "searchAll",
    "variables": {
        "input": "\(query)"
    },
    "query": "query searchAll($input: String!) {\\n  searchFilm(input: $input, limit: 5) {\\n    _id\\n    slug\\n    name\\n    name_es\\n    poster_path\\n    poster\\n    __typename\\n  }\\n}\\n"
}
"""
            case .trendingFilms:
                return """
{
    "operationName": "listtendFilms",
    "variables": {
        "limit": 10
    },
    "query": "query listtendFilms($limit: Float) {\\n  trendsFilms(limit: $limit) {\\n    _id\\n    title\\n    name\\n    name_es\\n    languages\\n    release_date\\n    poster_path\\n    poster\\n    __typename\\n  }\\n}\\n"
}
"""
            case .detailSerie(let id):
                return """
{
    "operationName": "detailSerie",
    "variables": {
        "slug": "\(id)"
    },
    "query": "query detailSerie($slug: String!) {\\n  detailSerie(filter: { slug: $slug }) {\\n  _id\\n  name\\n  name_es\\n number_of_seasons\\n  slug\\n   poster_path\\n   }\\n}\\n"
}
"""            }
        }

    }

    private func generateTitle(_ name: String?, _ nameES: String?) -> String {
        if let nameES = nameES, let name = name, name == nameES {
            return nameES
        }
        // streamtape.com/e/9v1wp2eMlwF9Gg

        if let nameES = nameES {
            return nameES
        }
        return name ?? ""

    }

    // MARK: - Welcome
    struct FilmListingResponse: Decodable {
        let data: FilmListingDataClass
    }

    // MARK: - DataClass
    struct FilmListingDataClass: Decodable {
        let paginationFilm: PaginationFilm
    }

    // MARK: - PaginationFilm
    struct PaginationFilm: Decodable {
        let items: [FilmItem]
    }

    // MARK: - Item
    struct FilmItem: Decodable {
        let name: String
        let nameEs: String?
        let slug: String
        let posterPath: String
        enum CodingKeys: String, CodingKey {
            case name
            case nameEs = "name_es"
            case slug
            case posterPath = "poster_path"
        }
    }

    struct DetailFilmResponse: Decodable {
        let data: DetailFilmContainer
    }

    // MARK: - DataClass
    struct DetailFilmContainer: Decodable {
        let detailFilm: DetailFilm
    }

    // MARK: - DetailFilm
    struct DetailFilm: Codable {
        let name: String?
        let nameEs: String?
        let posterPath: String
        let linksOnline: [LinksOnline]

        enum CodingKeys: String, CodingKey {
            case name
            case nameEs = "name_es"
            case posterPath = "poster_path"
            case linksOnline = "links_online"
        }

    }

    // MARK: - LinksOnline
    struct LinksOnline: Codable {
        let link: URL
    }

    // MARK: - Welcome
    struct SeriesListingResponse: Codable {
        let data: SeriesListingDataClass
    }

    // MARK: - DataClass
    struct SeriesListingDataClass: Codable {
        let paginationSerie: PaginationSerie
    }

    // MARK: - PaginationSerie
    struct PaginationSerie: Codable {
        let items: [SerieItem]
    }

    // MARK: - Item
    struct SerieItem: Codable {
        let name: String?
        let nameEs: String?
        let slug: String
        let posterPath: String

        enum CodingKeys: String, CodingKey {
            case name = "name"
            case nameEs = "name_es"
            case slug = "slug"
            case posterPath = "poster_path"
        }
    }

    struct ListEpisodesResponse: Codable {
        let data: ListEpisodesDataClass
    }

    // MARK: - DataClass
    struct ListEpisodesDataClass: Codable {
        let paginationEpisode: PaginationEpisode
    }

    // MARK: - PaginationEpisode
    struct PaginationEpisode: Codable {
        let items: [ListEpisodesItem]
    }

    // MARK: - Item
    struct ListEpisodesItem: Codable {
        let episodeNumber: Int
        let seasonNumber: Int
        let linksOnline: [LinksOnline]

        enum CodingKeys: String, CodingKey {
            case episodeNumber = "episode_number"
            case seasonNumber = "season_number"
            case linksOnline = "links_online"
        }
    }

    // MARK: - Welcome
    struct SearchResponse: Codable {
        let data: SearchDataClass

        enum CodingKeys: String, CodingKey {
            case data = "data"
        }
    }

    struct SearchDataClass: Codable {
        let searchFilm: [SearchItem]?
        let searchSerie: [SearchItem]?

        enum CodingKeys: String, CodingKey {
            case searchFilm = "searchFilm"
            case searchSerie = "searchSerie"
        }
    }

    // MARK: - SearchFilm
    struct SearchItem: Codable {
        let slug: String
        let name: String?
        let nameEs: String?
        let posterPath: String

        enum CodingKeys: String, CodingKey {
            case slug = "slug"
            case name = "name"
            case nameEs = "name_es"
            case posterPath = "poster_path"
        }
    }

    struct DetailSerieResponse: Codable {
        let data: DetailSerieDataClass

        enum CodingKeys: String, CodingKey {
            case data
        }
    }

    // MARK: - DataClass
    struct DetailSerieDataClass: Codable {
        let detailSerie: DetailSerie

        enum CodingKeys: String, CodingKey {
            case detailSerie
        }
    }

    // MARK: - DetailSerieById
    struct DetailSerie: Codable {
        let id: String
        let name: String
        let nameEs: String
        let slug: String
        let posterPath: String
        let numberOfSeasons: Int

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case name
            case nameEs = "name_es"
            case slug
            case posterPath = "poster_path"
            case numberOfSeasons = "number_of_seasons"
        }
    }

}
