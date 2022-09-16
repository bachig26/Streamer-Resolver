import Foundation
import SwiftSoup

struct FlixtorReslover: Resolver {
    static let domains: [String] = ["flixtor.video", "tvshows88.com", "sflix.pro", "fmovies.to"]

    enum FlixtorResloverError: Error {
        case urlNotValid
    }
    let nineAnimeKey = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    var cipherKey: String {
        if let key = UserDefaults.standard.string(forKey: "flixtor_provider_cipher_key") {
            return key
        } else {
            return "DZmuZuXqa9O0z3b7"
        }
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let hostURL = try await getSources(url: url)
        let subtitles = try await self.getSubtitles(url: hostURL)

        return try await HostsResolver.resloveURL(url: hostURL).map {
            Stream(stream: $0, subtitles: subtitles)
        }
    }

    private func decodeURL(url: String) -> URL? {

        guard let text = decryptss(input: url, key: nineAnimeKey),
              let id = cipher(key: cipherKey, text: text).removingPercentEncoding else {
            return nil
        }

        return URL(string: id)

    }

    func getSources(url: URL) async throws -> URL {

        let data = try await Utilities.requestData(url: url)
        let movieEmbedResponse = try JSONCoder.decoder.decode(MediaResponse.self, from: data)

        guard let url = decodeURL(url: movieEmbedResponse.url) else {
            throw FlixtorResloverError.urlNotValid
        }
        return url

    }

    func getSubtitles(url: URL) async throws -> [Subtitle] {
        var subtitles: [Subtitle] = []
        if let subtitleInfo = url.queryParameters?["sub.info"],
           let subtitleURL = URL(string: subtitleInfo) {
            let data = try await Utilities.requestData(url: subtitleURL)
            let subtitlesResponse = try JSONCoder.decoder.decode([SubtitleResponse].self, from: data)

            subtitles = subtitlesResponse.compactMap {
                if let language = SubtitlesLangauge(rawValue: $0.label) {
                    return Subtitle(url: $0.file, language: language)
                } else {
                    return nil
                }
            }
        }
        return subtitles
    }

    struct MediaResponse: Codable {
        let url: String
    }
    struct SubtitleResponse: Codable {
        let file: URL
        let label: String
        let kind: String
    }

}
