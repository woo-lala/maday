import SwiftUI

enum AppColor {
    static let background = Color.white
    static let surface = Color.white
    static let overlay = Color.black.opacity(0.05)

    static let primary = Color(red: 91 / 255, green: 141 / 255, blue: 239 / 255)
    static let primaryStrong = Color(red: 70 / 255, green: 117 / 255, blue: 224 / 255)

    static let secondary = Color(red: 233 / 255, green: 78 / 255, blue: 61 / 255)
    static let secondaryStrong = Color(red: 204 / 255, green: 65 / 255, blue: 51 / 255)

    static let fitness = Color(red: 90 / 255, green: 200 / 255, blue: 150 / 255)
    static let learning = Color(red: 132 / 255, green: 94 / 255, blue: 247 / 255)

    static let neutralButton = Color(red: 235 / 255, green: 237 / 255, blue: 244 / 255)
    static let textPrimary = Color(red: 23 / 255, green: 26 / 255, blue: 31 / 255)
    static let textSecondary = Color(red: 86 / 255, green: 93 / 255, blue: 109 / 255)

    static let border = Color(red: 222 / 255, green: 225 / 255, blue: 230 / 255)
    static let shadow = Color.black.opacity(0.1)

    static let clear = Color.clear
    static let white = Color.white
}

enum AppFont {
    static func largeTitle() -> Font { .system(size: 28, weight: .bold) }
    static func title() -> Font { .system(size: 20, weight: .semibold) }
    static func headline() -> Font { .system(size: 18, weight: .semibold) }
    static func heading() -> Font { .system(size: 16, weight: .semibold) }
    static func body() -> Font { .system(size: 15, weight: .medium) }
    static func bodyRegular() -> Font { .system(size: 15, weight: .regular) }
    static func callout() -> Font { .system(size: 14, weight: .medium) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
    static func badge() -> Font { .system(size: 12, weight: .semibold) }
    static func button() -> Font { .system(size: 16, weight: .semibold) }
}

enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let smallPlus: CGFloat = 12
    static let medium: CGFloat = 16
    static let mediumPlus: CGFloat = 20
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
}

enum AppRadius {
    static let standard: CGFloat = 12
}

enum AppShadow {
    static let card = AppColor.shadow
    static let radius: CGFloat = 2
    static let x: CGFloat = 0
    static let y: CGFloat = 0
}

enum AppMetrics {
    static let buttonHeight: CGFloat = 48
    static let iconSize: CGFloat = 18
    static let toolbarIconSize: CGFloat = 36
}
