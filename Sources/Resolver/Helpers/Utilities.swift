import Foundation
import SwiftSoup

public struct Utilities {

    public static func extractURLs(content: String) -> [URL] {
        let pattern = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)" +
        "(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*" +
        "\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
        return content.matches(for: pattern).compactMap {
            URL(string: $0)
        }
    }
    public static func requestData(
        url: URL,
        httpMethod: String = "GET",
        parameters: [String: String] = [:],
        data: Data? = nil,
        extraHeaders: [String: String] = [:]) async throws -> Data {
            try await Self.requestResponse(url: url, httpMethod: httpMethod, parameters: parameters, data: data, extraHeaders: extraHeaders).0
        }
    public static func requestResponse(
        url: URL,
        httpMethod: String = "GET",
        parameters: [String: String] = [:],
        data: Data? = nil,
        extraHeaders: [String: String] = [:]) async throws -> (Data, URLResponse) {
            ResloverURLSession.shared.session.configuration.httpCookieStorage = .shared
            ResloverURLSession.shared.session.configuration.httpCookieAcceptPolicy = .always
            ResloverURLSession.shared.session.configuration.httpShouldSetCookies = true

            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw ProviderError.wrongURL
            }

            if data == nil{
                var cs = CharacterSet.urlQueryAllowed
                cs.remove("+")
                cs.remove("&")
                cs.insert("µ")

                components.queryItems = components.queryItems ?? []
                parameters.forEach { key, value in
                    components.queryItems?.append(URLQueryItem(name: key, value: value))
                }

                components.percentEncodedQuery = components.queryItems?.compactMap { item -> String? in
                    guard let value = item.value else { return nil }
                    return "\(item.name)=\(value)".addingPercentEncoding(withAllowedCharacters: cs)
                }.joined(separator: "&")

            }
            guard let url = components.url else {
                throw ProviderError.wrongURL
            }

            print("[Reslover] Requesting URL: \(url.absoluteString)")
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            request.httpBody = data
            request.setValue(Constants.userAgent, forHTTPHeaderField: "user-agent")
            request.setValue("same-origin", forHTTPHeaderField: "sec-fetch-site")
            request.setValue("cors", forHTTPHeaderField: "sec-fetch-mode")
            request.setValue(url.absoluteString, forHTTPHeaderField: "referer")
            request.setValue("en-US,en;q=0.9,ar;q=0.8", forHTTPHeaderField: "accept-language")
            if data != nil {
                request.setValue("XMLHttpRequest", forHTTPHeaderField: "x-requested-with")
                request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "accept")
                request.setValue("application/json", forHTTPHeaderField: "content-type")
            } else {
                request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9", forHTTPHeaderField: "accept")

            }
            request.setValue(url.absoluteString, forHTTPHeaderField: "authority")
            extraHeaders.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)

            }
            let (data, response)  = try await ResloverURLSession.shared.session.asyncData(for: request)

            if let url = response.url,
               let httpResponse = response as? HTTPURLResponse,
               let fields = httpResponse.allHeaderFields as? [String: String] {

                let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
                for cookie in cookies {
                    var cookieProperties = [HTTPCookiePropertyKey: Any]()
                    cookieProperties[.name] = cookie.name
                    cookieProperties[.value] = cookie.value
                    cookieProperties[.domain] = cookie.domain
                    cookieProperties[.path] = cookie.path
                    cookieProperties[.version] = cookie.version
                    cookieProperties[.expires] = Date().addingTimeInterval(31536000)

                    let newCookie = HTTPCookie(properties: cookieProperties)
                    HTTPCookieStorage.shared.setCookie(newCookie!)
                }
            }

            print("[Reslover] Finished requesting: \(url.absoluteString) successfully ")
            return (data, response)
        }

    public static func downloadPage(url: URL,
                                    httpMethod: String = "GET",
                                    parameters: [String: String] = [:],
                                    data: Data? = nil,
                                    encoding: String.Encoding = .utf8,
                                    extraHeaders: [String: String] = [:]) async throws -> String {
        let data = try await requestData(url: url, httpMethod: httpMethod, parameters: parameters, data: data, extraHeaders: extraHeaders)
        guard let content = String(data: data, encoding: encoding) else {
            throw ProviderError.noContent
        }
        return content
    }

    public static func getCaptchaToken(url: URL, key: String, referer: String = "") async throws ->  String? {
        let vTokenRegex = try! NSRegularExpression(
            pattern: #"releases/([^/&?#]+)"#,
            options: .caseInsensitive
        )
         let tokenRegex =  try! NSRegularExpression(
            pattern: #"rresp\",\"(.+?)\""#,
            options: .caseInsensitive
        )

        let domain = "https://\(url.host!):443".data(using: .utf8)?.base64EncodedString().replacingOccurrences(of: "=", with: "") ?? ""
        let vTokenPage = try await Utilities.downloadPage(url: URL(string: "https://www.google.com/recaptcha/api.js?render=\(key)")!,
                                                          extraHeaders: ["referrer": referer])

        guard let vToken = vTokenRegex.firstMatch(in: vTokenPage)?.firstMatchingGroup else {
            return nil
        }
        let recapTokenPageContent = try await Utilities.downloadPage(url: URL(string: "https://www.google.com/recaptcha/api2/anchor?ar=1&hi=en&size=invisible&cb=123456789&k=\(key)&co=\(domain)&v=\(vToken)")!)
        let pageDocument = try SwiftSoup.parse(recapTokenPageContent)
        guard let recapToken = try pageDocument.select("#recaptcha-token").array().first?.attr("value") else {
            return nil
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        let extraHeaders = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        let postData = [
            "v": vToken,
            "k": key,
            "c": recapToken,
            "co": domain,
            "sa": "",
            "reason": "q"
        ]
        let httpBody = NSMutableData()

        for (key, value) in postData {
            httpBody.appendString(convertFormField(named: key, value: value, using: boundary))
        }
        httpBody.appendString("--\(boundary)--")

        let reloadPageContent = try await Utilities.downloadPage(url: URL(string: "https://www.google.com/recaptcha/api2/reload?k=\(key)")!,
                                         httpMethod: "POST",
                                         data: httpBody as Data,
                                         extraHeaders: extraHeaders)
        return tokenRegex.firstMatch(in: reloadPageContent)?.firstMatchingGroup
    }

    static func convertFormField(named name: String, value: String, using boundary: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }
}
