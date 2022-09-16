import Foundation
import SwiftSoup

struct PelisplussResolver: Resolver {
    static let domains: [String] = ["pelispluss.net"]

    enum PelisplussResolverError: Error {
        case urlNotValid

    }

    func getMediaURL(url: URL) async throws -> [Stream] {
       let headers = [
            "Host": "pelispluss.net",
            "sec-ch-ua": "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"102\", \"Google Chrome\";v=\"102\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "dnt": "1",
            "upgrade-insecure-requests": "1",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36",
            "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
            "sec-fetch-site": "none",
            "sec-fetch-mode": "navigate",
            "sec-fetch-user": "?1",
            "sec-fetch-dest": "document",
            "accept-language": "en-US,en;q=0.9,ar;q=0.8"
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        let (data, _)  = try await ResloverURLSession.shared.session.asyncData(for: request)
        let pageDocument = try SwiftSoup.parse(String(data: data, encoding: .utf8) ?? "")
        if url.absoluteString.contains("embed.php") {
            let html = try pageDocument.select(".ODDIV").html()
            let streams = try await Utilities.extractURLs(content: html).asyncMap {
                return try await HostsResolver.resloveURL(url: $0)
            }.flatMap { $0 }
            return streams
        }

        if let h = url.queryParameters?["h"] {
            var rRequest = URLRequest(url: .init(staticString: "https://pelispluss.net/sc/r.php"))
            rRequest.httpMethod = "POST"
            rRequest.httpBody = "h=\(h)".data(using: .utf8)
            let (_, rResponse)  = try await ResloverURLSession.shared.session.asyncData(for: rRequest)
            return try await HostsResolver.resloveURL(url: rResponse.url!)
        }

        throw PelisplussResolverError.urlNotValid
    }
}
