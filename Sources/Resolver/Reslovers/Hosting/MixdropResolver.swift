import Foundation

struct MixdropResolver: Resolver {
    static let domains: [String] = ["mixdrop.co", "mixdrop.ch"]

    enum MixdropResolverError: Error {
        case urlNotValid
        case codeNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        guard let embedUrl = URL(string: url.absoluteString.replacingOccurrences(of: "/f/", with: "/e/")) else {
            throw MixdropResolverError.urlNotValid
        }

        let page  = try await Utilities.downloadPage(url: embedUrl)
        let decodedScript = try PackerDecoder().decode(page)
        let sourceMatchingExpr = try NSRegularExpression(
            pattern: "MDCore\\.wurl=\"([^\"]+)",
            options: []
        )

        guard let videoAssetUrlString = sourceMatchingExpr.firstMatch(in: decodedScript)?.firstMatchingGroup else {
            throw MixdropResolverError.codeNotFound
        }

        guard let resourceUrl = URL(string: videoAssetUrlString.hasPrefix("//") ?  "https:\(videoAssetUrlString)" : videoAssetUrlString) else {
            throw MixdropResolverError.urlNotValid
        }

        let headers: [String: String] = [
            "Host": resourceUrl.host ?? "",
            "sec-ch-ua": "\".Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"103\", \"Chromium\";v=\"103\"",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "User-Agent": Constants.userAgent,
            "sec-ch-ua-platform": "\"macOS\"",
            "Accept": "*/*",
            "Origin": embedUrl.host ?? "https://mixdrop.co/",
            "Sec-Fetch-Site": "cross-site",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "video",
            "Referer": embedUrl.host ?? "https://mixdrop.co/",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8"
        ]

        return [.init(reslover: "MixDrop", streamURL: resourceUrl, headers: headers)]

    }

}
