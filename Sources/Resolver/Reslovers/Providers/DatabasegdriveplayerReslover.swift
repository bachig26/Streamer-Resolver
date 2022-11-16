import Foundation
import SwiftSoup

struct DatabasegdriveplayerReslover: Resolver {
    static let domains: [String] = ["databasegdriveplayer.xyz"]

    enum TwoEmbedResloverError: Error {
        case capchaKeyNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        return try await pageDocument.select("#list-server-more a").array()
            .filter { row in
                (try? row.attr("href").contains("membed.net")) == true
            }
            .map {try "https:" + $0.attr("href")}
            .compactMap { URL(string:$0)}
            .concurrentMap {
                return try await HostsResolver.resloveURL(url: $0)
            }
            .flatMap { $0 }
    }

}
