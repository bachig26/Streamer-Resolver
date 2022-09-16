import XCTest
import Resolver

class MediaBoxProviderTests: XCTestCase {
    let provider = ProviderType.mediabox.provider

    func testMovies() async throws {
        print("✅ 🖥 Provider ", provider.title)
        let movies = try await provider.latestMovies(page: 1)
        XCTAssertNotNil(movies)
        if let tempMovie = movies.last {
            let movie = try await provider.fetchMovieDetails(for: tempMovie.webURL)
            print("✅ 🍿 Movie ", movie.title)

            XCTAssertFalse(movie.title.isEmpty)
            XCTAssertFalse(movie.sources!.isEmpty)
            print("✅ 🕸 Sources count", movie.sources?.count ?? 0)
            print("✅ 🕸 Sources", movie.sources?.compactMap { $0.hostURL.host } ?? "" )
            XCTAssertFalse(movie.posterURL.absoluteString.isEmpty)
            XCTAssertFalse(movie.webURL.absoluteString.isEmpty)
        } else {
            print("❌ 🖥 Provider ", provider.title)

            XCTFail("\(provider.title) movie parsing failed")
        }
    }

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
