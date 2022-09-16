import Foundation

public struct Stream: Codable, Hashable, Identifiable, Comparable {
    public var id: String {
        return streamURL.absoluteString
    }
    public let reslover: String
    public let streamURL: URL
    public let quality: Quality
    public var subtitles: [Subtitle]
    public let headers: [String: String]?

    internal init(reslover: String, streamURL: URL, quality: Quality? = nil, headers: [String: String]? = nil, subtitles: [Subtitle] = []) {
        self.reslover = reslover
        self.streamURL = streamURL
        self.quality = quality ?? Quality(url: streamURL)
        self.headers = headers
        self.subtitles = subtitles
    }

    public static func <(lhs: Stream, rhs: Stream) -> Bool {
        lhs.quality < rhs.quality
    }

    init(stream: Stream, subtitles: [Subtitle]) {
        self.streamURL = stream.streamURL
        self.reslover = stream.reslover
        self.quality = stream.quality
        self.headers = stream.headers
        self.subtitles = subtitles
    }
}

public enum Quality: String, CaseIterable, Comparable, Codable {
    case p360 = "360p"
    case p480 = "480p"
    case p720 = "720p"
    case p1080 = "1080p"
    case k4 = "4k"
    case auto
    case unknown
    case manual = "Manual"

    var piroirty: Int {
        switch self {
        case .p360:
            return 2
        case .p480:
            return 3
        case .p720:
            return 4
        case .p1080:
            return 5
        case .k4:
            return 6
        case .auto:
            return 1
        case .unknown:
            return 0
        case .manual:
            return 0
        }
    }

    public var localized: String {
        switch self {
        case .p360:
            return "360p"
        case .p480:
            return "480p"
        case .p720:
            return "720p"
        case .p1080:
            return "1080p"
        case .k4:
            return NSLocalizedString("Max", bundle: Bundle.main, comment: "")
        case .auto:
            return NSLocalizedString("Auto", bundle: Bundle.main, comment: "")
        case .unknown:
            return "Unknown"
        case .manual:
            return NSLocalizedString("Manual", bundle: Bundle.main, comment: "")
        }
    }

    public static var allCases: [Quality] {
        return  [.p360, .p480, .p720, .p1080, .k4, .manual]
    }

    public static func <(lhs: Quality, rhs: Quality) -> Bool {
        lhs.piroirty < rhs.piroirty
    }

    public init(url: URL) {
        switch true {
        case url.absoluteString.contains("360"):
            self = .p360
        case url.absoluteString.contains("480"):
            self = .p480
        case url.absoluteString.contains("720"):
            self = .p720
        case url.absoluteString.contains("1080"):
            self = .p1080
        case url.absoluteString.contains("4k"):
            self = .k4
        case url.absoluteString.contains("auto"):
            self = .auto
        default:
            self = .unknown
        }
    }

    public init?(quality: String?) {
        switch true {
        case quality?.contains("360"):
            self = .p360
        case quality?.contains("480"):
            self = .p480
        case quality?.contains("720"):
            self = .p720
        case quality?.contains("1080"):
            self = .p1080
        case quality?.contains("4k"):
            self = .k4
        case quality?.contains("auto"):
            self = .auto
        default:
            return nil
        }
    }
}
