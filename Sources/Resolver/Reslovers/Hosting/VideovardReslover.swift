import Foundation
import SwiftSoup

struct VideovardReslover: Resolver {
    static let domains: [String] = ["videovard.to"]
    private let baseURL: URL = URL(staticString: "https://videovard.to/api")

    enum VideovardResloverError: Error {
        case urlNotValid
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let resourceIdentifier = url.lastPathComponent
        let hashURL = baseURL
            .appendingPathComponent("make")
            .appendingPathComponent("hash")
            .appendingPathComponent(resourceIdentifier)

        let data = try await Utilities.requestData(url: hashURL)
        let hashResponse = try JSONCoder.decoder.decode(HashResponse.self, from: data)

        let playerSetupURL = baseURL
            .appendingPathComponent("player")
            .appendingPathComponent("setup")

        let boundary = "Boundary-\(UUID().uuidString)"
        let extraHeaders = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        let postData = [
            "cmd": "get_stream",
            "file_code": resourceIdentifier,
            "hash": hashResponse.hash
        ]
        let httpBody = NSMutableData()

        for (key, value) in postData {
            httpBody.appendString(convertFormField(named: key, value: value, using: boundary))
        }
        httpBody.appendString("--\(boundary)--")

        let playerData = try await Utilities.requestData(
            url: playerSetupURL,
            httpMethod: "POST",
            data: httpBody as Data,
            extraHeaders: extraHeaders
        )
        let setupResponse = try JSONCoder.decoder.decode(SetupResponse.self, from: playerData)
        let fileAsset =  try Utilities.tearDecode(file: setupResponse.src, seed: setupResponse.seed)

        guard let url = URL(string: fileAsset) else {
            throw VideovardResloverError.urlNotValid
        }
        let subtitles = setupResponse.tracks.compactMap { track -> Subtitle? in
            guard let language = SubtitlesLangauge(rawValue: track.label) else { return nil}
            return Subtitle(url: track.file, language: language)
        }
        return [.init(reslover: "Videovard", streamURL: url, subtitles: subtitles)]
    }

    func convertFormField(named name: String, value: String, using boundary: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

}
extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

// MARK: - Request-Related Structs
extension VideovardReslover {
    struct HashResponse: Decodable {
        var hash: String
    }

    struct SetupResponse: Decodable {
        var src: String
        var tracks: [Track]
        var seed: String
    }

    struct Track: Decodable {
        let file: URL
        let label: String
    }
}
