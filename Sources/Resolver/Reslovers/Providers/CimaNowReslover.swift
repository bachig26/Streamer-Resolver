import Foundation
import SwiftSoup

struct CimaNowReslover: Resolver {
    static let domains: [String] = ["cimanow.cc"]
    private let directStreamDomains: [String] = ["cn.box.com", "cimanow.net"]

    func getMediaURL(url: URL) async throws -> [Stream] {

        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let rows: Elements = try document.select("#download > li > a")
        return rows.array().compactMap { row -> Stream? in
            if let path = try? row.attr("href"), let url = URL(string: path) {
                let quality =  (try? row.text())
                return Stream(reslover: url.host ?? "CimaNow", streamURL: url, quality: Quality(quality: quality))
            } else {
                return nil
            }
        }
        .filter { stream in
            return directStreamDomains.reduce(false) { partialResult, host in
                stream.streamURL.absoluteString.contains(host) || partialResult
            }
        }
    }
}
