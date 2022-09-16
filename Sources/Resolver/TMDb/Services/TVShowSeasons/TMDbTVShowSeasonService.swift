import Foundation

#if canImport(Combine)
import Combine
#endif

final class TMDbTVShowSeasonProvider: TVShowSeasonProvider {

    private let apiClient: APIClient

    init(apiClient: APIClient = TMDbAPIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchDetails(forSeason seasonNumber: Int, inTVShow tvShowID: TMDBTVShow.ID,
                      completion: @escaping (Result<TVShowSeason, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowSeasonsEndpoint.details(tvShowID: tvShowID, seasonNumber: seasonNumber),
                      completion: completion)
    }

    func fetchImages(forSeason seasonNumber: Int, inTVShow tvShowID: TMDBTVShow.ID,
                     completion: @escaping (Result<ImageCollection, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowSeasonsEndpoint.images(tvShowID: tvShowID, seasonNumber: seasonNumber),
                      completion: completion)
    }

    func fetchVideos(forSeason seasonNumber: Int, inTVShow tvShowID: TMDBTVShow.ID,
                     completion: @escaping (Result<VideoCollection, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowSeasonsEndpoint.videos(tvShowID: tvShowID, seasonNumber: seasonNumber),
                      completion: completion)
    }

}

#if canImport(Combine)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension TMDbTVShowSeasonProvider {

    func detailsPublisher(forSeason seasonNumber: Int,
                          inTVShow tvShowID: TMDBTVShow.ID) -> AnyPublisher<TVShowSeason, TMDbError> {
        apiClient.get(endpoint: TVShowSeasonsEndpoint.details(tvShowID: tvShowID, seasonNumber: seasonNumber))
    }

    func imagesPublisher(forSeason seasonNumber: Int,
                         inTVShow tvShowID: TMDBTVShow.ID) -> AnyPublisher<ImageCollection, TMDbError> {
        apiClient.get(endpoint: TVShowSeasonsEndpoint.images(tvShowID: tvShowID, seasonNumber: seasonNumber))
    }

    func videosPublisher(forSeason seasonNumber: Int,
                         inTVShow tvShowID: TMDBTVShow.ID) -> AnyPublisher<VideoCollection, TMDbError> {
        apiClient.get(endpoint: TVShowSeasonsEndpoint.videos(tvShowID: tvShowID, seasonNumber: seasonNumber))
    }

}
#endif

#if swift(>=5.5) && !os(Linux)
@available(macOS 12, iOS 14.0, tvOS 14.0, watchOS 8.0, *)
extension TMDbTVShowSeasonProvider {

    func details(forSeason seasonNumber: Int, inTVShow tvShowID: TMDBTVShow.ID) async throws -> TVShowSeason {
        try await apiClient.get(endpoint: TVShowSeasonsEndpoint.details(tvShowID: tvShowID, seasonNumber: seasonNumber))
    }

    func images(forSeason seasonNumber: Int, inTVShow tvShowID: TMDBTVShow.ID) async throws -> ImageCollection {
        try await apiClient.get(endpoint: TVShowSeasonsEndpoint.images(tvShowID: tvShowID, seasonNumber: seasonNumber))
    }

    func videos(forSeason seasonNumber: Int, inTVShow tvShowID: TMDBTVShow.ID) async throws -> VideoCollection {
        try await apiClient.get(endpoint: TVShowSeasonsEndpoint.videos(tvShowID: tvShowID, seasonNumber: seasonNumber))
    }

}
#endif
