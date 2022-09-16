import Foundation
import SwiftSoup

struct StreamtapeReslover: Resolver {
    static let domains: [String] = [
        "streamtape.com"
    ]

    enum StreamtapeResloverError: Error {
        case urlNotValid
        case redirectTokenNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        guard let embedUrl = URL(string: url.absoluteString.replacingOccurrences(of: "/v/", with: "/e/")) else {
            throw StreamtapeResloverError.urlNotValid
        }

        let content = try await  Utilities.downloadPage(url: embedUrl)
        let document = try SwiftSoup.parse(content)
        let path = try document.select("#ideoolink").text()
        let tokenPattern = #"getElementById\('robotlink'\)\.innerHTML[^\n]*token=(?<token>[A-Za-z0-9-_]*)"#
        let tokenRegex = try NSRegularExpression(pattern: tokenPattern, options: [])

        guard let tokenMatch = tokenRegex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.count)) else {
            throw StreamtapeResloverError.redirectTokenNotFound
        }

        let tokenMatchRange = tokenMatch.range(at: 1)
        guard let tokenRange = Range(tokenMatchRange, in: content) else {
            throw StreamtapeResloverError.redirectTokenNotFound
        }

        let token = String(content[tokenRange])

        guard var urlComponents = URLComponents(string: "https:/\(path)&stream=1"),
              let index = urlComponents.queryItems?.firstIndex(where: { item in
                  item.name == "token"
              }) else {
            throw StreamtapeResloverError.urlNotValid
        }

        urlComponents.queryItems?.remove(at: index)
        urlComponents.queryItems?.append(.init(name: "token", value: token))

        guard let streamURL = urlComponents.url else {
            throw StreamtapeResloverError.urlNotValid

        }
        return [.init(reslover: "StreamTape", streamURL: streamURL)]
    }
}
