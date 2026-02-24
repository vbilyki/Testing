import Foundation
import SwiftData

@Model
final class CategoryModel {
    var id: String
    var name: String
    var emoji: String
    var colorHex: String
    var mccCodes: [Int]
    var keywords: [String]
    var isSystem: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        emoji: String,
        colorHex: String,
        mccCodes: [Int] = [],
        keywords: [String] = [],
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.mccCodes = mccCodes
        self.keywords = keywords
        self.isSystem = isSystem
    }
}

// MARK: - MCC Category Mapping
struct MCCCategoryMapper {
    static let mccToCategory: [Int: (name: String, emoji: String)] = [
        // Food & Grocery
        5411: ("Groceries", "🛒"), 5412: ("Groceries", "🛒"), 5441: ("Groceries", "🛒"),
        5451: ("Groceries", "🛒"), 5462: ("Groceries", "🛒"), 5499: ("Groceries", "🛒"),
        5812: ("Dining", "🍽️"), 5813: ("Dining", "🍽️"), 5814: ("Dining", "🍽️"),
        // Transport
        4111: ("Transport", "🚇"), 4112: ("Transport", "🚇"), 4121: ("Transport", "🚗"),
        4131: ("Transport", "🚌"), 5541: ("Fuel", "⛽"), 5542: ("Fuel", "⛽"),
        // Health
        5047: ("Health", "💊"), 5122: ("Health", "💊"), 5912: ("Health", "💊"),
        8011: ("Healthcare", "🏥"), 8021: ("Healthcare", "🏥"), 8031: ("Healthcare", "🏥"),
        8049: ("Healthcare", "🏥"), 8099: ("Healthcare", "🏥"),
        // Entertainment
        5735: ("Entertainment", "🎬"), 7832: ("Cinema", "🎬"), 7922: ("Entertainment", "🎭"),
        7929: ("Entertainment", "🎭"), 7941: ("Sports", "⚽"), 7993: ("Games", "🎮"),
        7996: ("Games", "🎮"), 7999: ("Recreation", "🎯"),
        // Shopping
        5311: ("Department Store", "🏬"), 5600: ("Clothing", "👕"), 5621: ("Clothing", "👗"),
        5631: ("Clothing", "👗"), 5641: ("Children's Clothing", "👶"), 5651: ("Clothing", "👕"),
        5661: ("Shoes", "👟"), 5691: ("Clothing", "👕"), 5699: ("Clothing", "👕"),
        5732: ("Electronics", "📱"), 5734: ("Electronics", "💻"),
        // Utilities
        4900: ("Utilities", "💡"), 4911: ("Utilities", "💡"), 4924: ("Gas", "🔥"),
        4941: ("Water", "💧"), 4961: ("Heating", "🌡️"),
        // Education
        5942: ("Books", "📚"), 8211: ("Education", "🎓"), 8220: ("Education", "🎓"),
        8241: ("Education", "🎓"), 8244: ("Education", "🎓"), 8249: ("Education", "🎓"),
        8299: ("Education", "🎓"),
        // Travel
        4411: ("Travel", "✈️"), 4511: ("Travel", "✈️"), 7011: ("Hotel", "🏨"),
        7012: ("Hotel", "🏨"), 4722: ("Travel Agency", "🗺️"),
        // Finance
        6010: ("ATM", "🏧"), 6011: ("ATM", "🏧"), 6012: ("Bank", "🏦"),
        6051: ("Currency Exchange", "💱"), 6211: ("Investment", "📈"),
        // Beauty
        7230: ("Beauty", "💇"), 7231: ("Beauty", "💇"), 7297: ("Beauty", "💆"),
    ]

    static func category(forMCC mcc: Int) -> (name: String, emoji: String) {
        return mccToCategory[mcc] ?? ("Other", "📦")
    }

    static func category(forDescription description: String, mcc: Int) -> (name: String, emoji: String) {
        let mapped = category(forMCC: mcc)
        if mapped.name != "Other" { return mapped }

        let lower = description.lowercased()
        if lower.contains("uber") || lower.contains("bolt") || lower.contains("taxi") {
            return ("Transport", "🚗")
        } else if lower.contains("netflix") || lower.contains("spotify") || lower.contains("apple") {
            return ("Subscriptions", "📱")
        } else if lower.contains("salary") || lower.contains("зарплата") || lower.contains("дохід") {
            return ("Income", "💰")
        }
        return ("Other", "📦")
    }
}
