import Foundation
import SwiftData

@Model
final class TransactionModel {
    var id: String
    var amount: Double           // positive = income, negative = expense (in minor currency units / 100)
    var currencyCode: Int        // ISO 4217
    var date: Date
    var transactionDescription: String
    var comment: String?
    var categoryMCC: Int?        // Monobank MCC code
    var categoryName: String
    var categoryEmoji: String
    var isIncome: Bool
    var source: TransactionSource
    var budgetCategoryID: String?
    var monobankID: String?
    var isManual: Bool

    init(
        id: String = UUID().uuidString,
        amount: Double,
        currencyCode: Int = 980,
        date: Date = Date(),
        description: String,
        comment: String? = nil,
        categoryMCC: Int? = nil,
        categoryName: String,
        categoryEmoji: String,
        isIncome: Bool,
        source: TransactionSource = .manual,
        budgetCategoryID: String? = nil,
        monobankID: String? = nil,
        isManual: Bool = true
    ) {
        self.id = id
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.transactionDescription = description
        self.comment = comment
        self.categoryMCC = categoryMCC
        self.categoryName = categoryName
        self.categoryEmoji = categoryEmoji
        self.isIncome = isIncome
        self.source = source
        self.budgetCategoryID = budgetCategoryID
        self.monobankID = monobankID
        self.isManual = isManual
    }

    var amountFormatted: String {
        let value = abs(amount) / 100.0
        let sign = isIncome ? "+" : "-"
        return "\(sign)\(value.currencyFormatted)"
    }

    var absoluteAmount: Double { abs(amount) / 100.0 }
}

enum TransactionSource: String, Codable {
    case monobank = "monobank"
    case manual = "manual"
}
