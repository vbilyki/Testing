import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionModel.date, order: .reverse) private var allTransactions: [TransactionModel]
    @Query private var budgets: [BudgetModel]

    @StateObject private var viewModel = TransactionViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar

                // Transaction List
                if filteredTransactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transactions")
            .searchable(text: $viewModel.searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTransaction) {
                AddTransactionView(budget: currentBudget, context: modelContext)
            }
            .sheet(item: $viewModel.selectedTransaction) { tx in
                TransactionDetailView(transaction: tx, budget: currentBudget, context: modelContext)
            }
        }
    }

    private var currentBudget: BudgetModel? {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return budgets.first { $0.month == month && $0.year == year }
    }

    private var filteredTransactions: [TransactionModel] {
        viewModel.filteredTransactions(allTransactions)
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            // Period picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionViewModel.TimePeriod.allCases, id: \.self) { period in
                        Button {
                            viewModel.selectedPeriod = period
                        } label: {
                            Text(period.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedPeriod == period ? AppTheme.primary : Color(.systemGray5))
                                .foregroundColor(viewModel.selectedPeriod == period ? .white : AppTheme.textSecondary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Type filter
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(TransactionViewModel.TransactionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                let grouped = viewModel.groupByDate(filteredTransactions)
                ForEach(grouped, id: \.0) { (date, txs) in
                    Section {
                        VStack(spacing: 8) {
                            ForEach(txs) { tx in
                                TransactionRowView(transaction: tx)
                                    .padding(.horizontal, 16)
                                    .onTapGesture {
                                        viewModel.selectedTransaction = tx
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        HStack {
                            Text(DateFormatter.shortDate.string(from: date))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            let dayTotal = txs.filter { !$0.isIncome }.reduce(0.0) { $0 + $1.absoluteAmount }
                            Text("-\(dayTotal.currencyFormatted)")
                                .font(.caption)
                                .foregroundColor(AppTheme.danger)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textSecondary)
            Text("No transactions found")
                .font(.headline)
            Text("Try a different filter or add transactions manually")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Add Transaction View
struct AddTransactionView: View {
    let budget: BudgetModel?
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var description = ""
    @State private var isIncome = false
    @State private var selectedCategory = BudgetCategoryItem.defaultCategories().first!
    @State private var date = Date()

    private var categories: [BudgetCategoryItem] {
        budget?.categories ?? BudgetCategoryItem.defaultCategories()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("₴")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    Toggle("This is income", isOn: $isIncome)
                }

                Section("Details") {
                    TextField("Description", text: $description)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                if !isIncome {
                    Section("Category") {
                        Picker("Category", selection: $selectedCategory.id) {
                            ForEach(categories) { cat in
                                Label(cat.name, systemImage: "circle.fill")
                                    .tag(cat.id)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(amount.isEmpty || description.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }

        let viewModel = TransactionViewModel()
        viewModel.addManualTransaction(
            amount: amountValue,
            description: description,
            isIncome: isIncome,
            categoryName: selectedCategory.name,
            categoryEmoji: selectedCategory.emoji,
            date: date,
            budgetCategoryID: isIncome ? nil : selectedCategory.id,
            context: context
        )
        dismiss()
    }
}

// MARK: - Transaction Detail View
struct TransactionDetailView: View {
    let transaction: TransactionModel
    let budget: BudgetModel?
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(transaction.categoryEmoji).font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(transaction.transactionDescription).font(.headline)
                            Text(transaction.categoryName).font(.caption).foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        AmountText(amount: transaction.absoluteAmount, isIncome: transaction.isIncome, fontSize: 20)
                    }
                }

                Section("Details") {
                    LabeledContent("Date", value: DateFormatter.shortDate.string(from: transaction.date))
                    LabeledContent("Source", value: transaction.source == .monobank ? "Monobank" : "Manual")
                    if let mcc = transaction.categoryMCC {
                        LabeledContent("MCC", value: String(mcc))
                    }
                    if let comment = transaction.comment {
                        LabeledContent("Comment", value: comment)
                    }
                }
            }
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if transaction.isManual {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            context.delete(transaction)
                            try? context.save()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
