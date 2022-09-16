import Foundation

public struct ExternalID: Decodable, Equatable, Hashable {
    public let id: Int
    public let imdbID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case imdbID = "imdb_id"
    }

}
