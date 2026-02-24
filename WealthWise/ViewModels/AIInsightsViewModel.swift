import Foundation
import SwiftData

@MainActor
final class AIInsightsViewModel: ObservableObject {
    @Published var insights: AIInsightResponse?
    @Published var spendingAnalysis: SpendingAnalysis?
    @Published var savingsRecommendation: SavingsRecommendation?
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?

    private let aiService = AIService.shared

    func generateInsights(
        budget: BudgetModel?,
        transactions: [TransactionModel],
        savingsGoals: [SavingsGoalModel]
    ) async {
        guard let budget = budget else {
            error = "No budget found for this month. Create a budget first."
            return
        }

        isLoading = true
        error = nil

        do {
            async let insightsTask = aiService.generateBudgetInsights(
                budget: budget,
                transactions: transactions,
                savingsGoals: savingsGoals
            )
            async let analysisTask = aiService.analyzeSpendingPatterns(transactions: transactions)

            let (insightsResult, analysisResult) = try await (insightsTask, analysisTask)

            insights = insightsResult
            spendingAnalysis = analysisResult
            lastUpdated = Date()

        } catch AIServiceError.noAPIKey {
            error = "Please add your Anthropic API key in Settings to use AI Insights."
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func generateSavingsRecommendation(
        budget: BudgetModel?,
        transactions: [TransactionModel],
        goals: [SavingsGoalModel]
    ) async {
        guard let budget = budget else { return }

        isLoading = true
        error = nil

        let expensesByCategory = Dictionary(
            grouping: transactions.filter { !$0.isIncome },
            by: { $0.categoryName }
        ).mapValues { $0.reduce(0.0) { $0 + $1.absoluteAmount * 100 } }

        let currentSavingsRate = budget.totalIncome > 0
            ? budget.savingsTarget / budget.totalIncome
            : 0

        do {
            savingsRecommendation = try await aiService.getSavingsRecommendation(
                income: budget.totalIncome,
                expenses: expensesByCategory,
                currentSavingsRate: currentSavingsRate,
                goals: goals
            )
        } catch AIServiceError.noAPIKey {
            error = "Please add your Anthropic API key in Settings to use AI Insights."
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    var healthScoreColor: String {
        guard let score = insights?.overallScore else { return "#9E9E9E" }
        if score >= 80 { return "#4CAF50" }
        if score >= 60 { return "#FF9800" }
        return "#F44336"
    }
}
