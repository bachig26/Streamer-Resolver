import Foundation

struct VidCloud9Resolver: Resolver {
    static let domains: [String] = [
        "membed.net",
        "vidembed.me",
        "vidcloud9.com",
        "vidnode.net",
        "vidnext.net",
        "vidembed.net",
        "vidembed.cc",
        "vidembed.io"
    ]
    static let headers = [
        "sec-ch-ua": "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"98\", \"Google Chrome\";v=\"99\"",
        "dnt": "1",
        "sec-ch-ua-mobile": "?0",
        "user-agent": Constants.userAgent,
        "sec-ch-ua-platform": "\"macOS\"",
        "accept": "*/*",
        "sec-fetch-site": "cross-site",
        "sec-fetch-mode": "no-cors",
        "sec-fetch-dest": "video",
        "referer": "https://vidembed.me",
        "accept-language": "en-GB,en-US;q=0.9,en;q=0.8"
    ]

    enum VidCloud9ResolverError: Error {
        case idParamterNotFound
        case urlNotValid
        case encryptionFaild
        case decryptionFaild
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        guard let url = URLComponents(string: url.absoluteString),
              let mediaID = url.queryItems?.first(where: { $0.name == "id" })?.value else {
                  throw VidCloud9ResolverError.idParamterNotFound
              }
        let headers = [
            "User-Agent": Constants.userAgent,
            "Referer": url.host ?? "",
            "x-requested-with": "XMLHttpRequest",
            "same-origin": "sec-fetch-site",
            "cors": "sec-fetch-mode"
        ]
        let key = "25742532592138496744665879883281"
        let iv =  "9225679083961858"
        guard let eid = mediaID.aesEncrypt(key: key, iv: iv) else {
            throw VidCloud9ResolverError.encryptionFaild
        }

        guard let host = url.host,
            var embedUrl = URL(string: "https://\(host)/encrypt-ajax.php") else {
            throw VidCloud9ResolverError.urlNotValid
        }

        embedUrl = embedUrl.appending([
            "c": "aaaaaaaa",
            "id": eid,
            "refer": "https://123moviesfree.so",
            "alias": mediaID
        ])
        var request = URLRequest(url: embedUrl)
        request.allHTTPHeaderFields = headers
        let (data, _)  = try await ResloverURLSession.shared.session.asyncData(for: request)
        let encryptedContent = try JSONCoder.decoder.decode(EncryptedResponse.self, from: data)

        guard let data = encryptedContent.data.aesDecrypt(key: key, iv: iv)?.data(using: .utf8) else {
            throw VidCloud9ResolverError.decryptionFaild
        }
        let content = try JSONCoder.decoder.decode(Response.self, from: data)
        return content.source.reversed().compactMap {
            return .init(reslover: "Vidcloud", streamURL: $0.file, quality: Quality(quality: $0.label), headers: Self.headers)
        }
    }

    struct EncryptedResponse: Equatable, Codable {
        let data: String
    }

    // MARK: - Welcome
    struct Response: Equatable, Codable {
        let source: [Source]
    }

    // MARK: - Source
    struct Source: Equatable, Codable {
        let file: URL
        let label: String
        let type: String?
    }

}
