import SwiftUI

extension Color {
    /// Initialize a Color from a hex string like "#RRGGBB" or "RRGGBB".
    init(hex: String, alpha: Double = 1.0) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    // Core palette
    static let mdPrimary = Color(hex: "3D7AF5")
    static let mdPrimaryStrong = Color(hex: "2F63C8")
    static let mdDestructive = Color(hex: "FF3B30")

    // Backgrounds
    static let mdBackground = Color(hex: "F2F2F7")
    static let mdCard = Color(hex: "FFFFFF")

    // Text
    static let mdTextPrimary = Color(hex: "000000")
    static let mdTextSecondary = Color(hex: "8E8E93")

    // Category tags
    static let mdWork = Color(hex: "3D7AF5")      // blue
    static let mdFitness = Color(hex: "26BA67")   // green
    static let mdLearning = Color(hex: "FFC23F")  // yellow
    static let mdYoutube = Color(hex: "E94E3D")   // red
    static let mdShopping = Color(hex: "2EB97F")  // green variant
    static let mdCooking = Color(hex: "6B7280")   // gray
}
