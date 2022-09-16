import Foundation

extension URL {

    func appendingPathComponent(_ value: Int) -> Self {
        appendingPathComponent(String(value))
    }

    func appendingQueryItem(name: String, value: CustomStringConvertible) -> Self {
        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value.description))
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }

}

extension URL {

    enum URLError: Error {
        case badURL
    }
    public init(_ string: String) throws {
        guard let url = URL(string: string) else {
            throw URLError.badURL
        }
        self = url
    }

    func appendingAPIKey(_ apiKey: String) -> Self {
        appendingQueryItem(name: "api_key", value: apiKey)
    }

    func appendingLanguage(locale: Locale = .current) -> Self {
        var parts = [String]()
        if let languageCode = locale.languageCode {
            parts.append(languageCode)
        }

        guard !parts.isEmpty else {
            return self
        }

        return appendingLanguage(parts.joined(separator: "-"))
    }

    func appendingLanguage(_ language: String) -> Self {
        return appendingQueryItem(name: "language", value: language)
    }

    func appendingPage(_ page: Int?) -> Self {
        guard var page = page else {
            return self
        }

        page = max(page, 1)
        page = min(page, 1000)

        return appendingQueryItem(name: "page", value: page)
    }

    func appendingYear(_ year: Int?) -> Self {
        guard let year = year else {
            return self
        }

        return appendingQueryItem(name: "year", value: year)
    }

    func appendingFirstAirDateYear(_ year: Int?) -> Self {
        guard let year = year else {
            return self
        }

        return appendingQueryItem(name: "first_air_date_year", value: year)
    }

}
