import Foundation
import SwiftyPyString

class MyCloudResolver: Resolver {
    static let domains: [String] = [
        "mcloud.to",
        "mwvn.vizcloud.info",
        "vidstream.pro",
        "vidstreamz.online",
        "vizcloud.cloud",
        "vizcloud.digital",
        "vizcloud.info",
        "vizcloud.live",
        "vizcloud.online",
        "vizcloud.xyz",
        "vizcloud2.online",
        "vizcloud2.ru"
    ]

    var keysURL: URL {
        if let path = UserDefaults.standard.string(forKey: "mycloud_keys_url"), let url = URL(string: path) {
            return url
        } else {
            return URL(staticString: "https://mcloud-url.onrender.com/")
        }
    }

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("vizcloud") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let info = url.absoluteString
            .replacingOccurrences(of: "https://", with: "")
        let eURL = keysURL.appending("url", value: info.encodeURIComponent())
        let encodedPath = try await Utilities.downloadPage(url: eURL)
        let encodedURL = try URL(encodedPath)
        let headers = [
            "User-Agent": Constants.userAgent,
            "Referer": url.absoluteString,
            "origin": url.absoluteString,
            "content-type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin"
        ]

        let data = try await Utilities.requestData(url: encodedURL, extraHeaders: headers)
        let content = try JSONCoder.decoder.decode(Response.self, from: data)

        return content.data.media.sources.compactMap {
            Stream(reslover: "VizCloud", streamURL: $0.file, quality: .unknown)
        }
    }
    struct Response: Codable {
        let status: Int
        let data: DData
    }
    struct DData: Codable {
        let media: Media
    }

    // MARK: - Media
    struct Media: Codable {
        let sources: [Source]
    }

    // MARK: - Source
    struct Source: Codable {
        let file: URL
    }
}
