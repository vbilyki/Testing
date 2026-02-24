import Foundation
import SwiftData

@MainActor
final class SavingsViewModel: ObservableObject {
    @Published var showingAddGoal = false
    @Published var editingGoal: SavingsGoalModel?
    @Published var totalSaved: Double = 0
    @Published var totalTarget: Double = 0

    func loadStats(goals: [SavingsGoalModel]) {
        totalSaved = goals.reduce(0) { $0 + $1.currentAmount }
        totalTarget = goals.reduce(0) { $0 + $1.targetAmount }
    }

    func addGoal(
        name: String,
        emoji: String,
        targetAmount: Double,
        monthlyContribution: Double,
        deadline: Date?,
        priority: GoalPriority,
        context: ModelContext
    ) {
        let goal = SavingsGoalModel(
            name: name,
            emoji: emoji,
            targetAmount: targetAmount,
            monthlyContribution: monthlyContribution,
            deadline: deadline,
            priority: priority
        )
        context.insert(goal)
        try? context.save()
    }

    func addContribution(goal: SavingsGoalModel, amount: Double, context: ModelContext) {
        goal.currentAmount += amount
        if goal.currentAmount >= goal.targetAmount {
            goal.isCompleted = true
        }
        try? context.save()
    }

    func deleteGoal(_ goal: SavingsGoalModel, context: ModelContext) {
        context.delete(goal)
        try? context.save()
    }

    func sortedGoals(_ goals: [SavingsGoalModel]) -> [SavingsGoalModel] {
        goals.sorted { g1, g2 in
            // High priority first, then by completion
            if g1.priority.rawValue != g2.priority.rawValue {
                return g1.priority.rawValue < g2.priority.rawValue
            }
            return g1.progress > g2.progress
        }
    }
}
