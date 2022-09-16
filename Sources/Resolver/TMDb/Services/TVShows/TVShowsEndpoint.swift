import Foundation

enum TVShowsEndpoint {

    static let basePath = URL(string: "/tv")!

    case details(tvShowID: TMDBTVShow.ID)
    case credits(tvShowID: TMDBTVShow.ID)
    case reviews(tvShowID: TMDBTVShow.ID, page: Int? = nil)
    case images(tvShowID: TMDBTVShow.ID)
    case videos(tvShowID: TMDBTVShow.ID)
    case recommendations(tvShowID: TMDBTVShow.ID, page: Int? = nil)
    case similar(tvShowID: TMDBTVShow.ID, page: Int? = nil)
    case popular(page: Int? = nil)
    case externalId(tvShowID: TMDBTVShow.ID, seasonNumber: Int, epsoideNumber: Int)

}

extension TVShowsEndpoint: Endpoint {

    var url: URL {
        switch self {
        case .details(let tvShowID):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appending(["append_to_response": "videos,credits"])

        case .credits(let tvShowID):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appendingPathComponent("credits")

        case .reviews(let tvShowID, let page):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appendingPathComponent("reviews")
                .appendingPage(page)

        case .images(let tvShowID):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appendingPathComponent("images")

        case .videos(let tvShowID):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appendingPathComponent("videos")

        case .recommendations(let tvShowID, let page):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appendingPathComponent("recommendations")
                .appendingPage(page)

        case .similar(let tvShowID, let page):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appendingPathComponent("similar")
                .appendingPage(page)

        case .popular(let page):
            return Self.basePath
                .appendingPathComponent("popular")
                .appendingPage(page)

            // season/1/episode/1/external_ids
        case let .externalId(tvShowID, seasonNumber, epsoideNumber):
            return Self.basePath
                .appendingPathComponent(tvShowID)
                .appendingPathComponent("season")
                .appendingPathComponent(seasonNumber)
                .appendingPathComponent("episode")
                .appendingPathComponent(epsoideNumber)
                .appendingPathComponent("external_ids")
        }
    }

}
