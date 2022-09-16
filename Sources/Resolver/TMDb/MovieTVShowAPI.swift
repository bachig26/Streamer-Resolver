import Foundation

/// The Movie Database API.
public protocol MovieTVShowAPI {

    /// Sets the API Key to be used with requests to the API.
    ///
    /// - Parameters
    ///     - apiKey: The API Key.
    static func setAPIKey(_ apiKey: String)

    /// Configurations.
    var configurations: ConfigurationProvider { get }

    /// Movies.
    var movies: MovieProvider { get }

    /// Search.
    var search: SearchProvider { get }

    /// TV Shows.
    var tvShows: TVShowProvider { get }

    /// TV Show Seasons.
    var tvShowSeasons: TVShowSeasonProvider { get }

}
