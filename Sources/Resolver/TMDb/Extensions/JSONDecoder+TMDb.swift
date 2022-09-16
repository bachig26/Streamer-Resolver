import Foundation

extension JSONDecoder {

    static var theMovieDatabase: JSONDecoder {
        let decoder = JSONCoder.decoder
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(.theMovieDatabase)
        return decoder
    }

}
