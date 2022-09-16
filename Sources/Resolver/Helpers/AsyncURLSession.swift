import Foundation
import Network

/// We need this protoocol to tell our async/await runtime about URLSession.
public protocol AsyncURLSession {

    /// Our async/await enabled URL fetcher,
    /// returns an async error or a [ data, response ] tuple.
    func asyncData(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Here we implement our async aware function.
extension URLSession: AsyncURLSession {

    public func asyncData(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
            ResloverURLSession.shared.session.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    if let error = error {
                        continuation.resume(throwing: error )
                    }
                    return
                }
                continuation.resume(returning: (data, response))
            }.resume()
        })
    }
}

public class ResloverURLSession: NSObject, URLSessionDelegate {
    public static let shared = ResloverURLSession()
    let session: URLSession = URLSession(configuration: .default)

    override init() {
        super.init()
        let secureDNS = DoHConfigurarion.google
        NWParameters.PrivacyContext.default.requireEncryptedNameResolution(
            true,
            fallbackResolver: .https(secureDNS.httpsURL, serverAddresses: secureDNS.serverAddresses)
        )
    }
}
