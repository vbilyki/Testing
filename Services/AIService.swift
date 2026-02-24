import Foundation

// MARK: - Claude AI Service for Budget Insights
final class AIService: ObservableObject {
    static let shared = AIService()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-opus-4-5"
    private let apiVersion = "2023-06-01"

    @Published var isLoading = false
    @Published var lastError: String?

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "anthropic_api_key")
    }

    private init() {}

    // MARK: - Generate Budget Insights
    func generateBudgetInsights(
        budget: BudgetModel,
        transactions: [TransactionModel],
        savingsGoals: [SavingsGoalModel]
    ) async throws -> AIInsightResponse {
        guard !apiKey.isEmpty else {
            throw AIServiceError.noAPIKey
        }

        isLoading = true
        defer { Task { @MainActor in self.isLoading = false } }

        let prompt = buildBudgetInsightPrompt(
            budget: budget,
            transactions: transactions,
            savingsGoals: savingsGoals
        )

        let request = ClaudeRequest(
            model: model,
            maxTokens: 1500,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ]
        )

        return try await callClaude(request: request, responseType: AIInsightResponse.self)
    }

    // MARK: - Analyze Spending Pattern
    func analyzeSpendingPatterns(transactions: [TransactionModel]) async throws -> SpendingAnalysis {
        guard !apiKey.isEmpty else { throw AIServiceError.noAPIKey }

        isLoading = true
        defer { Task { @MainActor in self.isLoading = false } }

        let prompt = buildSpendingAnalysisPrompt(transactions: transactions)

        let request = ClaudeRequest(
            model: model,
            maxTokens: 1200,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ]
        )

        return try await callClaude(request: request, responseType: SpendingAnalysis.self)
    }

    // MARK: - Get Savings Recommendation
    func getSavingsRecommendation(
        income: Double,
        expenses: [String: Double],
        currentSavingsRate: Double,
        goals: [SavingsGoalModel]
    ) async throws -> SavingsRecommendation {
        guard !apiKey.isEmpty else { throw AIServiceError.noAPIKey }

        isLoading = true
        defer { Task { @MainActor in self.isLoading = false } }

        let prompt = buildSavingsRecommendationPrompt(
            income: income,
            expenses: expenses,
            currentSavingsRate: currentSavingsRate,
            goals: goals
        )

        let request = ClaudeRequest(
            model: model,
            maxTokens: 1000,
            messages: [
                ClaudeMessage(role: "user", content: prompt)
            ]
        )

        return try await callClaude(request: request, responseType: SavingsRecommendation.self)
    }

    // MARK: - Generic Claude API Call
    private func callClaude<T: Decodable>(
        request: ClaudeRequest,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw AIServiceError.invalidAPIKey
            }
            throw AIServiceError.serverError(httpResponse.statusCode)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let content = claudeResponse.content.first?.text else {
            throw AIServiceError.emptyResponse
        }

        // Extract JSON from response (Claude may wrap it in markdown)
        let jsonString = extractJSON(from: content)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.parseError
        }

        return try JSONDecoder().decode(T.self, from: jsonData)
    }

    private func extractJSON(from text: String) -> String {
        // Strip markdown code blocks if present
        if let start = text.range(of: "```json\n"),
           let end = text.range(of: "\n```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound])
        }
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }

    // MARK: - Prompt Builders
    private func buildBudgetInsightPrompt(
        budget: BudgetModel,
        transactions: [TransactionModel],
        savingsGoals: [SavingsGoalModel]
    ) -> String {
        let categorySpending = Dictionary(grouping: transactions.filter { !$0.isIncome }) { $0.categoryName }
            .mapValues { $0.reduce(0.0) { $0 + $1.absoluteAmount } }

        let savingsRate = budget.totalIncome > 0 ? (budget.savingsTarget / budget.totalIncome * 100) : 0

        var prompt = """
        You are a personal finance AI advisor. Analyze this user's budget data and provide actionable insights.

        Monthly Budget for \(budget.displayName):
        - Total Income: ₴\(String(format: "%.2f", budget.totalIncome / 100))
        - Savings Target (Pay Yourself First): ₴\(String(format: "%.2f", budget.savingsTarget / 100)) (\(String(format: "%.1f", savingsRate))%)
        - Spendable Income: ₴\(String(format: "%.2f", budget.spendableIncome / 100))

        Category Spending:
        """

        for (category, amount) in categorySpending.sorted(by: { $0.value > $1.value }) {
            prompt += "\n- \(category): ₴\(String(format: "%.2f", amount))"
        }

        prompt += "\n\nBudget Categories and Allocations:"
        for cat in budget.categories {
            let status = cat.isOverBudget ? " ⚠️ OVER BUDGET" : ""
            prompt += "\n- \(cat.name): Allocated ₴\(String(format: "%.2f", cat.allocatedAmount / 100)), Spent ₴\(String(format: "%.2f", cat.spentAmount / 100))\(status)"
        }

        if !savingsGoals.isEmpty {
            prompt += "\n\nSavings Goals:"
            for goal in savingsGoals.prefix(5) {
                prompt += "\n- \(goal.name): \(Int(goal.progress * 100))% complete (₴\(String(format: "%.2f", goal.currentAmount))/₴\(String(format: "%.2f", goal.targetAmount)))"
            }
        }

        prompt += """

        Respond with a JSON object in this exact format:
        {
          "overallScore": 75,
          "summary": "Brief 2-sentence summary of financial health",
          "topInsights": [
            {"title": "Insight title", "description": "Detailed description", "type": "warning|success|tip", "impact": "high|medium|low"},
            {"title": "Insight title", "description": "Detailed description", "type": "warning|success|tip", "impact": "high|medium|low"},
            {"title": "Insight title", "description": "Detailed description", "type": "warning|success|tip", "impact": "high|medium|low"}
          ],
          "actionItems": [
            "Specific action the user should take",
            "Another specific action",
            "Third action"
          ],
          "savingsAdvice": "Specific advice about savings strategy"
        }
        """

        return prompt
    }

    private func buildSpendingAnalysisPrompt(transactions: [TransactionModel]) -> String {
        let recentExpenses = transactions
            .filter { !$0.isIncome }
            .sorted { $0.date > $1.date }
            .prefix(30)

        var prompt = "Analyze these recent transactions for spending patterns:\n\n"
        for tx in recentExpenses {
            let dateStr = DateFormatter.shortDate.string(from: tx.date)
            prompt += "- \(dateStr): \(tx.transactionDescription) | \(tx.categoryName) | ₴\(String(format: "%.2f", tx.absoluteAmount))\n"
        }

        prompt += """

        Respond with JSON:
        {
          "patterns": [
            {"pattern": "Pattern description", "frequency": "daily|weekly|monthly", "suggestion": "How to optimize"}
          ],
          "unusualSpending": ["Description of unusual transactions"],
          "topExpenseCategory": "Category name",
          "optimizationTip": "Single most impactful optimization"
        }
        """
        return prompt
    }

    private func buildSavingsRecommendationPrompt(
        income: Double,
        expenses: [String: Double],
        currentSavingsRate: Double,
        goals: [SavingsGoalModel]
    ) -> String {
        var prompt = """
        Income: ₴\(String(format: "%.2f", income / 100))
        Current savings rate: \(String(format: "%.1f", currentSavingsRate * 100))%

        Expenses by category:
        """

        for (category, amount) in expenses.sorted(by: { $0.value > $1.value }) {
            let percent = income > 0 ? (amount / income * 100) : 0
            prompt += "\n- \(category): ₴\(String(format: "%.2f", amount / 100)) (\(String(format: "%.1f", percent))%)"
        }

        if !goals.isEmpty {
            prompt += "\n\nSavings goals:"
            for goal in goals {
                prompt += "\n- \(goal.name): Need ₴\(String(format: "%.2f", goal.remainingAmount)) more"
                if let months = goal.monthsToGoal {
                    prompt += " (\(months) months at current rate)"
                }
            }
        }

        prompt += """

        Use Pay Yourself First principle. Respond with JSON:
        {
          "recommendedSavingsRate": 0.20,
          "recommendedMonthlySavings": 5000,
          "reasoning": "Why this rate",
          "categoryReductions": [
            {"category": "Category", "currentAmount": 1000, "suggestedAmount": 800, "saving": 200, "tip": "How to reduce"}
          ],
          "payYourselfFirstTip": "Specific advice on automating savings"
        }
        """
        return prompt
    }
}

// MARK: - Claude API Models
struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case model
        case stopReason = "stop_reason"
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

// MARK: - AI Response Models
struct AIInsightResponse: Codable {
    let overallScore: Int
    let summary: String
    let topInsights: [AIInsight]
    let actionItems: [String]
    let savingsAdvice: String
}

struct AIInsight: Codable, Identifiable {
    var id = UUID().uuidString
    let title: String
    let description: String
    let type: String   // warning | success | tip
    let impact: String // high | medium | low

    enum CodingKeys: String, CodingKey {
        case title, description, type, impact
    }
}

struct SpendingAnalysis: Codable {
    let patterns: [SpendingPattern]
    let unusualSpending: [String]
    let topExpenseCategory: String
    let optimizationTip: String
}

struct SpendingPattern: Codable, Identifiable {
    var id = UUID().uuidString
    let pattern: String
    let frequency: String
    let suggestion: String

    enum CodingKeys: String, CodingKey {
        case pattern, frequency, suggestion
    }
}

struct SavingsRecommendation: Codable {
    let recommendedSavingsRate: Double
    let recommendedMonthlySavings: Double
    let reasoning: String
    let categoryReductions: [CategoryReduction]
    let payYourselfFirstTip: String
}

struct CategoryReduction: Codable, Identifiable {
    var id = UUID().uuidString
    let category: String
    let currentAmount: Double
    let suggestedAmount: Double
    let saving: Double
    let tip: String

    enum CodingKeys: String, CodingKey {
        case category, currentAmount, suggestedAmount, saving, tip
    }
}

// MARK: - AI Service Errors
enum AIServiceError: LocalizedError {
    case noAPIKey
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case emptyResponse
    case parseError
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No AI API key configured. Please add your Anthropic API key in Settings."
        case .invalidAPIKey:
            return "Invalid Anthropic API key."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .emptyResponse:
            return "Empty response from AI service."
        case .parseError:
            return "Could not parse AI response."
        case .serverError(let code):
            return "AI service error: \(code)"
        }
    }
}
