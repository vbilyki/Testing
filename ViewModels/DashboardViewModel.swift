import Foundation
import SwiftData
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var currentBudget: BudgetModel?
    @Published var recentTransactions: [TransactionModel] = []
    @Published var savingsGoals: [SavingsGoalModel] = []
    @Published var healthScore: Int = 0
    @Published var monthSummary: MonthSummary?
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var payYourselfFirstResult: PayYourselfFirstResult?

    private let budgetService = BudgetService.shared
    private let monobankService = MonobankService.shared

    func loadData(
        transactions: [TransactionModel],
        budgets: [BudgetModel],
        goals: [SavingsGoalModel]
    ) {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        currentBudget = budgets.first { $0.month == month && $0.year == year }
        savingsGoals = goals.filter { !$0.isCompleted }.sorted { $0.priority.rawValue < $1.priority.rawValue }

        let currentMonthTransactions = transactions.filter {
            let txMonth = calendar.component(.month, from: $0.date)
            let txYear = calendar.component(.year, from: $0.date)
            return txMonth == month && txYear == year
        }

        recentTransactions = Array(
            currentMonthTransactions.sorted { $0.date > $1.date }.prefix(10)
        )

        if let budget = currentBudget {
            monthSummary = budgetService.monthSummary(
                transactions: currentMonthTransactions,
                budget: budget
            )
            healthScore = budgetService.calculateHealthScore(
                budget: budget,
                transactions: currentMonthTransactions,
                savingsGoals: savingsGoals
            )

            if budget.totalIncome > 0 {
                payYourselfFirstResult = budgetService.applyPayYourselfFirst(
                    incomeAmount: budget.totalIncome,
                    budget: budget
                )
            }
        }
    }

    func syncMonobank(accounts: [MonobankAccountModel], context: ModelContext) async {
        guard let linkedAccount = accounts.first(where: { $0.isLinked }) else {
            syncError = "No linked Monobank account found."
            return
        }

        isSyncing = true
        syncError = nil

        do {
            let existingIDs = Set(
                (try? context.fetch(FetchDescriptor<TransactionModel>()))?.compactMap { $0.monobankID } ?? []
            )

            let newTransactions = try await monobankService.syncCurrentMonth(
                accountID: linkedAccount.accountID,
                existingIDs: existingIDs
            )

            for tx in newTransactions {
                context.insert(tx)
            }

            try context.save()
            linkedAccount.lastSyncDate = Date()

        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
    }
}
