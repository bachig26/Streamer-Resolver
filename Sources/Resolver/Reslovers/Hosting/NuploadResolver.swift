import Foundation
import SwiftSoup

struct NuploadResolver: Resolver {
    static let domains: [String] = ["nupload.xyz", "nupload.co", "nuuuppp.online"]

    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil || url.host?.contains("nupload") == true
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        guard url.absoluteString.contains("/watch/") else {
            return []
        }
        let pageContent = try await Utilities.downloadPage(url: url, parameters: ["h": ""], extraHeaders: [
            "sec-fetch-dest": "iframe",
            "referer": "https://pelisflix.uno/"
        ])
        guard let session = pageContent.matches(for: #"var sesz="(.+?)""#).last,
              let path = pageContent.matches(for: #"file:"(https:\/\/.+?)"\+sesz\+""#).first,
              let streamURL = URL(string: "\(path)\(session)") else {
            return []
        }
        return [.init(reslover: "NupLoad", streamURL: streamURL,
                      headers: [
                        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
                      ]
                     )
        ]
    }

}
