import Foundation

public enum SubtitlesLangauge: String, Codable, CaseIterable {
    case arabic = "Arabic"
    case bengali = "Bengali"
    case bulgarian = "Bulgarian"
    case chineseBilingual = "Chinese (Bilingual)"
    case chineseSimplified = "Chinese (Simplified)"
    case chineseTraditional = "Chinese (Traditional)"
    case croatian = "Croatian"
    case czech = "Czech"
    case danish = "Danish"
    case dutch = "Dutch"
    case english = "English"
    case estonian = "Estonian"
    case finnish = "Finnish"
    case french = "French"
    case farsi = "Farsi/Persian"
    case german = "German"
    case greek = "Greek"
    case hebrew = "Hebrew"
    case hindi = "Hindi"
    case hungarian = "Hungarian"
    case indonesian = "Indonesian"
    case italian = "Italian"
    case japanese = "Japanese"
    case korean = "Korean"
    case latvian = "Latvian"
    case lithuanian = "Lithuanian"
    case malay = "Malay"
    case norwegian = "Norwegian"
    case polish = "Polish"
    case portuguese = "Portuguese"
    case portugueseBrazilian = "Portuguese (Brazilian)"
    case russian = "Russian"
    case slovak = "Slovak"
    case slovenian = "Slovenian"
    case spanish = "Spanish"
    case spanishLatinAmerica = "Spanish (LA)"
    case swedish = "Swedish"
    case tamil = "Tamil"
    case telugu = "Telugu"
    case serbian = "Serbian"
    case thai = "Thai"
    case turkish = "Turkish"
    case ukrainian = "Ukrainian"
    case vietnamese = "Vietnamese"

    public var code: String? {
        let language = rawValue.components(separatedBy: " ").first!.components(separatedBy: "/").first!
        return NSLocale(localeIdentifier: NSLocale.canonicalLocaleIdentifier(from: language)).iso639_2LanguageCode
    }
}

public extension NSLocale {

    private static let allIso639_2LanguageIdentifiers: [String: String] = {
        guard let path = Bundle.main.path(forResource: "iso639_1_to_iso639_2", ofType: "plist") else { return [:] }
        guard let result = NSDictionary(contentsOfFile: path) as? [String: String] else { return [:] }

        return result
    }()

    var iso639_2LanguageCode: String? {
        return NSLocale.allIso639_2LanguageIdentifiers[languageCode]
    }

}
