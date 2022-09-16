import Foundation
import SwiftSoup

struct StreamingCommunityReslover: Resolver {
    static let domains: [String] = ["streamingcommunity.xyz", "streamingcommunity.one", "streamingcommunity.vip",
                                    "streamingcommunity.work", "streamingcommunity.name", "streamingcommunity.video",
                                    "streamingcommunity.live", "streamingcommunity.tv", "streamingcommunity.space",
                                    "streamingcommunity.art", "streamingcommunity.fun", "streamingcommunity.website",
                                    "streamingcommunity.host", "streamingcommunity.site", "streamingcommunity.bond",
                                    "streamingCommunity.icu", "streamingcommunity.bar", "streamingcommunity.top",
                                    "streamingcommunity.cc", "streamingcommunity.monster", "streamingcommunity.press",
                                    "streamingcommunity.business", "streamingcommunity.org", "streamingcommunity.best",
                                    "streamingcommunity.agency", "streamingcommunity.blog"]

    func getMediaURL(url: URL) async throws -> [Stream] {
        var headers = [
            "origin": url.host!,
            "referer": url.host!,
            "Sec-Fetch-Site": "cross-site",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Accept-Encoding": ""
        ]

        let pageContent = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(pageContent)
        let rows = try document.select("video-player").attr("response")
        let data = rows.data(using: .utf8)!
        let response = try JSONCoder.decoder.decode(MediaResponse.self, from: data)
        let expire = Int(Date().timeIntervalSince1970 + 172800)

        let ipData = try await Utilities.requestData(url: .init(string: "https://scws.xyz/videos/\(response.scws_id)")!)
        let ipResponse = try JSONCoder.decoder.decode(Response.self, from: ipData)
        let uno = "\(expire)\(ipResponse.client_ip) Yc8U6r8KjAKAepEA"
        let token = uno.data(using: .utf8)?.md5().toBase64URL() ?? ""
        let m3umURL = try URL("streamer://scws.xyz/master/\(response.scws_id)?token=\(token)&expires=\(expire)")
        headers["base_url"] = "https://sc-\(ipResponse.cdn.type)\(ipResponse.cdn.number)-01.scws-content.net/hls/\(ipResponse.storage.number)/\(ipResponse.folder_id)"
        return [.init(reslover: "StreamingCommunity", streamURL: m3umURL, quality: .init(quality: "\(ipResponse.quality ?? 0)"), headers: headers)]
    }

    struct Response: Codable {
        let client_ip: String
        let folder_id: String
        let host: String
        let storage: Storage
        let cdn: CDN
        let quality: Int?
    }
    struct CDN: Codable {
        let id: Int
        let number: Int
        let type: String
    }
    struct Storage: Codable {
        let id: Int
        let number: Int
    }

    struct MediaResponse: Codable {
        let scws_id: Int
    }

}
