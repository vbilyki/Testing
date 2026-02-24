import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [TransactionModel]
    @Query private var budgets: [BudgetModel]
    @Query private var savingsGoals: [SavingsGoalModel]
    @Query private var accounts: [MonobankAccountModel]

    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingSync = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard

                    // Pay Yourself First Banner
                    if let pyf = viewModel.payYourselfFirstResult {
                        payYourselfFirstCard(result: pyf)
                    }

                    // Monthly Overview
                    if let summary = viewModel.monthSummary {
                        monthlyOverviewCard(summary: summary)
                    }

                    // Active Budget Categories
                    if let budget = viewModel.currentBudget {
                        budgetCategoriesSection(budget: budget)
                    }

                    // Recent Transactions
                    recentTransactionsSection

                    // Top Savings Goal
                    if let topGoal = viewModel.savingsGoals.first {
                        topGoalCard(goal: topGoal)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("WealthWise")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.gradient)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.syncMonobank(accounts: accounts, context: modelContext)
                        }
                    } label: {
                        if viewModel.isSyncing {
                            ProgressView().tint(AppTheme.primary)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .disabled(viewModel.isSyncing || accounts.isEmpty)
                }
            }
            .onAppear {
                viewModel.loadData(
                    transactions: transactions,
                    budgets: budgets,
                    goals: savingsGoals
                )
            }
            .onChange(of: transactions.count) { _, _ in
                viewModel.loadData(transactions: transactions, budgets: budgets, goals: savingsGoals)
            }
            .alert("Sync Error", isPresented: .constant(viewModel.syncError != nil)) {
                Button("OK") { viewModel.syncError = nil }
            } message: {
                Text(viewModel.syncError ?? "")
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.currentBudget?.displayName ?? "No Budget Set")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(viewModel.monthSummary.map {
                            "Balance: \(($0.totalIncome - $0.totalExpenses).currencyFormatted)"
                        } ?? "Set up your budget")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                    HealthScoreRing(score: viewModel.healthScore)
                }

                if let summary = viewModel.monthSummary {
                    HStack(spacing: 12) {
                        StatPill(
                            label: "Income",
                            value: summary.totalIncome.currencyFormatted,
                            color: AppTheme.success
                        )
                        StatPill(
                            label: "Expenses",
                            value: summary.totalExpenses.currencyFormatted,
                            color: AppTheme.danger
                        )
                        StatPill(
                            label: "Saved",
                            value: summary.savingsContributed.currencyFormatted,
                            color: AppTheme.primary
                        )
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Pay Yourself First Card
    private func payYourselfFirstCard(result: PayYourselfFirstResult) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.gradient)
                    Text("Pay Yourself First")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(result.savingsPercent * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.gradient)
                }

                Text("Before spending anything, \(result.savingsDisplay) goes directly to savings.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Set aside for saving")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(result.savingsDisplay)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Available to spend")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(result.spendableDisplay)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.success)
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
    }

    // MARK: - Monthly Overview Card
    private func monthlyOverviewCard(summary: MonthSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Monthly Overview")

                VStack(spacing: 10) {
                    overviewRow(
                        label: "Income",
                        amount: summary.totalIncome,
                        color: AppTheme.success,
                        icon: "arrow.down.circle.fill"
                    )
                    overviewRow(
                        label: "Expenses",
                        amount: summary.totalExpenses,
                        color: AppTheme.danger,
                        icon: "arrow.up.circle.fill"
                    )
                    Divider()
                    overviewRow(
                        label: "Net Cash Flow",
                        amount: summary.netCashFlow,
                        color: summary.netCashFlow >= 0 ? AppTheme.success : AppTheme.danger,
                        icon: "equal.circle.fill"
                    )
                }
            }
            .padding(20)
        }
    }

    private func overviewRow(label: String, amount: Double, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(amount.currencyFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }

    // MARK: - Budget Categories Section
    private func budgetCategoriesSection(budget: BudgetModel) -> some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Budget Categories")
            ForEach(budget.categories.filter { $0.allocatedAmount > 0 }.prefix(5), id: \.id) { category in
                CardView {
                    HStack(spacing: 12) {
                        Text(category.emoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(category.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\((category.spentAmount / 100).currencyFormatted) / \((category.allocatedAmount / 100).currencyFormatted)")
                                    .font(.caption)
                                    .foregroundColor(category.isOverBudget ? AppTheme.danger : AppTheme.textSecondary)
                            }
                            BudgetProgressBar(
                                progress: category.usagePercent,
                                color: Color(hex: category.color)
                            )
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Transactions")
            if viewModel.recentTransactions.isEmpty {
                CardView {
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard.and.123")
                            .font(.largeTitle)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Connect Monobank or add manually")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                }
            } else {
                ForEach(viewModel.recentTransactions.prefix(5)) { tx in
                    TransactionRowView(transaction: tx)
                }
            }
        }
    }

    // MARK: - Top Goal Card
    private func topGoalCard(goal: SavingsGoalModel) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(goal.emoji)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.name)
                            .font(.headline)
                        Text("Top Savings Goal")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(goal.progress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.savingsGradient)
                }

                BudgetProgressBar(
                    progress: goal.progress,
                    color: AppTheme.primary,
                    height: 10
                )

                HStack {
                    Text("\(goal.currentAmount.currencyFormatted) saved")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(goal.remainingAmount.currencyFormatted) to go")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(20)
        }
    }
}
