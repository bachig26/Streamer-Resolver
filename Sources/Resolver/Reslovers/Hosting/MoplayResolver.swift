import Foundation

struct MoplayResolver: Resolver {
    static let domains: [String] = ["moplay.org"]

    enum MoplayResolverError: Error {
        case codeNotFound
        case dataRequestFailed
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let headers = [
            "User-Agent": Constants.userAgent,
            "Referer": url.absoluteString,
            "origin": "https://moplay.org",
            "content-type": "application/json",
            "x-requested-with": "XMLHttpRequest"
        ]

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        let (data, _)  = try await ResloverURLSession.shared.session.asyncData(for: request)
        let responseString = String(data: data, encoding: .utf8)
        guard let code = responseString?.matches(for: "'code': '([^{}]*)'").first else {
            throw MoplayResolverError.codeNotFound
        }

        let json: [String: String] = ["code": code]
        var dataRequest = URLRequest(url: .init(string: "https://moplay.org/data")!)
        dataRequest.httpMethod = "POST"
        dataRequest.allHTTPHeaderFields = headers
        dataRequest.httpBody = try? JSONSerialization.data(withJSONObject: json)
        let (urlData, _)  = try await ResloverURLSession.shared.session.asyncData(for: dataRequest)
        let content = try JSONCoder.decoder.decode(Response.self, from: urlData)
        guard let path = content.url.base64Decoded(),
              let mediaURL = URL(string: "https://moplay.org"+path) else {
                  throw MoplayResolverError.dataRequestFailed
              }
        return [.init(reslover: "MoPlay.com", streamURL: mediaURL) ]

    }

    struct Response: Equatable, Codable {
        let status: Bool
        let url: String
    }

}
