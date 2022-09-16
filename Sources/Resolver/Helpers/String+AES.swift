import Foundation
import CryptoSwift

public extension String {
    var MD5: String {
        self.md5()
    }

    func encodeURIComponent() -> String {
        let characterSet = NSMutableCharacterSet.urlQueryAllowed

        return self.addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
    }

    func removingRegexMatches(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch { return  self }
    }

    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range(at: 1), in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    func aesEncrypt(key: String, iv: String) -> String? {
        guard let data = self.data(using: .utf8),
              let key = key.data(using: .utf8),
              let iv = iv.data(using: .utf8)
        else { return nil }

        let aes = try? AES(key: key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)

        let base64Data = try? aes?.encrypt(data.bytes)
        return Data(base64Data ?? []).base64EncodedString()
    }

    func aesDecrypt(key: String, iv: String) -> String? {
        guard
            let data = Data(base64Encoded: self),
            let key = key.data(using: .utf8),
            let iv = iv.data(using: .utf8)
        else { return nil }
        let aes = try? AES(key: key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)
        let decrypt = try? aes?.decrypt(data.bytes)
        return String(data: Data(decrypt ?? [] ), encoding: .utf8)
    }

    func fromBase64URL() -> String? {
        var base64 = self
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func toBase64URL() -> String {
        var result = Data(self.utf8).base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }

    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    subscript (bounds: NSRange) -> String {
        let range = Range(bounds, in: self)!
        return String(self[range])
    }

    subscript (_ matchResult: NSTextCheckingResult, at group: Int) -> String {
        let range = matchResult.range(at: group)
        if range.lowerBound == NSNotFound && range.length == 0 {
            return ""
        }
        return self[range]
    }

    subscript (range: PartialRangeFrom<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        return String(self[startIndex..<endIndex])
    }

    var matchingRange: NSRange {
        NSRange(location: 0, length: utf16.count)
    }
}

extension Character {
    func unicodeScalarCodePoint() -> UInt32 {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars

        return scalars[scalars.startIndex].value
    }
}

func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map { _ in letters.randomElement()! })
}

public extension NSRegularExpression {
    func matches(in content: String, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        matches(in: content, options: options, range: content.matchingRange)
    }

    // Return the groups of the first match
    func firstMatch(in content: String, options: NSRegularExpression.MatchingOptions = []) -> [String]? {
        guard let match = matches(in: content, options: options).first else { return nil }
        return (0..<match.numberOfRanges).map { content[match, at: $0] }
    }

    // Return the groups of the last match
    func lastMatch(in content: String, options: NSRegularExpression.MatchingOptions = []) -> [String]? {
        guard let match = matches(in: content, options: options).last else { return nil }
        return (0..<match.numberOfRanges).map { content[match, at: $0] }
    }
}

extension Data {
    func toBase64URL() -> String {
        var result = self.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }

}
public extension Array where Element == String {
    // Return the first matching group (second array item)
    var firstMatchingGroup: String? {
        if count > 1 {
            return self[1]
        } else { return nil }
    }
}

func encryptss(input: String, key: String) -> String {
    var output = ""
    let lengInput = input.count
    for i in stride(from: 0, to: lengInput, by: 3) {
        var a: [Int] = [-1, -1, -1, -1]
        a[0] = Int(input[i].unicodeScalarCodePoint() >> 2)
        a[1] = Int((3 & input[i].unicodeScalarCodePoint()) << 4)
        if lengInput > i + 1 {
            a[1] = a[1] | Int((input[i + 1].unicodeScalarCodePoint() >> 4))
            a[2] = Int((15 & input[i + 1].unicodeScalarCodePoint()) << 2)
        }
        if lengInput > i + 2 {
            a[2] = a[2] | Int((input[i + 2].unicodeScalarCodePoint() >> 6))
            a[3] = Int(63 & input[i + 2].unicodeScalarCodePoint())
        }
        a.forEach { n in
            if n == -1 {
                output.append("=")
            } else if n >= 0 && n <= 63 {
                output.append(key[n])
            }
        }
    }
    return output
}
func cipher(key: String, text: String) -> String {
    var arr = Array(0...255)
    var output = ""
    var u = 0
    var r = 0
    let arr2 = Array(0...arr.count-1)
    arr2.forEach { a in
        u = (u + arr[a] + Int(key[a % key.count].unicodeScalarCodePoint())) % 256
        r = arr[a]
        arr[a] = arr[u]
        arr[u] = r
    }
    u = 0
    var c = 0
    let arr3 = Array(0...text.count-1)
    arr3.forEach { f in
        c = (c + 1) % 256
        u = (u + arr[c]) % 256
        r = arr[c]
        arr[c] = arr[u]
        arr[u] = r
        output += String(UnicodeScalar(Int(text[f].unicodeScalarCodePoint()) ^ arr[(arr[c] + arr[u]) % 256]) ?? "0")
    }

    return output
}

func decryptss(input: String, key: String) -> String? {
    var t = input
    let regx =
"""
    [\t\n\\f\r]
"""
    let a = input.removingRegexMatches(pattern: regx, replaceWith: "")
    if a.count % 4 == 0 {
        t = a.removingRegexMatches(pattern: "==?$", replaceWith: "")
        if t.count % 4 == 1 {
            return nil
        }
    }

    var i = 0
    var r = ""
    var e = 0
    var u = 0
    t.enumerated().forEach { _, o in
        e = e << 6
        if let charIndex = key.firstIndex(of: o) {
            i = key.distance(from: key.startIndex, to: charIndex)
        } else {
            i = -1
        }
        e |= i < 0 ? e : i
        u += 6
        if 24 == u {
            r +=  String(UnicodeScalar(((16711680 & e) >> 16))!)
            r +=  String(UnicodeScalar(((65280 & e) >> 8))!)
            r +=  String(UnicodeScalar(((255 & e)))!)
            e = 0
            u = 0
        }
    }
    if 12 == u {
        e = e >> 4
        return r + String(UnicodeScalar((e))!)
    } else {
        if 18 == u {
            e = e >> 2
            r += String(UnicodeScalar((65280 & e) >> 8)!)
            r += String(UnicodeScalar(((255) & e))!)
        }
        return r
    }
}
