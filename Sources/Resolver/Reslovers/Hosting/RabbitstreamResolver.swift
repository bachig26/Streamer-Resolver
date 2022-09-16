import Foundation

import SwiftSoup

class RabbitstreamResolver: Resolver {
    static let domains: [String] = ["rabbitstream.net", "rapid-cloud.co"]

    enum RabbitstreamResolver: Error {
        case urlNotValid
        case codeNotFound
    }
    var websocketTask: URLSessionWebSocketTask?

    func getMediaURL(url: URL) async throws -> [Stream] {
        var parsedURL = url
        let id = parsedURL.lastPathComponent
        let page  = try await Utilities.downloadPage(url: parsedURL)
        let pageDocument = try SwiftSoup.parse(page)
        let captchaURL = try pageDocument.select("script[src*=https://www.google.com/recaptcha/api.js?render=]").attr("src")
        guard let range = captchaURL.range(of: "render=") else {
            throw RabbitstreamResolver.urlNotValid
        }
        let captchaKey = String(captchaURL[range.upperBound...])
        guard let token = try await Utilities.getCaptchaToken(url: parsedURL, key: captchaKey) else {
            throw RabbitstreamResolver.urlNotValid
        }

        let recaptchaNumberRegex = try! NSRegularExpression(
            pattern: #"recaptchaNumber\s?=\s'([^']+)"#,
            options: []
        )

        guard let number = recaptchaNumberRegex.firstMatch(in: page)?.firstMatchingGroup else {
            throw RabbitstreamResolver.codeNotFound
        }

        parsedURL.deleteLastPathComponent()

        let websocketURL: URL
        if url.host == "rapid-cloud.co" {
            websocketURL = URL(staticString: "wss://ws1.rapid-cloud.co/socket.io/?EIO=4&transport=websocket")
        } else {
            let wsServers = ["ws10", "ws11", "ws12"]
            websocketURL = URL(string: "wss://\(wsServers.randomElement() ?? "ws10").rabbitstream.net/socket.io/?EIO=4&transport=websocket")!
        }
        var wsData: Data
        let websocketTask = ResloverURLSession.shared.session.webSocketTask(with: websocketURL)
        websocketTask.resume()
        _ = try await websocketTask.receive()
        try await websocketTask.send(.string("40"))
        let message = try await websocketTask.receive()
        switch message {
        case .data(let data):
            wsData = data
        case .string(let string):
            wsData = string.dropFirst(2).data(using: .utf8) ?? Data()
        @unknown default:
            fatalError("error")
        }
        self.websocketTask = websocketTask
        receive()

        let wsResponse = try JSONCoder.decoder.decode(Message.self, from: wsData)

        guard var ajaxURL = URL(string: parsedURL.absoluteString
            .replacingOccurrences(of: "z=", with: "")
            .replacingOccurrences(of: "/embed", with: "/ajax/embed"))?
            .appendingPathComponent("getSources") else {
            throw RabbitstreamResolver.codeNotFound
        }
        ajaxURL = ajaxURL.appendingQueryItem(name: "_token", value: token)
            .appendingQueryItem(name: "_number", value: number)
            .appendingQueryItem(name: "id", value: id)
            .appendingQueryItem(name: "sId", value: wsResponse.sid)

        let data  = try await Utilities.requestData(url: ajaxURL)

        let response = try JSONCoder.decoder.decode(Response.self, from: data)
        if !response.sources.isEmpty {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onPlaybackDidEnd(_:)),
                name: .cleanup,
                object: nil
            )
        }

        return response.sources.map {
            let subtitles = response.tracks.compactMap { track -> Subtitle? in
                guard let label = track.label, let subtitle = SubtitlesLangauge(rawValue: label) else { return  nil }
                return Subtitle(url: track.file, language: subtitle)
            }

            let headers = [
                "origin": "https://rapid-cloud.co/",
                "referer": "https://rapid-cloud.co/",
                "user-agent": Constants.userAgent,
                "SID": wsResponse.sid
            ]

            return .init(reslover: "RabbitStream", streamURL: $0.file, headers: headers, subtitles: subtitles)
        }

    }

    func receive() {
        guard let websocketTask = websocketTask else {
            return
        }

        websocketTask.receive { [weak self] result in
            switch result {
            case .failure:
                break
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Websocket receive data %@", data)
                case .string(let message):
                    if message == "2" {
                        websocketTask.send(.string("3")) { _ in }
                    }
                @unknown default:
                    break
                }
            }
            self?.receive()
        }

        // todo disconnect on playback end
    }

    @objc private func onPlaybackDidEnd(_ notification: Notification) {
        if let source = notification.object as? String, source == "RabbitStream" {
            return
        }
        DispatchQueue.global().async { [weak self] in self?.disconnect() }
    }

    private func disconnect() {
        websocketTask?.cancel(with: .goingAway, reason: "Connection ended".data(using: .utf8))
        websocketTask = nil
    }

    // MARK: - Welcome
    struct Response: Codable {
        let sources: [ResponseSource]
        let tracks: [Track]
        let server: Int

        enum CodingKeys: String, CodingKey {
            case sources
            case tracks
            case server
        }
    }

    // MARK: - Source
    struct ResponseSource: Codable {
        let file: URL
        let type: String

        enum CodingKeys: String, CodingKey {
            case file
            case type
        }
    }

    struct Message: Codable {
        let sid: String
    }
    // MARK: - Track
    struct Track: Codable {
        let file: URL
        let label: String?
        let kind: String

        enum CodingKeys: String, CodingKey {
            case file
            case label
            case kind
        }
    }

}

public extension NSNotification.Name {
    static let cleanup: NSNotification.Name = .init("cleanup")
}
