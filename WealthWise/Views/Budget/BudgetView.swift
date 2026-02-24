import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [BudgetModel]
    @Query(sort: \TransactionModel.date, order: .reverse) private var transactions: [TransactionModel]

    @StateObject private var viewModel = BudgetViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let budget = viewModel.selectedBudget ?? currentMonthBudget {
                    budgetContent(budget: budget)
                } else {
                    noBudgetView
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.showingBudgetSetup = true
                        } label: {
                            Label("New Budget", systemImage: "plus")
                        }
                        if let budget = viewModel.selectedBudget ?? currentMonthBudget {
                            Button {
                                viewModel.suggestAllocations(budget: budget)
                            } label: {
                                Label("Auto-Suggest (50/30/20)", systemImage: "wand.and.stars")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingBudgetSetup) {
                BudgetSetupView(viewModel: viewModel, context: modelContext)
            }
            .onAppear {
                viewModel.ensureCurrentMonthBudget(budgets: budgets, context: modelContext)
            }
        }
    }

    private var currentMonthBudget: BudgetModel? {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return budgets.first { $0.month == month && $0.year == year }
    }

    private var currentTransactions: [TransactionModel] {
        guard let budget = currentMonthBudget else { return [] }
        let calendar = Calendar.current
        return transactions.filter {
            calendar.component(.month, from: $0.date) == budget.month &&
            calendar.component(.year, from: $0.date) == budget.year
        }
    }

    @ViewBuilder
    private func budgetContent(budget: BudgetModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Budget Overview
                budgetOverviewCard(budget: budget)

                // Pay Yourself First
                payYourselfFirstCard(budget: budget)

                // Category Budget Cards
                VStack(spacing: 12) {
                    SectionHeader(title: "Categories")
                    ForEach(budget.categories, id: \.id) { category in
                        BudgetCategoryCard(
                            category: category,
                            budget: budget,
                            onUpdate: { newAmount in
                                viewModel.updateCategoryAllocation(
                                    budget: budget,
                                    categoryID: category.id,
                                    amount: newAmount
                                )
                                try? modelContext.save()
                            }
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func budgetOverviewCard(budget: BudgetModel) -> some View {
        CardView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(budget.displayName)
                            .font(.headline)
                        Text("Monthly Budget")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text((budget.totalIncome / 100).currencyFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.gradient)
                        Text("Total Income")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Allocation Summary
                VStack(spacing: 8) {
                    allocationRow(
                        label: "Savings (First!)",
                        amount: budget.savingsTarget / 100,
                        color: AppTheme.primary,
                        icon: "banknote.fill"
                    )
                    allocationRow(
                        label: "Allocated",
                        amount: budget.totalAllocated / 100,
                        color: AppTheme.success,
                        icon: "chart.pie.fill"
                    )
                    allocationRow(
                        label: "Unallocated",
                        amount: budget.unallocated / 100,
                        color: budget.unallocated < 0 ? AppTheme.danger : AppTheme.warning,
                        icon: "questionmark.circle.fill"
                    )
                }

                // Overall budget progress bar
                let totalUsed = budget.totalAllocated + budget.savingsTarget
                let usagePercent = budget.totalIncome > 0 ? totalUsed / budget.totalIncome : 0
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Budget Utilization")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(Int(usagePercent * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    BudgetProgressBar(progress: usagePercent, color: AppTheme.primary, height: 10)
                }
            }
            .padding(20)
        }
    }

    private func allocationRow(label: String, amount: Double, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
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

    private func payYourselfFirstCard(budget: BudgetModel) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Pay Yourself First", systemImage: "dollarsign.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.gradient)
                    Spacer()
                }

                Text("Savings are deducted from income BEFORE you budget for expenses.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                HStack {
                    Text("Savings Rate:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(budget.savingsPercent * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.gradient)
                }

                Slider(
                    value: Binding(
                        get: { budget.savingsPercent },
                        set: { newValue in
                            viewModel.updateSavingsPercent(budget: budget, percent: newValue)
                            try? modelContext.save()
                        }
                    ),
                    in: 0.05...0.50,
                    step: 0.05
                )
                .accentColor(AppTheme.primary)

                HStack {
                    Text("5% (Min)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("20% (Recommended)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.success)
                    Spacer()
                    Text("50% (Aggressive)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(20)
        }
    }

    private var noBudgetView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.gradient)
            Text("No Budget Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Create your first monthly budget to start tracking your spending and saving.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                viewModel.showingBudgetSetup = true
            } label: {
                Text("Create Budget")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.gradient)
                    .cornerRadius(14)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
}

// MARK: - Budget Category Card
struct BudgetCategoryCard: View {
    let category: BudgetCategoryItem
    let budget: BudgetModel
    let onUpdate: (Double) -> Void

    @State private var showingEdit = false
    @State private var editAmount = ""

    var body: some View {
        CardView {
            VStack(spacing: 10) {
                HStack {
                    Text(category.emoji)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if category.allocatedAmount > 0 {
                            Text("\((category.spentAmount / 100).currencyFormatted) spent of \((category.allocatedAmount / 100).currencyFormatted)")
                                .font(.caption)
                                .foregroundColor(category.isOverBudget ? AppTheme.danger : AppTheme.textSecondary)
                        } else {
                            Text("Not budgeted")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    Spacer()
                    Button {
                        editAmount = category.allocatedAmount > 0 ? String(format: "%.0f", category.allocatedAmount / 100) : ""
                        showingEdit = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(AppTheme.primary)
                    }
                }

                if category.allocatedAmount > 0 {
                    BudgetProgressBar(
                        progress: category.usagePercent,
                        color: Color(hex: category.color)
                    )
                }
            }
            .padding(14)
        }
        .alert("Set Budget for \(category.name)", isPresented: $showingEdit) {
            TextField("Amount (₴)", text: $editAmount)
                .keyboardType(.numberPad)
            Button("Save") {
                if let amount = Double(editAmount) {
                    onUpdate(amount)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Budget Setup View
struct BudgetSetupView: View {
    @ObservedObject var viewModel: BudgetViewModel
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss

    @State private var income = ""
    @State private var savingsPercent: Double = 0.20
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        NavigationStack {
            Form {
                Section("Income") {
                    HStack {
                        Text("₴")
                        TextField("Monthly income", text: $income)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    HStack {
                        Text("Savings First:")
                        Spacer()
                        Text("\(Int(savingsPercent * 100))%")
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.gradient)
                    }
                    Slider(value: $savingsPercent, in: 0.05...0.50, step: 0.05)
                        .accentColor(AppTheme.primary)

                    if let incomeValue = Double(income) {
                        let savingsAmount = incomeValue * savingsPercent
                        let spendable = incomeValue - savingsAmount
                        HStack {
                            Label("Savings: \(savingsAmount.currencyFormatted)", systemImage: "banknote")
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            Spacer()
                            Label("Spendable: \(spendable.currencyFormatted)", systemImage: "cart")
                                .font(.caption)
                                .foregroundColor(AppTheme.success)
                        }
                    }
                } header: {
                    Text("Pay Yourself First")
                } footer: {
                    Text("This amount will be automatically earmarked for savings when income arrives.")
                }

                Section("Period") {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                        }
                    }
                    Picker("Year", selection: $selectedYear) {
                        ForEach([2024, 2025, 2026], id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                }
            }
            .navigationTitle("Create Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createBudget() }
                        .disabled(income.isEmpty)
                }
            }
        }
    }

    private func createBudget() {
        guard let incomeValue = Double(income.replacingOccurrences(of: ",", with: ".")) else { return }
        _ = viewModel.createBudget(
            month: selectedMonth,
            year: selectedYear,
            income: incomeValue,
            savingsPercent: savingsPercent,
            context: context
        )
        dismiss()
    }
}
