import Foundation
import SwiftSoup

class VidsrcResolver: Resolver {
    static let domains: [String] = ["v2.vidsrc.me"]
    let baseURL: URL = URL(staticString: "https://v2.vidsrc.me/src/")

    var timer: Timer?
    var setPassURL: URL?

    enum VidsrcResolverrError: Error {
        case videoNotFound

    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        // load other sources
        let sources =  try? await pageDocument.select(".source").array().asyncMap { source -> [Stream] in
            let hash = try source.attr("data-hash")
            let hashURL = self.baseURL.appendingPathComponent(hash)
            let (data, response) = try await Utilities.requestResponse(url: hashURL)
            if let redirectURL = response.url, !redirectURL.absoluteString.contains("vidsrc.stream") {
                return (try? await HostsResolver.resloveURL(url: redirectURL)) ?? []
            } else {
                let pageContent = String(data: data, encoding: .utf8) ?? ""
                let pageDocument = try SwiftSoup.parse(pageContent)
                let script = try pageDocument.select("script").array().filter {
                    try $0.html().contains("hls.loadSource")
                }.first?.html() ?? ""

                let allURLs = Utilities.extractURLs(content: script.replacingOccurrences(of: "\"//", with: "\"https://").replacingOccurrences(of: "'", with: " '"))
                guard let path = allURLs.filter({ $0.pathExtension == "m3u8"}).first else {
                    throw VidsrcResolverrError.videoNotFound
                }
                guard let setPathURL = allURLs.filter({ $0.absoluteString.contains("set_pass.php")}).first else {
                    throw VidsrcResolverrError.videoNotFound
                }
                self.setPassURL = setPathURL

                self.startTimer()

                return [.init(reslover: "Vidsrc", streamURL: path)]
            }
        }
        .flatMap { $0 }

        return sources ?? []

    }

    func startTimer() {
        timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(requestSetPass), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPlaybackDidEnd(_:)),
            name: .cleanup,
            object: nil
        )
        Task {
            await requestSetPass()
        }
    }

    @objc private func onPlaybackDidEnd(_ notification: Notification) {
        if let source = notification.object as? String, source == "Vidsrc" {
            return
        }
        timer?.invalidate()
        timer = nil
    }

    @objc func requestSetPass() async {
        guard let url = self.setPassURL else { return }
        let headers = [
            "Host": url.host ?? "",
            "Connection": "keep-alive",
            "sec-ch-ua": "\"Google Chrome\";v=\"105\", \"Not)A;Brand\";v=\"8\", \"Chromium\";v=\"105\"",
            "Accept": "*/*",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36",
            "sec-ch-ua-platform": "\"macOS\"",
            "Origin": "https://vidsrc.stream",
            "Sec-Fetch-Site": "same-site",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Referer": "https://vidsrc.stream/",
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8"
        ]
        _ = try? await Utilities.requestData(url: url, extraHeaders: headers)
    }
}
