import Foundation

@objc public class LocalizationHelper: NSObject {
    @objc public static func localizedString(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }

    @objc public static func localizedString(_ key: String, arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: arguments)
    }

    // Get current language
    @objc public static var currentLanguage: String {
        return Bundle.main.preferredLocalizations.first ?? "en"
    }

    // Check if it's a Chinese environment
    @objc public static var isChineseLanguage: Bool {
        return currentLanguage.hasPrefix("zh")
    }

    // Get language display name
    @objc public static func displayNameForLanguage(_ code: String) -> String {
        let locale = NSLocale(localeIdentifier: code)
        return locale.displayName(forKey: .identifier, value: code) ?? code
    }
}
