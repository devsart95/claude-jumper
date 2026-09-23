import AppKit
import SpriteKit

enum GameTheme: String, CaseIterable {
    case lightBackground
    case darkBackground

    private static let defaultsKey = "gameTheme"

    static var saved: GameTheme {
        guard let value = UserDefaults.standard.string(forKey: defaultsKey),
              let theme = GameTheme(rawValue: value) else {
            return .darkBackground
        }
        return theme
    }

    var displayName: String {
        switch self {
        case .lightBackground: "Sobre fondo claro"
        case .darkBackground: "Sobre fondo oscuro"
        }
    }

    var foreground: NSColor {
        switch self {
        case .lightBackground: Theme.ink
        case .darkBackground: Theme.paper
        }
    }

    var mutedForeground: NSColor {
        switch self {
        case .lightBackground: Theme.ink.withAlphaComponent(0.56)
        case .darkBackground: Theme.paper.withAlphaComponent(0.72)
        }
    }

    var creatorBlue: NSColor {
        switch self {
        case .lightBackground: Theme.creatorBlue
        case .darkBackground: Theme.creatorBlueBright
        }
    }

    var signatureColor: NSColor {
        switch self {
        case .lightBackground: Theme.signatureViolet
        case .darkBackground: Theme.signatureAmber
        }
    }

    var shadow: NSColor {
        switch self {
        case .lightBackground: NSColor(calibratedWhite: 0.02, alpha: 0.16)
        case .darkBackground: NSColor(calibratedWhite: 0.98, alpha: 0.18)
        }
    }

    var next: GameTheme {
        self == .lightBackground ? .darkBackground : .lightBackground
    }

    var symbolName: String {
        self == .lightBackground ? "sun.max.fill" : "moon.stars.fill"
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
    }
}

enum Theme {
    static let ink = NSColor(calibratedRed: 0.12, green: 0.11, blue: 0.10, alpha: 1)
    static let paper = NSColor(calibratedRed: 0.97, green: 0.94, blue: 0.88, alpha: 0.94)
    static let terracotta = NSColor(calibratedRed: 0.82, green: 0.36, blue: 0.22, alpha: 1)
    static let creatorBlue = NSColor(calibratedRed: 0.05, green: 0.43, blue: 0.96, alpha: 1)
    static let creatorBlueBright = NSColor(calibratedRed: 0.33, green: 0.67, blue: 1.00, alpha: 1)
    static let signatureViolet = NSColor(calibratedRed: 0.36, green: 0.13, blue: 0.78, alpha: 1)
    static let signatureAmber = NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.25, alpha: 1)
}
