import Foundation
import SwiftData

// MARK: - Budget Service: Auto-categorization and Pay Yourself First logic
final class BudgetService {
    static let shared = BudgetService()
    private init() {}

    // MARK: - Auto-categorize transactions into budget categories
    func categorizeToBudget(
        transaction: TransactionModel,
        budget: BudgetModel
    ) -> String? {
        guard !transaction.isIncome else { return nil }

        // First try MCC code matching
        if let mcc = transaction.categoryMCC {
            for category in budget.categories {
                if category.mccCodes.contains(mcc) {
                    return category.id
                }
            }
        }

        // Fall back to name matching
        let txName = transaction.categoryName.lowercased()
        for category in budget.categories {
            if category.name.lowercased() == txName {
                return category.id
            }
        }

        // Default to "Other"
        return budget.categories.last?.id
    }

    // MARK: - Apply Pay Yourself First to income
    func applyPayYourselfFirst(
        incomeAmount: Double,    // in minor units
        budget: BudgetModel
    ) -> PayYourselfFirstResult {
        let savingsAmount = incomeAmount * budget.savingsPercent
        let spendableAmount = incomeAmount - savingsAmount

        return PayYourselfFirstResult(
            totalIncome: incomeAmount,
            savingsAmount: savingsAmount,
            spendableAmount: spendableAmount,
            savingsPercent: budget.savingsPercent
        )
    }

    // MARK: - Update budget spent amounts
    func updateBudgetSpending(
        budget: inout BudgetModel,
        transactions: [TransactionModel]
    ) {
        // Reset spent amounts
        for i in budget.categories.indices {
            budget.categories[i].spentAmount = 0
        }

        let expenses = transactions.filter { !$0.isIncome }
        for transaction in expenses {
            guard let budgetCategoryID = transaction.budgetCategoryID else { continue }
            if let index = budget.categories.firstIndex(where: { $0.id == budgetCategoryID }) {
                budget.categories[index].spentAmount += transaction.absoluteAmount * 100
            }
        }
    }

    // MARK: - Calculate financial health score (0-100)
    func calculateHealthScore(
        budget: BudgetModel,
        transactions: [TransactionModel],
        savingsGoals: [SavingsGoalModel]
    ) -> Int {
        var score = 0

        // Savings rate (max 30 points)
        let savingsRate = budget.totalIncome > 0 ? budget.savingsTarget / budget.totalIncome : 0
        if savingsRate >= 0.20 { score += 30 }
        else if savingsRate >= 0.10 { score += 20 }
        else if savingsRate > 0 { score += 10 }

        // Budget adherence (max 40 points)
        let overBudgetCategories = budget.categories.filter { $0.isOverBudget }.count
        let totalCategories = budget.categories.count
        if totalCategories > 0 {
            let adherenceRate = Double(totalCategories - overBudgetCategories) / Double(totalCategories)
            score += Int(adherenceRate * 40)
        }

        // Savings goals progress (max 20 points)
        if !savingsGoals.isEmpty {
            let avgProgress = savingsGoals.reduce(0.0) { $0 + $1.progress } / Double(savingsGoals.count)
            score += Int(avgProgress * 20)
        } else {
            score += 10 // Neutral if no goals set
        }

        // Unallocated budget (max 10 points) - reward fully allocated budgets
        if budget.totalIncome > 0 && budget.unallocated >= 0 && budget.unallocated < budget.spendableIncome * 0.1 {
            score += 10
        } else if budget.unallocated >= 0 {
            score += 5
        }

        return min(100, score)
    }

    // MARK: - Monthly summary
    func monthSummary(
        transactions: [TransactionModel],
        budget: BudgetModel
    ) -> MonthSummary {
        let income = transactions.filter { $0.isIncome }.reduce(0.0) { $0 + $1.absoluteAmount }
        let expenses = transactions.filter { !$0.isIncome }.reduce(0.0) { $0 + $1.absoluteAmount }
        let netFlow = income - expenses
        let savingsAmount = budget.savingsTarget / 100

        return MonthSummary(
            totalIncome: income,
            totalExpenses: expenses,
            netCashFlow: netFlow,
            savingsContributed: savingsAmount,
            expensesByCategory: Dictionary(
                grouping: transactions.filter { !$0.isIncome },
                by: { $0.categoryName }
            ).mapValues { $0.reduce(0.0) { $0 + $1.absoluteAmount } }
        )
    }
}

// MARK: - Result Types
struct PayYourselfFirstResult {
    let totalIncome: Double
    let savingsAmount: Double
    let spendableAmount: Double
    let savingsPercent: Double

    var savingsDisplay: String { (savingsAmount / 100).currencyFormatted }
    var spendableDisplay: String { (spendableAmount / 100).currencyFormatted }
}

struct MonthSummary {
    let totalIncome: Double
    let totalExpenses: Double
    let netCashFlow: Double
    let savingsContributed: Double
    let expensesByCategory: [String: Double]

    var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return savingsContributed / totalIncome
    }
}
