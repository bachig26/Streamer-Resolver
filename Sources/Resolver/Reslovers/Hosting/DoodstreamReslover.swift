import Foundation
import SwiftSoup

struct DoodstreamReslover: Resolver {
    static let domains: [String] = ["doodstream.com", "dood.ws", "dood.cx", "dood.sh", "dood.watch", "dood.pm", "dood.to", "dood.so", "dood.la", "dood.wf"]

    enum DoodstreamResloverrError: Error {
        case regxValueNotFound
        case urlNotValid

    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let document = try SwiftSoup.parse(content)
        let script = try document.select("script").array().filter {
            try $0.html().contains("pass_md5")
        }.first?.html() ?? ""
        guard let md5UrlString = script.matches(for: #"\$\.get\('(\/pass_md5[^']+)"#).first  else {
            throw DoodstreamResloverrError.regxValueNotFound
        }

        guard let md5URL = URL(string: "https://dood.pm" + md5UrlString) else {
            throw DoodstreamResloverrError.urlNotValid
        }
        let md5Token = md5URL.lastPathComponent
        let responseContent = try await Utilities.downloadPage(url: md5URL)
        let randomLetters = randomString(length: 10)
        let dateString = String(Date().timeIntervalSince1970)
        let directVideoURLString = "\(responseContent + randomLetters)?token=\(md5Token)&expiry=\(dateString)"
        guard let directVideoURL = URL(string: directVideoURLString) else {
            throw DoodstreamResloverrError.urlNotValid
        }
        return [.init(reslover: "DoodStream", streamURL: directVideoURL)]
    }

}
