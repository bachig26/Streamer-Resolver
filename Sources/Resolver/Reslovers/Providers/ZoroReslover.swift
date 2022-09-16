import Foundation
import SwiftSoup

struct ZoroReslover: Resolver {
    static let domains: [String] = ["zoro.to"]
    private let baseURL: URL = URL(staticString: "https://zoro.to/")

    func getMediaURL(url: URL) async throws -> [Stream] {
        let sources = try await getSources(url: url)
        var finalSources = await sources.asyncMap {
            return try? await HostsResolver.resloveURL(url: $0.hostURL)
        }
            .compactMap { $0

            }
            .flatMap { $0 }

        let subtitles = finalSources.map {
            $0.subtitles
        }.flatMap { $0 }.unique()

        for i in finalSources.indices {
            finalSources[i].subtitles = subtitles
        }

        return finalSources
    }

    func getSources(url: URL) async throws -> [Source] {
        let data = try await Utilities.requestData(url: url)
        let serversResponse = try JSONCoder.decoder.decode(Response.self, from: data)
        let document = try SwiftSoup.parse(serversResponse.html)
        let rows: Elements = try document.select(".server-item")
        var sources = try await rows.array().asyncMap { row -> Source in
            let id: String = try row.attr("data-id")
            let url = self.baseURL.appendingPathComponent("ajax/v2/episode/sources").appending(["id": id])
            let data = try await Utilities.requestData(url: url)
            let serversResponse = try JSONCoder.decoder.decode(MediaResponse.self, from: data)
            return Source(hostURL: serversResponse.link)
        }

        let rapidCloudSources  = sources.filter {$0.hostURL.host == "rapid-cloud.co" }
        if rapidCloudSources.count > 1 {
            sources.removeAll { source in
                source.hostURL.host == "rapid-cloud.co"
            }
            sources.append(rapidCloudSources.first!)
        }
        return sources
    }

    struct Response: Codable {
        let html: String
    }
    struct MediaResponse: Codable {
        let link: URL
    }

}
