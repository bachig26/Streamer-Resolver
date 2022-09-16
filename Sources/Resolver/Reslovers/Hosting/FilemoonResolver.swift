import Foundation

struct FilemoonResolver: Resolver {
    static let domains: [String] = ["filemoon.sx", "filemoon.to"]

    enum FilemoonResolverError: Error {
        case urlNotValid
        case codeNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let page  = try await Utilities.downloadPage(url: url)
        let decodedScript = try PackerDecoder().decode(page)
        let regx = #"file\:\"(.+?)\"\}"#
        do {
            let sourceMatchingExpr = try NSRegularExpression(
                pattern: regx ,
                options: .caseInsensitive
            )
            guard let match = sourceMatchingExpr.matches(in: decodedScript).first else {
                throw FilemoonResolverError.codeNotFound
            }

            guard let url = URL(string: decodedScript[match, at: 1]) else {
                throw FilemoonResolverError.urlNotValid
            }

            return [.init(reslover: "Filemoon", streamURL: url)]

        } catch {
            throw FilemoonResolverError.urlNotValid
        }

    }
}
