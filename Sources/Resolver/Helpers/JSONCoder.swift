import Foundation

/// this class is about creating a default json coder to in order to support decoding/encoding strategies e.g. for dates
public final class JSONCoder {

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let encodedStringDate = try? container.decode(String.self) {
                guard let date = DateCoder.decode(string: encodedStringDate) else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported String date format!")
                }
                return date
            }

            if let encodedIntDate = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: encodedIntDate)
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported String date format!")
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
