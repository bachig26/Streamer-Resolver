import Foundation

struct StreamlareResolver: Resolver {
    static let domains: [String] = ["streamlare.com", "slmaxed.com", "sltube.org", "slwatch.co"]
    enum StreamlareResolverError: Error {
        case urlNotValid
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let id = url.lastPathComponent
        let url = URL(string: "https://\(url.host!)/api/video/stream/get")!
        let data  = try await Utilities.requestData(url: url, httpMethod: "POST", data: "{\"id\":\"\(id)\"}".data(using: .utf8))
        let content = try JSONCoder.decoder.decode(Response.self, from: data)
        guard case .object(let value) = content.result else {
            throw StreamlareResolverError.urlNotValid
        }
        return value.compactMap { key, value -> Stream? in
            guard case .string(let path) = value["file"], let url = URL(string: path) else { return nil }
            return .init(reslover: "StreamLare", streamURL: url, quality: Quality(quality: key))
        }
    }

    struct Response: Codable {
        let result: JSONValue
    }
}
