import Foundation

public final class DateCoder {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    public static func decode(string: String) -> Date? {
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZ"
        if let date = formatter.date(from: string) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = formatter.date(from: string) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let date = formatter.date(from: string) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: string) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        if let date = formatter.date(from: string) {
            return date
        }

        return nil
    }

    public static func encode(date: Date) -> String {
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter.string(from: date)
    }
}
