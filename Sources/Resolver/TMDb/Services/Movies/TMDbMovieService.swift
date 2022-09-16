import Foundation

#if canImport(Combine)
import Combine
#endif

final class TMDbMovieProvider: MovieProvider {

    private let apiClient: APIClient

    init(apiClient: APIClient = TMDbAPIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchDetails(forMovie id: TMDBMovie.ID, completion: @escaping (Result<TMDBMovie, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.details(movieID: id), completion: completion)
    }

    func fetchCredits(forMovie movieID: TMDBMovie.ID, completion: @escaping (Result<ShowCredits, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.credits(movieID: movieID), completion: completion)
    }

    func fetchReviews(forMovie movieID: TMDBMovie.ID, page: Int?,
                      completion: @escaping (Result<ReviewPageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.reviews(movieID: movieID, page: page), completion: completion)
    }

    func fetchImages(forMovie movieID: TMDBMovie.ID, completion: @escaping (Result<ImageCollection, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.images(movieID: movieID), completion: completion)
    }

    func fetchVideos(forMovie movieID: TMDBMovie.ID, completion: @escaping (Result<VideoCollection, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.videos(movieID: movieID), completion: completion)
    }

    func fetchRecommendations(forMovie movieID: TMDBMovie.ID, page: Int?,
                              completion: @escaping (Result<MoviePageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.recommendations(movieID: movieID, page: page), completion: completion)
    }

    func fetchSimilar(toMovie movieID: TMDBMovie.ID, page: Int?,
                      completion: @escaping (Result<MoviePageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.similar(movieID: movieID, page: page), completion: completion)
    }

    func fetchNowPlaying(page: Int?, completion: @escaping (Result<MoviePageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.nowPlaying(page: page), completion: completion)
    }

    func fetchPopular(page: Int?, completion: @escaping (Result<MoviePageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.popular(page: page), completion: completion)
    }

    func fetchTopRated(page: Int?, completion: @escaping (Result<MoviePageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.topRated(page: page), completion: completion)
    }

    func fetchUpcoming(page: Int?, completion: @escaping (Result<MoviePageableList, TMDbError>) -> Void) {
        apiClient.get(endpoint: MoviesEndpoint.upcoming(page: page), completion: completion)
    }

}

#if canImport(Combine)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension TMDbMovieProvider {

    func detailsPublisher(forMovie id: TMDBMovie.ID) -> AnyPublisher<TMDBMovie, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.details(movieID: id))
    }

    func creditsPublisher(forMovie movieID: TMDBMovie.ID) -> AnyPublisher<ShowCredits, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.credits(movieID: movieID))
    }

    func reviewsPublisher(forMovie movieID: TMDBMovie.ID, page: Int?) -> AnyPublisher<ReviewPageableList, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.reviews(movieID: movieID, page: page))
    }

    func imagesPublisher(forMovie movieID: TMDBMovie.ID) -> AnyPublisher<ImageCollection, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.images(movieID: movieID))
    }

    func videosPublisher(forMovie movieID: TMDBMovie.ID) -> AnyPublisher<VideoCollection, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.videos(movieID: movieID))
    }

    func recommendationsPublisher(forMovie movieID: TMDBMovie.ID,
                                  page: Int?) -> AnyPublisher<MoviePageableList, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.recommendations(movieID: movieID, page: page))
    }

    func similarPublisher(toMovie movieID: TMDBMovie.ID, page: Int?) -> AnyPublisher<MoviePageableList, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.similar(movieID: movieID, page: page))
    }

    func nowPlayingPublisher(page: Int?) -> AnyPublisher<MoviePageableList, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.nowPlaying(page: page))
    }

    func popularPublisher(page: Int?) -> AnyPublisher<MoviePageableList, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.popular(page: page))
    }

    func topRatedPublisher(page: Int?) -> AnyPublisher<MoviePageableList, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.topRated(page: page))
    }

    func upcomingPublisher(page: Int?) -> AnyPublisher<MoviePageableList, TMDbError> {
        apiClient.get(endpoint: MoviesEndpoint.upcoming(page: page))
    }

}
#endif

#if swift(>=5.5) && !os(Linux)
@available(macOS 12, iOS 14.0, tvOS 14.0, watchOS 8.0, *)
extension TMDbMovieProvider {

    func details(forMovie id: TMDBMovie.ID) async throws -> TMDBMovie {
        try await apiClient.get(endpoint: MoviesEndpoint.details(movieID: id))
    }

    func credits(forMovie movieID: TMDBMovie.ID) async throws -> ShowCredits {
        try await apiClient.get(endpoint: MoviesEndpoint.credits(movieID: movieID))
    }

    func reviews(forMovie movieID: TMDBMovie.ID, page: Int?) async throws -> ReviewPageableList {
        try await apiClient.get(endpoint: MoviesEndpoint.reviews(movieID: movieID, page: page))
    }

    func images(forMovie movieID: TMDBMovie.ID) async throws -> ImageCollection {
        try await apiClient.get(endpoint: MoviesEndpoint.images(movieID: movieID))
    }

    func videos(forMovie movieID: TMDBMovie.ID) async throws -> VideoCollection {
        try await apiClient.get(endpoint: MoviesEndpoint.videos(movieID: movieID))
    }

    func recommendations(forMovie movieID: TMDBMovie.ID, page: Int?) async throws -> MoviePageableList {
        try await apiClient.get(endpoint: MoviesEndpoint.recommendations(movieID: movieID, page: page))
    }

    func similar(toMovie movieID: TMDBMovie.ID, page: Int?) async throws -> MoviePageableList {
        try await apiClient.get(endpoint: MoviesEndpoint.similar(movieID: movieID, page: page))
    }

    func nowPlaying(page: Int?) async throws -> MoviePageableList {
        try await apiClient.get(endpoint: MoviesEndpoint.nowPlaying(page: page))
    }

    func popular(page: Int?) async throws -> MoviePageableList {
        try await apiClient.get(endpoint: MoviesEndpoint.popular(page: page))
    }

    func topRated(page: Int?) async throws -> MoviePageableList {
        try await apiClient.get(endpoint: MoviesEndpoint.topRated(page: page))
    }

    func upcoming(page: Int?) async throws -> MoviePageableList {
        try await apiClient.get(endpoint: MoviesEndpoint.upcoming(page: page))
    }

}
#endif
