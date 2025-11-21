import SwiftUI

enum AppColor {
    static let background = Color.mdBackground
    static let surface = Color.mdCard
    static let overlay = Color.black.opacity(0.05)

    static let primary = Color.mdPrimary
    static let primaryStrong = Color.mdPrimaryStrong
    static let destructive = Color.mdDestructive

    static let secondary = Color.mdPrimary // fallback
    static let secondaryStrong = Color.mdPrimaryStrong

    static let work = Color.mdWork
    static let fitness = Color.mdFitness
    static let learning = Color.mdLearning
    static let youtube = Color.mdYoutube
    static let shopping = Color.mdShopping
    static let cooking = Color.mdCooking

    static let neutralButton = Color.mdBackground
    static let textPrimary = Color.mdTextPrimary
    static let textSecondary = Color.mdTextSecondary

    static let border = Color.black.opacity(0.08)
    static let shadow = Color.black.opacity(0.05)

    static let clear = Color.clear
    static let white = Color.white
}

enum AppFont {
    static func largeTitle() -> Font { .system(size: 34, weight: .bold) }
    static func title() -> Font { .system(size: 20, weight: .bold) }
    static func headline() -> Font { .system(size: 18, weight: .semibold) }
    static func heading() -> Font { .system(size: 17, weight: .semibold) } // Card title
    static func body() -> Font { .system(size: 15, weight: .regular) }
    static func bodyRegular() -> Font { .system(size: 15, weight: .regular) }
    static func callout() -> Font { .system(size: 14, weight: .medium) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
    static func badge() -> Font { .system(size: 12, weight: .semibold) }
    static func button() -> Font { .system(size: 16, weight: .semibold) }
    static func timerDisplay() -> Font { .system(size: 48, weight: .bold, design: .monospaced) }
}

enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let smallPlus: CGFloat = 12 // default vertical stack spacing
    static let medium: CGFloat = 16 // card/internal padding
    static let mediumPlus: CGFloat = 20 // screen horizontal padding
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
}

enum AppRadius {
    static let standard: CGFloat = 16 // cards/containers
    static let button: CGFloat = 12
    static let badge: CGFloat = 4
}

enum AppShadow {
    static let card = AppColor.shadow
    static let radius: CGFloat = 5
    static let x: CGFloat = 0
    static let y: CGFloat = 2
}

enum AppMetrics {
    static let buttonHeight: CGFloat = 48
    static let iconSize: CGFloat = 18
    static let toolbarIconSize: CGFloat = 36
}
