//
//  AppSettings.swift
//  HomeMeasure
//
//  App-wide preferences (theme, units, currency, notifications). Backed by
//  UserDefaults so every change persists between launches. Exposed as an
//  EnvironmentObject and drives preferredColorScheme on the root view.
//

import SwiftUI
import Combine

final class AppSettings: ObservableObject {

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let theme = "settings.theme"
        static let units = "settings.units"
        static let currency = "settings.currency"
        static let notifications = "settings.notifications"
        static let haptics = "settings.haptics"
        static let detail = "settings.detail"
        static let accent = "settings.accent"
    }

    @Published var themeMode: ThemeMode {
        didSet { defaults.set(themeMode.rawValue, forKey: Keys.theme) }
    }
    @Published var unitSystem: UnitSystem {
        didSet { defaults.set(unitSystem.rawValue, forKey: Keys.units) }
    }
    @Published var currencyCode: String {
        didSet { defaults.set(currencyCode, forKey: Keys.currency) }
    }
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    @Published var detailLevel: DetailLevel {
        didSet { defaults.set(detailLevel.rawValue, forKey: Keys.detail) }
    }

    init() {
        themeMode = ThemeMode(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system
        unitSystem = UnitSystem(rawValue: defaults.string(forKey: Keys.units) ?? "") ?? .metric
        currencyCode = defaults.string(forKey: Keys.currency) ?? "USD"
        // Default-on the first time the key doesn't exist yet.
        notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        detailLevel = DetailLevel(rawValue: defaults.string(forKey: Keys.detail) ?? "") ?? .standard
    }

    var colorScheme: ColorScheme? { themeMode.colorScheme }

    // Currency formatting -------------------------------------------------
    static let currencies: [(code: String, symbol: String, name: String)] = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("RUB", "₽", "Russian Ruble"),
        ("JPY", "¥", "Japanese Yen"),
        ("CAD", "C$", "Canadian Dollar")
    ]

    var currencySymbol: String {
        AppSettings.currencies.first { $0.code == currencyCode }?.symbol ?? "$"
    }

    func money(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        let whole = rounded == rounded.rounded()
        let number: String
        if whole {
            number = AppSettings.grouped(Int(rounded))
        } else {
            number = String(format: "%.2f", rounded)
        }
        return "\(currencySymbol)\(number)"
    }

    private static func grouped(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func length(_ value: Double) -> String {
        formatNumber(value) + " " + unitSystem.lengthUnit
    }
    func area(_ value: Double) -> String {
        formatNumber(value) + " " + unitSystem.areaUnit
    }
    func formatNumber(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
