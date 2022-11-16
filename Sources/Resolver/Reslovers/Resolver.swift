import Foundation

protocol Resolver {
    static var domains: [String] { get }
    func getMediaURL(url: URL) async throws -> [Stream]
    func canHandle(url: URL) -> Bool
}
extension Resolver {
    func canHandle(url: URL) -> Bool {
        Self.domains.firstIndex(of: url.host!) != nil
    }
}

public struct HostsResolver {
    static let reslovers : [ Resolver ] = [
        AkwamReslover(),
        CimaNowReslover(),
        DoodstreamReslover(),
        EmbedsitoResolver(),
        FlixtorReslover(),
        MixdropResolver(),
        MoplayResolver(),
        MyCloudResolver(),
        ZoroReslover(),
        NuploadResolver(),
        PelisflixResolver(),
        PelisplusReslover(),
        PelisplussResolver(),
        RabbitstreamResolver(),
        SeriesYonkisReslover(),
        StreamlareResolver(),
        StreamSBResolver(),
        StreamtapeReslover(),
        TwoEmbedReslover(),
        UqloadResolver(),
        VidCloud9Resolver(),
        VideovardReslover(),
        VidsrcResolver(),
        FilemoonResolver(),
        StreamingCommunityReslover(),
        OlgPlayResolver(),
        DatabasegdriveplayerReslover()
    ]
    static public func resloveURL(url: URL) async throws -> [Stream] {
        print("🕸", url)
        guard let reslover = Self.reslovers.filter({ $0.canHandle(url: url)}).first else {
            throw ResolverError.hostNotSupported
        }
        return try await reslover.getMediaURL(url: url)
    }
}

public enum ResolverError: Error {
    case hostError
    case hostNotSupported
    case URLNotFound
    case NoStreamsFound
}
