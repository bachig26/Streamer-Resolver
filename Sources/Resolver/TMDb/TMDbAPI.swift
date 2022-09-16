import Foundation

/// The Movie Database API.
///
/// [The Movie Database API Documentation](https://developers.themoviedb.org)
/// 
/// The TMDb API provider is for those of you interested in using their movie, TV show or actor images and/or data in your application. Their API is a system they
/// provide for you and your team to programmatically fetch and use their data and/or images.
public final class TMDbAPI: MovieTVShowAPI {

    /// A shared instance of the TMDb API.
    public static let shared: MovieTVShowAPI = TMDbAPI()

    public let configurations: ConfigurationProvider
    public let movies: MovieProvider
    public let search: SearchProvider
    public let tvShows: TVShowProvider
    public let tvShowSeasons: TVShowSeasonProvider

    init(
        configurationProvider: ConfigurationProvider = TMDbConfigurationProvider(),
        movieProvider: MovieProvider = TMDbMovieProvider(),
        searchProvider: SearchProvider = TMDbSearchProvider(),
        tvShowProvider: TVShowProvider = TMDbTVShowProvider(),
        tvShowSeasonProvider: TVShowSeasonProvider = TMDbTVShowSeasonProvider()
    ) {
        self.configurations = configurationProvider
        self.movies = movieProvider
        self.search = searchProvider
        self.tvShows = tvShowProvider
        self.tvShowSeasons = tvShowSeasonProvider
    }

    public static func setAPIKey(_ apiKey: String) {
        TMDbAPIClient.setAPIKey(apiKey)
    }

}
