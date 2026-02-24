import Foundation
import SwiftData
import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var selectedBudget: BudgetModel?
    @Published var isEditing = false
    @Published var showingAddCategory = false
    @Published var showingBudgetSetup = false

    private let budgetService = BudgetService.shared

    func ensureCurrentMonthBudget(budgets: [BudgetModel], context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        if let existing = budgets.first(where: { $0.month == month && $0.year == year }) {
            selectedBudget = existing
        } else {
            showingBudgetSetup = true
        }
    }

    func createBudget(
        month: Int,
        year: Int,
        income: Double,
        savingsPercent: Double,
        context: ModelContext
    ) -> BudgetModel {
        let budget = BudgetModel(
            month: month,
            year: year,
            totalIncome: income * 100,
            savingsTarget: income * savingsPercent * 100,
            savingsPercent: savingsPercent
        )
        context.insert(budget)
        try? context.save()
        selectedBudget = budget
        return budget
    }

    func updateCategoryAllocation(
        budget: BudgetModel,
        categoryID: String,
        amount: Double
    ) {
        if let index = budget.categories.firstIndex(where: { $0.id == categoryID }) {
            budget.categories[index].allocatedAmount = amount * 100
        }
    }

    func updateSavingsPercent(budget: BudgetModel, percent: Double) {
        budget.savingsPercent = percent
        budget.savingsTarget = budget.totalIncome * percent
    }

    func distributeRemainingEqually(budget: BudgetModel) {
        let remaining = budget.unallocated
        guard remaining > 0 else { return }
        let emptyCategories = budget.categories.filter { $0.allocatedAmount == 0 }
        guard !emptyCategories.isEmpty else { return }
        let perCategory = remaining / Double(emptyCategories.count)
        for i in budget.categories.indices {
            if budget.categories[i].allocatedAmount == 0 {
                budget.categories[i].allocatedAmount = perCategory
            }
        }
    }

    // Suggested allocation using 50/30/20 rule adapted
    func suggestAllocations(budget: BudgetModel) {
        let spendable = budget.spendableIncome
        let needs = spendable * 0.50     // 50% needs
        let wants = spendable * 0.30     // 30% wants
        // 20% already in savings via Pay Yourself First

        let needsCategories = ["Groceries", "Transport", "Health", "Utilities"]
        let wantsCategories = ["Dining", "Entertainment", "Shopping", "Education"]

        let needsPerCategory = needs / Double(needsCategories.count)
        let wantsPerCategory = wants / Double(wantsCategories.count)

        for i in budget.categories.indices {
            if needsCategories.contains(budget.categories[i].name) {
                budget.categories[i].allocatedAmount = needsPerCategory
            } else if wantsCategories.contains(budget.categories[i].name) {
                budget.categories[i].allocatedAmount = wantsPerCategory
            }
        }
    }
}
