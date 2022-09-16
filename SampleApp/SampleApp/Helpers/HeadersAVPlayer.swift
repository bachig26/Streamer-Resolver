import Foundation
import AVKit
import Resolver

public class HeadersAVPlayer: AVPlayer {
    public override init() {
        super.init()
    }
    public init(stream: Resolver.Stream) {
        super.init()
        let videoURL = stream.streamURL
        let referer = "https://\(videoURL.host ?? "")/"
        let headers: [String: String] = stream.headers ?? [
            "Host": videoURL.host ?? "",
            "sec-ch-ua": "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"98\", \"Google Chrome\";v=\"99\"",
            "dnt": "1",
            "sec-ch-ua-mobile": "?0",
            "user-agent": Constants.userAgent,
            "sec-ch-ua-platform": "\"macOS\"",
            "accept": "*/*",
            "sec-fetch-site": "cross-site",
            "sec-fetch-mode": "no-cors",
            "sec-fetch-dest": "video",
            "referer": referer,
            "accept-language": "en-GB,en-US;q=0.9,en;q=0.8"
        ]
        let asset = AVURLAsset(url: videoURL, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        replaceCurrentItem(with: playerItem)
    }
}
