@testable import Resolver

import XCTest

class ResolverTests: XCTestCase {

    func testStreamtape() async throws {
        let url = URL(staticString: "https://streamtape.com/e/lxp6g9QJGwi7XJK")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testVidCloud9() async throws {
        let timeInterval = NSDate().addingTimeInterval(30*60).timeIntervalSince1970
        let url = URL(string: "https://vidembed.io/embedplus?id=MzU1OTMw&token=zh8KBy7tDW5WSx0wAIJI1g&expires=\(timeInterval)")!
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testVizCloud() async throws {
        let url = URL(staticString: "https://vidstream.pro/e/0RYXXW94RYNV")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testAkwam() async throws {
        let url = URL(staticString: "https://akwam.to/episode/59599/%D8%A7%D9%84%D8%A2%D9%86%D8%B3%D8%A9-%D9%81%D8%B1%D8%AD-%D8%A7%D9%84%D9%85%D9%88%D8%B3%D9%85-%D8%A7%D9%84%D8%AE%D8%A7%D9%85%D8%B3/%D8%A7%D9%84%D8%AD%D9%84%D9%82%D8%A9-1")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testCimanow() async throws {
        let url = URL(staticString: "https://cimanow.cc/%d9%81%d9%8a%d9%84%d9%85-%d8%b9%d9%86%d8%aa%d8%b1-%d8%a7%d8%a8%d9%86-%d8%a7%d8%a8%d9%86-%d8%a7%d8%a8%d9%86-%d8%a7%d8%a8%d9%86-%d8%b4%d8%af%d8%a7%d8%af-2017/watching")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testEmbedsito() async throws {
        let url = URL(staticString: "https://embedsito.com/v/x4kj7h5ljjl358d")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)

    }

    func testSeriesYonkisTrembed() async throws {
        let url2 = URL(staticString: "https://seriesyonkis.io/?trembed=0&trid=7537&trtype=1")
        let streams2 = try await HostsResolver.resloveURL(url: url2)
        XCTAssertNotNil(streams2)
        XCTAssertFalse(streams2.isEmpty)
    }

    func testSeriesYonkis() async throws {
        let url = URL(staticString: "https://seriesyonkis.io/episode/obi-wan-kenobi-1x1/")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)

    }

    func testUqload() async throws {
        let url = URL(staticString: "https://uqload.com/embed-t507fza3eblw.html")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testPelisflix() async throws {
        let url = URL(staticString: "https://pelisflix.uno/episodio/star-wars-obi-wan-kenobi-1x1/")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testNupload() async throws {
        let url = URL(staticString: "https://nupload.xyz/watch/QfVXIzBw9ficuFOZVhhLBvUPntFtQ9ulFPnsMcW1wTc")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func testFilemoon() async throws {
        let url = URL(staticString: "https://filemoon.sx/e/j3r9glwhmofw")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)
    }

    func teststreamingcommunity() async throws {
        let url = URL(staticString: "https://streamingcommunity.agency/watch/1867")
        let streams = try await HostsResolver.resloveURL(url: url)
        XCTAssertNotNil(streams)
        XCTAssertFalse(streams.isEmpty)

    }
}
