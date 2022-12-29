import Foundation
import CryptoKit
import SwiftSoup
import CommonCrypto

class RabbitstreamResolver: Resolver {
    static let domains: [String] = ["rabbitstream.net", "rapid-cloud.co"]

    enum RabbitstreamResolverError: Error {
        case urlNotValid
        case codeNotFound
        case encryptionKeyNotDownloaded
    }
    var websocketTask: URLSessionWebSocketTask?
    static var encryptionKey: Data?

    func getMediaURL(url: URL) async throws -> [Stream] {
        //https://rapid-cloud.co/embed-6/XCk0Kd6dyHWj?vast=1&autoPlay=1&oa=0&asi=1
        var parsedURL = url.appendingQueryItem(name: "autoPlay", value: "1")
            .appendingQueryItem(name: "oa", value: "1")
            .appendingQueryItem(name: "asi", value: "1")

        let id = parsedURL.lastPathComponent

        guard var ajaxURL = URL(string: "https://rapid-cloud.co/ajax/embed-6/getSources") else {
            throw RabbitstreamResolverError.codeNotFound
        }
        ajaxURL = ajaxURL
            .appendingQueryItem(name: "id", value: id)
        print(ajaxURL)
        let data  = try await Utilities.requestData(url: ajaxURL)


        Self.encryptionKey = try await Utilities.downloadPage(url: try URL("https://raw.githubusercontent.com/consumet/rapidclown/main/key.txt?ts=\(Date().timeIntervalSince1970)")).data(using: .utf8)

        let response = try JSONCoder.decoder.decode(Response.self, from: data)
        return response.sources.map {
            let subtitles = response.tracks.compactMap { track -> Subtitle? in
                guard let label = track.label, let subtitle = SubtitlesLangauge(rawValue: label) else { return  nil }
                return Subtitle(url: track.file, language: subtitle)
            }

            let headers = [
                "origin": "https://rapid-cloud.co/",
                "referer": "https://rapid-cloud.co/",
                "user-agent": Constants.userAgent,
            ]

            return .init(reslover: "RapidCloud", streamURL: $0.file, headers: headers, subtitles: subtitles)
        }

    }


    // MARK: - Welcome
    struct Response: Codable {
        let sources: [ResponseSource]
        let tracks: [Track]
        let encrypted: Bool

        enum CodingKeys: String, CodingKey {
            case sources
            case tracks
            case encrypted
        }


        init(from decoder: Decoder) throws {
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            let sourcesEncrypted = try keyedContainer.decode(Bool.self, forKey: .encrypted)

            self.encrypted = sourcesEncrypted
            self.tracks = try keyedContainer.decode([Track].self, forKey: .tracks)

            if sourcesEncrypted {
                guard let encryptionKey = RabbitstreamResolver.encryptionKey else {
                    throw RabbitstreamResolverError.encryptionKeyNotDownloaded
                }

                let encryptedSourcesString = try keyedContainer.decode(String.self, forKey: .sources)
                let encryptedSourcesData = Data(base64Encoded: encryptedSourcesString)!
                let decryptedSourcesData = try RabbitstreamResolver.decrypt(
                    encryptedSourcesData,
                    withKey: encryptionKey
                )
                let internalDecoder = JSONDecoder()

                self.sources = try internalDecoder.decode(
                    [ResponseSource].self,
                    from: decryptedSourcesData
                )
            } else {
                self.sources = try keyedContainer.decode(
                    [ResponseSource].self,
                    forKey: .sources
                )
            }
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

// Standard CryptoJS.AES functions
private extension RabbitstreamResolver {
    /// Derives the 32-byte AES key and the 16-byte IV from data and salt
    ///
    /// See OpenSSL's implementation of EVP_BytesToKey
    private static func generateKeyAndIV(_ data: Data, salt: Data) -> (key: Data, iv: Data) {
        let totalLength = 48
        var destinationBuffer = Data(capacity: totalLength)
        let dataAndSalt = data + salt

        // Calculate the key and value with data and salt
        var digestBuffer = insecureHash(input: dataAndSalt)
        destinationBuffer.append(digestBuffer)

        // Keep digesting until the buffer is filled
        while destinationBuffer.count < totalLength {
            let combined = digestBuffer + dataAndSalt
            digestBuffer = insecureHash(input: combined)
            destinationBuffer.append(digestBuffer)
        }

        // Generate key and iv
        return (destinationBuffer[0..<32], destinationBuffer[32..<48])
    }

    private static func insecureHash(input: Data) -> Data {
        if #available(iOS 13.0, *) {
            // Use CryptoKit.Insecure.MD5 for hashing
            var insecureHasher = Insecure.MD5()
            insecureHasher.update(data: input)
            return Data(insecureHasher.finalize())
        } else {
            var digestBuffer = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            _ = digestBuffer.withUnsafeMutableBytes {
                destinationPointer in input.withUnsafeBytes {
                    (pointer: UnsafeRawBufferPointer) in CC_MD5(
                        pointer.baseAddress!,
                        CC_LONG(input.count),
                        destinationPointer.bindMemory(to: UInt8.self).baseAddress!
                    )
                }
            }
            return digestBuffer
        }
    }

    private static func decrypt(_ saultedData: Data, withKey encryptionKey: Data) throws -> Data {
        // Check if the data has the prefix
        let saltIdentifier = "Salted__"
        guard String(data: saultedData[0..<8], encoding: .utf8) == saltIdentifier else {
            throw RabbitstreamResolverError.codeNotFound
        }

        // 8 bytes of salt
        let salt = saultedData[8..<16]
        let data = saultedData[16...]

        // Calculate the key and iv
        let (key, iv) = self.generateKeyAndIV(encryptionKey, salt: salt)

        let destinationBufferLength = data.count + kCCBlockSizeAES128
        var destinationBuffer = Data(count: destinationBufferLength)
        var decryptedBytes = 0

        // AES256-CBC decrypt with the derived key and iv
        let decryptionStatus = destinationBuffer.withUnsafeMutableBytes {
            destinationPointer in
            data.withUnsafeBytes {
                dataPointer in
                key.withUnsafeBytes {
                    keyPointer in
                    iv.withUnsafeBytes {
                        ivPointer in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyPointer.baseAddress!,
                            kCCKeySizeAES256,
                            ivPointer.baseAddress!,
                            dataPointer.baseAddress!,
                            data.count,
                            destinationPointer.baseAddress!,
                            destinationBufferLength,
                            &decryptedBytes
                        )
                    }
                }
            }
        }

        // Check result status
        guard decryptionStatus == CCCryptorStatus(kCCSuccess) else {
            throw RabbitstreamResolverError.codeNotFound
        }

        return destinationBuffer[0..<decryptedBytes]
    }
}
