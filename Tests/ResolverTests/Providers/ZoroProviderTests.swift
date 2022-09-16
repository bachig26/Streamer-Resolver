import XCTest
import Resolver

class ZoroProviderTests: XCTestCase {
    let provider = ProviderType.zoro.provider

    func testTVShows() async throws {
        let tvShows = try await provider.latestTVShows(page: 1)
        XCTAssertNotNil(tvShows)
        if let tempTVShow = tvShows.last {
            let tvShow = try await provider.fetchTVShowDetails(for: tempTVShow.webURL)
            print("✅ 📺 TVShow ", tvShow.title)
            print("✅ 🧂 Seasons", tvShow.seasons?.count ?? 0)
            XCTAssertFalse(tvShow.title.isEmpty)
            XCTAssertFalse(tvShow.seasons!.isEmpty)
            XCTAssertFalse(tvShow.seasons!.first!.episodes!.isEmpty)
            print("✅ 🕸 Sources count", tvShow.seasons!.first?.episodes?.first?.sources?.count ?? 0 )
            print("✅ 🕸 Sources ", tvShow.seasons!.first?.episodes?.first?.sources?.compactMap { $0.hostURL.host } ?? "" )
            XCTAssertFalse(tvShow.posterURL.absoluteString.isEmpty)
            XCTAssertFalse(tvShow.webURL.absoluteString.isEmpty)
        } else {
            print("❌ 📺 Provider ", provider.title)
            XCTFail("\(provider.title) tv shows parsing failed")
        }
    }

    func testSearch() async throws {
        let searchResults = try await provider.search(keyword: "spider", page: 1)
        if let result = searchResults.first {
            XCTAssertFalse(result.title.isEmpty)
            XCTAssertFalse(result.posterURL.absoluteString.isEmpty)
            XCTAssertFalse(result.webURL.absoluteString.isEmpty)
        } else {
            print("❌ 🔎 Provider ", provider.title)
        }
    }

}
