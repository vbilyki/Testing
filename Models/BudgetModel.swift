import Foundation
import SwiftData

@Model
final class BudgetModel {
    var id: String
    var month: Int      // 1-12
    var year: Int
    var totalIncome: Double
    var savingsTarget: Double   // Pay Yourself First: amount set aside immediately
    var savingsPercent: Double  // e.g. 0.20 = 20%
    var categories: [BudgetCategoryItem]
    var createdAt: Date
    var notes: String?

    init(
        id: String = UUID().uuidString,
        month: Int,
        year: Int,
        totalIncome: Double = 0,
        savingsTarget: Double = 0,
        savingsPercent: Double = 0.20,
        categories: [BudgetCategoryItem] = BudgetCategoryItem.defaultCategories(),
        createdAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.totalIncome = totalIncome
        self.savingsTarget = savingsTarget
        self.savingsPercent = savingsPercent
        self.categories = categories
        self.createdAt = createdAt
        self.notes = notes
    }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(month)/\(year)"
    }

    var spendableIncome: Double {
        totalIncome - savingsTarget
    }

    var totalAllocated: Double {
        categories.reduce(0) { $0 + $1.allocatedAmount }
    }

    var unallocated: Double {
        spendableIncome - totalAllocated
    }

    static func currentMonthBudget() -> BudgetModel {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return BudgetModel(month: month, year: year)
    }
}

struct BudgetCategoryItem: Codable, Identifiable {
    var id: String
    var name: String
    var emoji: String
    var allocatedAmount: Double
    var spentAmount: Double
    var color: String   // hex color string
    var mccCodes: [Int]

    init(
        id: String = UUID().uuidString,
        name: String,
        emoji: String,
        allocatedAmount: Double = 0,
        spentAmount: Double = 0,
        color: String,
        mccCodes: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.allocatedAmount = allocatedAmount
        self.spentAmount = spentAmount
        self.color = color
        self.mccCodes = mccCodes
    }

    var remainingAmount: Double { allocatedAmount - spentAmount }
    var usagePercent: Double {
        guard allocatedAmount > 0 else { return 0 }
        return min(spentAmount / allocatedAmount, 1.0)
    }
    var isOverBudget: Bool { spentAmount > allocatedAmount }

    static func defaultCategories() -> [BudgetCategoryItem] {
        return [
            BudgetCategoryItem(name: "Groceries", emoji: "🛒", color: "#4CAF50",
                               mccCodes: [5411, 5412, 5441, 5451, 5462, 5499]),
            BudgetCategoryItem(name: "Transport", emoji: "🚇", color: "#2196F3",
                               mccCodes: [4111, 4112, 4121, 4131, 5541, 5542, 7011]),
            BudgetCategoryItem(name: "Dining", emoji: "🍽️", color: "#FF9800",
                               mccCodes: [5812, 5813, 5814]),
            BudgetCategoryItem(name: "Health", emoji: "💊", color: "#E91E63",
                               mccCodes: [5047, 5122, 5912, 8011, 8021, 8031, 8049, 8099]),
            BudgetCategoryItem(name: "Entertainment", emoji: "🎬", color: "#9C27B0",
                               mccCodes: [5735, 5945, 7012, 7832, 7922, 7929, 7941, 7993, 7996, 7999]),
            BudgetCategoryItem(name: "Shopping", emoji: "🛍️", color: "#FF5722",
                               mccCodes: [5311, 5600, 5621, 5631, 5641, 5651, 5661, 5691, 5699, 5732, 5734]),
            BudgetCategoryItem(name: "Utilities", emoji: "💡", color: "#607D8B",
                               mccCodes: [4900, 4911, 4924, 4941, 4961]),
            BudgetCategoryItem(name: "Education", emoji: "📚", color: "#00BCD4",
                               mccCodes: [5942, 8211, 8220, 8241, 8244, 8249, 8299]),
            BudgetCategoryItem(name: "Other", emoji: "📦", color: "#9E9E9E", mccCodes: [])
        ]
    }
}
