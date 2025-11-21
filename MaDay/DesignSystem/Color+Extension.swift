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
    static let mdPrimary = Color(hex: "4A90E2")
    static let mdPrimaryStrong = Color(hex: "3E7BC4")
    static let mdDestructive = Color(hex: "FF3B30")

    // Backgrounds
    static let mdBackground = Color(hex: "F2F2F7")
    static let mdCard = Color(hex: "FFFFFF")

    // Text
    static let mdTextPrimary = Color(hex: "000000")
    static let mdTextSecondary = Color(hex: "8E8E93")

    // Category tags
    static let mdWork = Color(hex: "5856D6")
    static let mdFitness = Color(hex: "34C759")
    static let mdLearning = Color(hex: "FFCC00")
    static let mdYoutube = Color(hex: "FF2D55")
    static let mdShopping = Color(hex: "8E8E93")
    static let mdCooking = Color(hex: "A2845E")
}
