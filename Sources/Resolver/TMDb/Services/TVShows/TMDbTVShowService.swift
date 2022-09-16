import Foundation

#if canImport(Combine)
import Combine
#endif

final class TMDbTVShowProvider: TVShowProvider {

    private let apiClient: APIClient

    init(apiClient: APIClient = TMDbAPIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchDetails(forTVShow id: TMDBTVShow.ID, completion: @escaping (Result<TMDBTVShow, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.details(tvShowID: id), completion: completion)
    }

    func fetchCredits(forTVShow tvShowID: TMDBTVShow.ID, completion: @escaping (Result<ShowCredits, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.credits(tvShowID: tvShowID), completion: completion)
    }

    func fetchReviews(forTVShow tvShowID: TMDBTVShow.ID, page: Int?,
                      completion: @escaping (Result<ReviewPageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.reviews(tvShowID: tvShowID, page: page), completion: completion)
    }

    func fetchImages(forTVShow tvShowID: TMDBTVShow.ID,
                     completion: @escaping (Result<ImageCollection, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.images(tvShowID: tvShowID), completion: completion)
    }

    func fetchVideos(forTVShow tvShowID: TMDBTVShow.ID,
                     completion: @escaping (Result<VideoCollection, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.videos(tvShowID: tvShowID), completion: completion)
    }

    func fetchRecommendations(forTVShow tvShowID: TMDBTVShow.ID, page: Int?,
                              completion: @escaping (Result<TVShowPageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.recommendations(tvShowID: tvShowID, page: page), completion: completion)
    }

    func fetchSimilar(toTVShow tvShowID: TMDBTVShow.ID, page: Int?,
                      completion: @escaping (Result<TVShowPageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.similar(tvShowID: tvShowID, page: page), completion: completion)
    }

    func fetchPopular(page: Int?, completion: @escaping (Result<TVShowPageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: TVShowsEndpoint.popular(page: page), completion: completion)
    }

}

#if canImport(Combine)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension TMDbTVShowProvider {

    func detailsPublisher(forTVShow id: TMDBTVShow.ID) -> AnyPublisher<TMDBTVShow, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.details(tvShowID: id))
    }

    func creditsPublisher(forTVShow tvShowID: TMDBTVShow.ID) -> AnyPublisher<ShowCredits, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.credits(tvShowID: tvShowID))
    }

    func reviewsPublisher(forTVShow tvShowID: TMDBTVShow.ID,
                          page: Int?) -> AnyPublisher<ReviewPageableList, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.reviews(tvShowID: tvShowID, page: page))
    }

    func imagesPublisher(forTVShow tvShowID: TMDBTVShow.ID) -> AnyPublisher<ImageCollection, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.images(tvShowID: tvShowID))
    }

    func videosPublisher(forTVShow tvShowID: TMDBTVShow.ID) -> AnyPublisher<VideoCollection, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.videos(tvShowID: tvShowID))
    }

    func recommendationsPublisher(forTVShow tvShowID: TMDBTVShow.ID,
                                  page: Int?) -> AnyPublisher<TVShowPageableList, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.recommendations(tvShowID: tvShowID, page: page))
    }

    func similarPublisher(toTVShow tvShowID: TMDBTVShow.ID,
                          page: Int?) -> AnyPublisher<TVShowPageableList, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.similar(tvShowID: tvShowID, page: page))
    }

    func popularPublisher(page: Int?) -> AnyPublisher<TVShowPageableList, TMDbError> {
        apiClient.get(endpoint: TVShowsEndpoint.popular(page: page))
    }

}
#endif

#if swift(>=5.5) && !os(Linux)
@available(macOS 12, iOS 14.0, tvOS 14.0, watchOS 8.0, *)
extension TMDbTVShowProvider {

    func details(forTVShow id: TMDBTVShow.ID) async throws -> TMDBTVShow {
        try await apiClient.get(endpoint: TVShowsEndpoint.details(tvShowID: id))
    }

    func credits(forTVShow tvShowID: TMDBTVShow.ID) async throws -> ShowCredits {
        try await apiClient.get(endpoint: TVShowsEndpoint.credits(tvShowID: tvShowID))
    }

    func reviews(forTVShow tvShowID: TMDBTVShow.ID, page: Int?) async throws -> ReviewPageableList {
        try await apiClient.get(endpoint: TVShowsEndpoint.reviews(tvShowID: tvShowID, page: page))
    }

    func images(forTVShow tvShowID: TMDBTVShow.ID) async throws -> ImageCollection {
        try await apiClient.get(endpoint: TVShowsEndpoint.images(tvShowID: tvShowID))
    }

    func videos(forTVShow tvShowID: TMDBTVShow.ID) async throws -> VideoCollection {
        try await apiClient.get(endpoint: TVShowsEndpoint.videos(tvShowID: tvShowID))
    }

    func recommendations(forTVShow tvShowID: TMDBTVShow.ID, page: Int?) async throws -> TVShowPageableList {
        try await apiClient.get(endpoint: TVShowsEndpoint.recommendations(tvShowID: tvShowID, page: page))
    }

    func similar(toTVShow tvShowID: TMDBTVShow.ID, page: Int?) async throws -> TVShowPageableList {
        try await apiClient.get(endpoint: TVShowsEndpoint.similar(tvShowID: tvShowID, page: page))
    }

    func popular(page: Int?) async throws -> TVShowPageableList {
        try await apiClient.get(endpoint: TVShowsEndpoint.popular(page: page))
    }

    func externalID(forTVShow id: TMDBTVShow.ID, seasonNumber: Int, epsoideNumber: Int) async throws -> ExternalID {
        try await apiClient.get(endpoint: TVShowsEndpoint.externalId(tvShowID: id, seasonNumber: seasonNumber, epsoideNumber: epsoideNumber))
    }

}
#endif
