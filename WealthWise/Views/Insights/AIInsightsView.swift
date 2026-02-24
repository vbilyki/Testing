import SwiftUI
import SwiftData

struct AIInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionModel.date, order: .reverse) private var transactions: [TransactionModel]
    @Query private var budgets: [BudgetModel]
    @Query private var savingsGoals: [SavingsGoalModel]

    @StateObject private var viewModel = AIInsightsViewModel()

    private var currentBudget: BudgetModel? {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        return budgets.first { $0.month == month && $0.year == year }
    }

    private var currentTransactions: [TransactionModel] {
        guard let budget = currentBudget else { return [] }
        let calendar = Calendar.current
        return transactions.filter {
            calendar.component(.month, from: $0.date) == budget.month &&
            calendar.component(.year, from: $0.date) == budget.year
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(message: error)
                    } else if let insights = viewModel.insights {
                        insightsContent(insights: insights)
                    } else {
                        generateView
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.insights != nil {
                        Button {
                            Task {
                                await viewModel.generateInsights(
                                    budget: currentBudget,
                                    transactions: currentTransactions,
                                    savingsGoals: savingsGoals
                                )
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Generate View
    private var generateView: some View {
        VStack(spacing: 24) {
            CardView {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.gradient.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.gradient)
                    }

                    Text("AI Financial Coach")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Get personalized insights on your spending patterns, budget optimization tips, and savings strategies powered by Claude AI.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task {
                            await viewModel.generateInsights(
                                budget: currentBudget,
                                transactions: currentTransactions,
                                savingsGoals: savingsGoals
                            )
                        }
                    } label: {
                        Label("Analyze My Finances", systemImage: "sparkles")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.gradient)
                            .cornerRadius(14)
                    }
                    .disabled(currentBudget == nil || currentTransactions.isEmpty)

                    if currentBudget == nil {
                        Label("Create a budget first to get insights", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundColor(AppTheme.warning)
                    }
                }
                .padding(24)
            }

            // Preview capabilities
            capabilitiesCard
        }
    }

    private var capabilitiesCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("What you'll get:")
                    .font(.headline)

                ForEach([
                    ("chart.bar.fill", "Spending pattern analysis", AppTheme.primary),
                    ("dollarsign.circle.fill", "Pay Yourself First optimization", AppTheme.success),
                    ("exclamationmark.triangle.fill", "Budget overrun alerts", AppTheme.warning),
                    ("arrow.up.right.circle.fill", "Actionable improvement tips", AppTheme.secondary),
                    ("target", "Goal-based savings advice", AppTheme.danger)
                ], id: \.0) { (icon, text, color) in
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .frame(width: 20)
                        Text(text)
                            .font(.subheadline)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        CardView {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppTheme.primary)
                Text("Analyzing your finances...")
                    .font(.headline)
                Text("Claude AI is reviewing your budget and transactions")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
        }
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        CardView {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.warning)
                Text("Could not generate insights")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                if message.contains("API key") {
                    NavigationLink("Go to Settings") {
                        SettingsView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                } else {
                    Button("Try Again") {
                        Task {
                            await viewModel.generateInsights(
                                budget: currentBudget,
                                transactions: currentTransactions,
                                savingsGoals: savingsGoals
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Insights Content
    @ViewBuilder
    private func insightsContent(insights: AIInsightResponse) -> some View {
        // Score Card
        CardView {
            HStack(spacing: 20) {
                HealthScoreRing(score: insights.overallScore, size: 90)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Financial Health")
                        .font(.headline)
                    Text(insights.summary)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
        }

        // Insights
        VStack(spacing: 12) {
            SectionHeader(title: "Key Insights")
            ForEach(insights.topInsights) { insight in
                InsightCard(insight: insight)
            }
        }

        // Action Items
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Action Plan", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(AppTheme.success)
                ForEach(Array(insights.actionItems.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(AppTheme.primary)
                            .clipShape(Circle())
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            .padding(20)
        }

        // Savings Advice
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Label("Savings Strategy", systemImage: "dollarsign.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.gradient)
                Text(insights.savingsAdvice)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                Button {
                    Task {
                        await viewModel.generateSavingsRecommendation(
                            budget: currentBudget,
                            transactions: currentTransactions,
                            goals: savingsGoals
                        )
                    }
                } label: {
                    Label("Get Detailed Savings Plan", systemImage: "sparkles")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(20)
        }

        // Spending Patterns
        if let analysis = viewModel.spendingAnalysis {
            spendingPatternsCard(analysis: analysis)
        }

        // Savings Recommendation
        if let recommendation = viewModel.savingsRecommendation {
            savingsRecommendationCard(recommendation: recommendation)
        }

        // Last updated
        if let updated = viewModel.lastUpdated {
            Text("Updated \(DateFormatter.shortDate.string(from: updated))")
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func spendingPatternsCard(analysis: SpendingAnalysis) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Label("Spending Patterns", systemImage: "chart.xyaxis.line")
                    .font(.headline)

                ForEach(analysis.patterns.prefix(3)) { pattern in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            Text(pattern.pattern)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(pattern.suggestion)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(pattern.frequency.capitalized)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.7))
                            .cornerRadius(4)
                    }
                    if analysis.patterns.prefix(3).last?.id != pattern.id {
                        Divider()
                    }
                }

                if !analysis.unusualSpending.isEmpty {
                    Divider()
                    Label("Unusual Spending Detected", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.warning)
                    ForEach(analysis.unusualSpending, id: \.self) { item in
                        Text("• \(item)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(20)
        }
    }

    private func savingsRecommendationCard(recommendation: SavingsRecommendation) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Label("Optimized Savings Plan", systemImage: "arrow.up.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.savingsGradient)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Recommended Rate")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(Int(recommendation.recommendedSavingsRate * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.gradient)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Monthly Savings")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(recommendation.recommendedMonthlySavings.currencyFormatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.savingsGradient)
                    }
                }

                Text(recommendation.reasoning)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                if !recommendation.categoryReductions.isEmpty {
                    Divider()
                    Text("Suggested Category Cuts:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ForEach(recommendation.categoryReductions.prefix(3)) { reduction in
                        HStack {
                            Text(reduction.category)
                                .font(.subheadline)
                            Spacer()
                            Text("Save \(reduction.saving.currencyFormatted)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.success)
                        }
                        Text(reduction.tip)
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Divider()
                Label(recommendation.payYourselfFirstTip, systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundColor(AppTheme.primary)
            }
            .padding(20)
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: AIInsight

    private var icon: String {
        switch insight.type {
        case "warning": return "exclamationmark.triangle.fill"
        case "success": return "checkmark.circle.fill"
        default: return "lightbulb.fill"
        }
    }

    private var color: Color {
        switch insight.type {
        case "warning": return AppTheme.warning
        case "success": return AppTheme.success
        default: return AppTheme.primary
        }
    }

    private var impactBadgeColor: Color {
        switch insight.impact {
        case "high": return AppTheme.danger
        case "medium": return AppTheme.warning
        default: return AppTheme.success
        }
    }

    var body: some View {
        CardView {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(insight.impact.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(impactBadgeColor)
                            .cornerRadius(4)
                    }
                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
        }
    }
}
