import SwiftUI
import UIKit

extension Color {
    /// Initialize a Color from a hex string like "#RRGGBB" or "RRGGBB".
    /// If the hex matches a known application color, it will return an adaptive color (Muted in Dark Mode).
    init(hex: String, alpha: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "#", with: "")
        
        // Known mappings from Light Mode Hex to Dark Mode Muted Hex
        let mappings: [String: String] = [
            "3D7AF5": "6B93D6", // Primary / Work
            "2F63C8": "4A70B6", // PrimaryStrong
            "FF3B30": "D65C54", // Destructive
            "26BA67": "5FA879", // Fitness
            "FFC23F": "D6B567", // Learning
            "E94E3D": "C26D64", // Youtube / Personal
            "2EB97F": "67A88F", // Shopping
            "6B7280": "8E939E"  // Cooking
        ]
        
        if let darkHex = mappings[cleaned] {
            self.init(uiColor: UIColor { trait in
                return trait.userInterfaceStyle == .dark 
                    ? UIColor(hex: darkHex, alpha: alpha) 
                    : UIColor(hex: cleaned, alpha: alpha)
            })
            return
        }

        // Fallback for unknown colors
        self.init(uiColor: UIColor(hex: cleaned, alpha: alpha))
    }
    
    /// Create a dynamic color that adapts to Light and Dark mode
    private static func semantic(light: String, dark: String) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark 
                ? UIColor(hex: dark) 
                : UIColor(hex: light)
        })
    }

    // MARK: - Core Palette
    // Muted Dark Mode: Desaturated/Softer options to reduce eye strain and allow focus
    
    static let mdPrimary = semantic(light: "3D7AF5", dark: "5E89D6") // Desaturated Blue
    static let mdPrimaryStrong = semantic(light: "2F63C8", dark: "4A70B6") // Muted Strong Blue
    static let mdDestructive = semantic(light: "FF3B30", dark: "D65C54") // Muted Red

    // MARK: - Backgrounds
    static let mdBackground = semantic(light: "F2F2F7", dark: "121212") // Soft Dark Background
    static let mdCard = semantic(light: "FFFFFF", dark: "1C1C1E") // Dark Card Background

    // MARK: - Text
    static let mdTextPrimary = semantic(light: "000000", dark: "E1E1E1") // Off-white, not harsh
    static let mdTextSecondary = semantic(light: "8E8E93", dark: "A0A0A0") // Lighter Gray for dark mode

    // MARK: - Category Tags
    // Muted/Pastel versions for dark mode
    static let mdWork = semantic(light: "3D7AF5", dark: "6B93D6")      // Muted Blue
    static let mdFitness = semantic(light: "26BA67", dark: "5FA879")   // Sage Green
    static let mdLearning = semantic(light: "FFC23F", dark: "D6B567")  // Muted Gold/Sand
    static let mdYoutube = semantic(light: "E94E3D", dark: "C26D64")   // Terra Cotta
    static let mdShopping = semantic(light: "2EB97F", dark: "67A88F")  // Muted Teal
    static let mdCooking = semantic(light: "6B7280", dark: "8E939E")   // Muted Cool Gray
    
    // MARK: - Elements
    static let mdBorder = Color(UIColor { trait in
        return trait.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.15) : UIColor(white: 0.0, alpha: 0.08)
    })
    
    static let mdOverlay = Color(UIColor { trait in
        return trait.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.10) : UIColor(white: 0.0, alpha: 0.05)
    })
    
    static let mdShadow = Color(UIColor { trait in
        return trait.userInterfaceStyle == .dark ? UIColor(white: 0.0, alpha: 0.5) : UIColor(white: 0.0, alpha: 0.05)
    })

    // Helper to get hex string from Color
    func toHex() -> String? {
        // Convert to UIColor to easily extract components
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // getRed(_:green:blue:alpha:) works for most color spaces by converting to RGB
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return String(format: "%02lX%02lX%02lX", lroundf(Float(red) * 255), lroundf(Float(green) * 255), lroundf(Float(blue) * 255))
        }
        
        return nil
    }
}

// Helper extension for UIColor to reuse hex logic
extension UIColor {
    convenience init(hex: String, alpha: Double = 1.0) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: CGFloat(alpha))
    }
}
