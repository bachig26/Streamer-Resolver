import Foundation

import SwiftSoup

struct StreamSBResolver: Resolver {
    static let domains: [String] = [
        "sbfull.com",
        "sbplay2.xyz",
        "sbplay1.com",
        "sbplay2.com",
        "sbplay3.com",
        "cloudemb.com",
        "sbplay.org",
        "embedsb.com",
        "pelistop.co",
        "streamsb.net",
        "sbplay.one",
        "sbplay2.xyz",
        "watchsb.com",
        "streamsss.net"
    ]

    private let apiPath: String = "https://sbplay2.com/sources43/566d337678566f743674494a7c7c\("HEXVIDEOID")7c7c346b6767586d6934774855537c7c73747265616d7362/6565417268755339773461447c7c346133383438333436313335376136323337373433383634376337633465366534393338373136643732373736343735373237613763376334363733353737303533366236333463353333363534366137633763373337343732363536313664373336327c7c6b586c3163614468645a47617c7c73747265616d7362"

    enum StreamSBResolverError: Error {
        case urlNotValid
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let videoID = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "embed-", with: "")
        let hexVideoID = Data(videoID.utf8).map { String(format: "%x", $0 ) }.joined()
        let sourceURLString = self.apiPath
            .replacingOccurrences(of: "HEXVIDEOID", with: hexVideoID)
        guard let sourceURL = URL(string: sourceURLString) else {
            throw StreamSBResolverError.urlNotValid
        }
        let data = try await Utilities.requestData(url: sourceURL)
        let decoder = JSONCoder.decoder
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let streamData = try decoder.decode(StreamSBAPIResponse.self, from: data).streamData
        let headers = [
            "sec-ch-ua": "\".Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"103\", \"Chromium\";v=\"103\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "DNT": "1",
            "Upgrade-Insecure-Requests": "1",
            "User-Agent": Constants.userAgent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-User": "?1",
            "Sec-Fetch-Dest": "document",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8"
        ]
        var streams: [Stream] = []
        streamData.file.map { streams.append(.init(reslover: "StreamSB", streamURL: $0, headers: headers))}
        streamData.backup.map { streams.append(.init(reslover: "StreamSB Backup", streamURL: $0, headers: headers))}
        return streams
    }

    private struct StreamSBAPIResponse: Codable {
        let streamData: StreamData
    }

    private struct StreamData: Codable {
        let file: URL?
        let backup: URL?
    }
}
