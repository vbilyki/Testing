import SwiftUI
import SwiftData

struct SavingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<SavingsGoalModel> { !$0.isCompleted },
           sort: \SavingsGoalModel.createdAt) private var activeGoals: [SavingsGoalModel]
    @Query(filter: #Predicate<SavingsGoalModel> { $0.isCompleted }) private var completedGoals: [SavingsGoalModel]

    @StateObject private var viewModel = SavingsViewModel()
    @State private var showingCompleted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Total Savings Summary
                    savingsSummaryCard

                    // Active Goals
                    if activeGoals.isEmpty {
                        emptyGoalsCard
                    } else {
                        goalsSection
                    }

                    // Completed Goals
                    if !completedGoals.isEmpty {
                        completedGoalsSection
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Savings Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddGoal) {
                AddGoalView(viewModel: viewModel, context: modelContext)
            }
            .onAppear {
                viewModel.loadStats(goals: activeGoals + completedGoals)
            }
        }
    }

    // MARK: - Summary Card
    private var savingsSummaryCard: some View {
        CardView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Saved")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(viewModel.totalSaved.currencyFormatted)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppTheme.savingsGradient)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.1))
                            .frame(width: 56, height: 56)
                        Image(systemName: "banknote.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.gradient)
                    }
                }

                if viewModel.totalTarget > 0 {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Overall Progress")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            let progress = viewModel.totalSaved / viewModel.totalTarget
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        BudgetProgressBar(
                            progress: viewModel.totalTarget > 0 ? viewModel.totalSaved / viewModel.totalTarget : 0,
                            color: AppTheme.primary,
                            height: 10
                        )
                        HStack {
                            Text("\(activeGoals.count) active goal\(activeGoals.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("Target: \(viewModel.totalTarget.currencyFormatted)")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Active Goals")
            ForEach(viewModel.sortedGoals(activeGoals)) { goal in
                GoalCard(goal: goal, viewModel: viewModel, context: modelContext)
            }
        }
    }

    private var completedGoalsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Completed",
                action: { showingCompleted.toggle() },
                actionLabel: showingCompleted ? "Hide" : "Show"
            )
            if showingCompleted {
                ForEach(completedGoals) { goal in
                    GoalCard(goal: goal, viewModel: viewModel, context: modelContext, isCompleted: true)
                }
            }
        }
    }

    private var emptyGoalsCard: some View {
        CardView {
            VStack(spacing: 16) {
                Text("🎯")
                    .font(.system(size: 48))
                Text("No savings goals yet")
                    .font(.headline)
                Text("Create your first goal to start building your future")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    viewModel.showingAddGoal = true
                } label: {
                    Label("Add First Goal", systemImage: "plus")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.gradient)
                        .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(30)
        }
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let goal: SavingsGoalModel
    @ObservedObject var viewModel: SavingsViewModel
    let context: ModelContext
    var isCompleted: Bool = false

    @State private var showingContribute = false
    @State private var contribution = ""

    var body: some View {
        CardView {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? AppTheme.success.opacity(0.15) : AppTheme.primary.opacity(0.1))
                            .frame(width: 50, height: 50)
                        Text(goal.emoji)
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(goal.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.success)
                                    .font(.caption)
                            }
                        }
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: goal.priority.color))
                                .frame(width: 6, height: 6)
                            Text(goal.priority.rawValue)
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                            if let deadline = goal.deadline {
                                Text("·")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("Due \(DateFormatter.shortDate.string(from: deadline))")
                                    .font(.caption2)
                                    .foregroundColor(goal.isOnTrack ? AppTheme.textSecondary : AppTheme.danger)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(goal.progress * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(isCompleted ? AnyShapeStyle(AppTheme.success) : AnyShapeStyle(AppTheme.savingsGradient))
                        Text(goal.currentAmount.currencyFormatted)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                BudgetProgressBar(
                    progress: goal.progress,
                    color: isCompleted ? AppTheme.success : AppTheme.primary,
                    height: 8
                )

                HStack {
                    VStack(alignment: .leading) {
                        Text("Saved")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(goal.currentAmount.currencyFormatted)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    VStack {
                        Text("Target")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(goal.targetAmount.currencyFormatted)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    if let months = goal.monthsToGoal {
                        VStack(alignment: .trailing) {
                            Text("ETA")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(months)mo")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(goal.isOnTrack ? AppTheme.success : AppTheme.warning)
                        }
                    }
                }

                if !isCompleted {
                    Button {
                        showingContribute = true
                    } label: {
                        Label("Add Contribution", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.gradient)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(16)
        }
        .alert("Add Contribution to \(goal.name)", isPresented: $showingContribute) {
            TextField("Amount (₴)", text: $contribution)
                .keyboardType(.decimalPad)
            Button("Add") {
                if let amount = Double(contribution.replacingOccurrences(of: ",", with: ".")) {
                    viewModel.addContribution(goal: goal, amount: amount, context: context)
                    contribution = ""
                    viewModel.loadStats(goals: [goal])
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteGoal(goal, context: context)
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Goal View
struct AddGoalView: View {
    @ObservedObject var viewModel: SavingsViewModel
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "🎯"
    @State private var targetAmount = ""
    @State private var monthlyContribution = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var priority: GoalPriority = .medium

    private let emojiOptions = ["🎯", "🏠", "✈️", "🚗", "💍", "📱", "💻", "🎓", "👶", "🏖️", "💪", "🌍"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal name (e.g., Emergency Fund)", text: $name)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button {
                                    emoji = e
                                } label: {
                                    Text(e)
                                        .font(.title)
                                        .padding(6)
                                        .background(emoji == e ? AppTheme.primary.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                Section("Amounts") {
                    HStack {
                        Text("Target ₴")
                        TextField("0", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Monthly ₴")
                        TextField("0 (monthly contribution)", text: $monthlyContribution)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    if let target = Double(targetAmount), let monthly = Double(monthlyContribution), monthly > 0 {
                        let months = Int(ceil(target / monthly))
                        Label("Goal in \(months) months", systemImage: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(AppTheme.success)
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(GoalPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Deadline") {
                    Toggle("Set deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Savings Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addGoal() }
                        .disabled(name.isEmpty || targetAmount.isEmpty)
                }
            }
        }
    }

    private func addGoal() {
        guard let target = Double(targetAmount.replacingOccurrences(of: ",", with: ".")),
              !name.isEmpty else { return }
        let monthly = Double(monthlyContribution.replacingOccurrences(of: ",", with: ".")) ?? 0
        viewModel.addGoal(
            name: name,
            emoji: emoji,
            targetAmount: target,
            monthlyContribution: monthly,
            deadline: hasDeadline ? deadline : nil,
            priority: priority,
            context: context
        )
        dismiss()
    }
}
