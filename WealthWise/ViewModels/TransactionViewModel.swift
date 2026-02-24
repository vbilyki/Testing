import Foundation
import SwiftData
import Combine

@MainActor
final class TransactionViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedFilter: TransactionFilter = .all
    @Published var selectedPeriod: TimePeriod = .thisMonth
    @Published var showingAddTransaction = false
    @Published var selectedTransaction: TransactionModel?

    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expenses = "Expenses"
    }

    enum TimePeriod: String, CaseIterable {
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case last3Months = "3 Months"
        case thisYear = "This Year"

        var dateRange: (from: Date, to: Date) {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .thisMonth:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return (start, now)
            case .lastMonth:
                let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
                return (lastMonthStart, thisMonthStart)
            case .last3Months:
                let start = calendar.date(byAdding: .month, value: -3, to: now)!
                return (start, now)
            case .thisYear:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
                return (start, now)
            }
        }
    }

    func filteredTransactions(_ transactions: [TransactionModel]) -> [TransactionModel] {
        let range = selectedPeriod.dateRange
        var result = transactions.filter { tx in
            tx.date >= range.from && tx.date <= range.to
        }

        switch selectedFilter {
        case .income:
            result = result.filter { $0.isIncome }
        case .expenses:
            result = result.filter { !$0.isIncome }
        case .all:
            break
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.transactionDescription.localizedCaseInsensitiveContains(searchText) ||
                $0.categoryName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted { $0.date > $1.date }
    }

    func groupByDate(_ transactions: [TransactionModel]) -> [(Date, [TransactionModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    func addManualTransaction(
        amount: Double,
        description: String,
        isIncome: Bool,
        categoryName: String,
        categoryEmoji: String,
        date: Date,
        budgetCategoryID: String?,
        context: ModelContext
    ) {
        let tx = TransactionModel(
            amount: isIncome ? amount * 100 : -amount * 100,
            date: date,
            description: description,
            categoryName: categoryName,
            categoryEmoji: categoryEmoji,
            isIncome: isIncome,
            source: .manual,
            budgetCategoryID: budgetCategoryID,
            isManual: true
        )
        context.insert(tx)
        try? context.save()
    }

    func deleteTransaction(_ transaction: TransactionModel, context: ModelContext) {
        context.delete(transaction)
        try? context.save()
    }
}
