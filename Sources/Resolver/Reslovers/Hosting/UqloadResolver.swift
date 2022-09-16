import Foundation
import SwiftSoup

struct UqloadResolver: Resolver {
    static let domains: [String] = ["uqload.com"]

    enum UqloadResolverError: Error {
        case videoNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url, extraHeaders: ["referer": "https://pelispluss.net/"])
        let pageDocument = try SwiftSoup.parse(pageContent)
        let script = try pageDocument.select("script").filter {
            try $0.html().contains("Clappr.Player")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script).filter({ $0.pathExtension == "mp4"}).first else {
            throw UqloadResolverError.videoNotFound
        }
        return [.init(reslover: "Uqload", streamURL: path)]
    }

}
