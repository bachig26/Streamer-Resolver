import Foundation

import SwiftSoup

struct WatchSBResolver: Resolver {
    static let domains: [String] = [
        "watchsb.com",
        "streamsss.net"
    ]

    private let apiPath: String = "https://sbplay2.com"

    enum StreamSBResolverError: Error {
        case urlNotValid
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let videoID = url.deletingPathExtension().lastPathComponent
        let path = ("||\(videoID)||||streamsb".data(using: .utf8)!.hexEncodedString())
        let jsonLink = "https://watchsb.com/sources49/\(path)/"
        guard let sourceURL = URL(string: jsonLink) else {
            throw StreamSBResolverError.urlNotValid
        }
        let extraHeaders = [
            "Host": "watchsb.com",
            "sec-ch-ua": "\"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"108\", \"Google Chrome\";v=\"108\"",
            "accept": "application/json, text/plain, */*",
            "watchsb": "sbstream",
            "dnt": "1",
            "sec-ch-ua-mobile": "?0",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
            "sec-ch-ua-platform": "\"macOS\"",
            "sec-fetch-site": "same-origin",
            "sec-fetch-mode": "cors",
            "sec-fetch-dest": "empty",
            "referer": url.absoluteString,
            "accept-language": "en-US,en;q=0.9,ar;q=0.8"
        ]
        let data = try await Utilities.requestData(url: sourceURL, extraHeaders: extraHeaders)
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

    private let hexArray = "0123456789ABCDEF".map { String($0) }

    private func bytesToHex(_ bytes: Data) -> String {
        return bytes.map { hexArray[Int($0 / 16)] + hexArray[Int($0 % 16)] }.joined()
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02x"
        return self.map { String(format: format, $0) }.joined()
    }
}

