import Foundation

/// this class is about creating a default json coder to in order to support decoding/encoding strategies e.g. for dates
public final class JSONCoder {

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let encodedDate = try container.decode(String.self)

            guard let date = DateCoder.decode(string: encodedDate) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date format!")
            }

            return date
        }
        return decoder
    }()

    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let encodedDate = DateCoder.encode(date: date)
            try container.encode(encodedDate)
        }
        return encoder
    }()
}
