import Foundation
import SwiftSoup

struct  SeriesYonkisReslover: Resolver {
    static let domains: [String] = ["seriesyonkis.io"]

    enum SeriesYonkisResloverError: Error {
        case episodeNotAvailable
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        if url.absoluteString.contains("trembed") {
            let path = try pageDocument.select("iframe").attr("src")
            guard let seriesURL = URL(string: path) else {
                throw SeriesYonkisResloverError.episodeNotAvailable
            }
            return try await HostsResolver.resloveURL(url: seriesURL)
        } else {
            let path = try pageDocument.select(".TPlayer iframe").attr("src")
            guard let embedURL = URL(string: path) else {
                throw SeriesYonkisResloverError.episodeNotAvailable
            }
            return try await HostsResolver.resloveURL(url: embedURL)
        }
    }
}
