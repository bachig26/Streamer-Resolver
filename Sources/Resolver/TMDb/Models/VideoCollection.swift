import Foundation

/// A collection of videos images for a movie or TV show.
public struct VideoCollection: Decodable, Equatable, Hashable {

    /// Videos.
    public let results: [VideoMetadata]

    /// Creates a new `VideoCollection`.
    ///
    /// - Parameters:
    ///    - id: Movie or TV show identifier.
    ///    - results: Videos.
    public init(results: [VideoMetadata]) {
        self.results = results
    }

}
