import Foundation
import SwiftSoup

struct TwoEmbedReslover: Resolver {
    static let domains: [String] = ["2embed.to"]
    let baseURL: URL = URL(staticString: "https://2embed.to")

    enum TwoEmbedResloverError: Error {
        case capchaKeyNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let captchaURL = try pageDocument.select("script[src*=https://www.google.com/recaptcha/api.js?render=]").attr("src")

        guard let range = captchaURL.range(of: "render=") else {
            throw TwoEmbedResloverError.capchaKeyNotFound
        }

        let captchaKey = String(captchaURL[range.upperBound...])
        return try await pageDocument.select(".dropdown-menu a[data-id]")
            .array()
            .asyncMap { row -> [Stream]? in
                let serverId =  try row.attr("data-id")
                guard let token = try await Utilities.getCaptchaToken(url: url, key: captchaKey) else {
                    throw TwoEmbedResloverError.capchaKeyNotFound
                }
                let serverURL = baseURL.appendingPathComponent("ajax/embed/play")
                    .appendingQueryItem(name: "id", value: serverId)
                    .appendingQueryItem(name: "_token", value: token)
                let data = try await Utilities.requestData(url: serverURL, extraHeaders: ["referer": url.absoluteString])
                let embed = try JSONCoder.decoder.decode(EmbedJSON.self, from: data)
                let subtitles = try await self.getSubtitles(url: embed.link)
                return try? await HostsResolver.resloveURL(url: embed.link).map {
                    Stream(stream: $0, subtitles: subtitles)
                }
            }
            .compactMap { $0 }
            .flatMap { $0 }
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

    struct EmbedJSON: Codable {
        let link: URL
    }
    struct SubtitleResponse: Codable {
        let file: URL
        let label: String
        let kind: String
    }
}
