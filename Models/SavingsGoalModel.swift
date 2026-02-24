import Foundation
import SwiftData

@Model
final class SavingsGoalModel {
    var id: String
    var name: String
    var emoji: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var monthlyContribution: Double
    var isCompleted: Bool
    var createdAt: Date
    var priority: GoalPriority
    var notes: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        emoji: String = "🎯",
        targetAmount: Double,
        currentAmount: Double = 0,
        deadline: Date? = nil,
        monthlyContribution: Double = 0,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        priority: GoalPriority = .medium,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.monthlyContribution = monthlyContribution
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.priority = priority
        self.notes = notes
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }

    var monthsToGoal: Int? {
        guard monthlyContribution > 0 else { return nil }
        return Int(ceil(remainingAmount / monthlyContribution))
    }

    var estimatedCompletionDate: Date? {
        guard let months = monthsToGoal else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: Date())
    }

    var isOnTrack: Bool {
        guard let deadline = deadline else { return true }
        guard let estimatedDate = estimatedCompletionDate else { return false }
        return estimatedDate <= deadline
    }
}

enum GoalPriority: String, Codable, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var color: String {
        switch self {
        case .high: return "#F44336"
        case .medium: return "#FF9800"
        case .low: return "#4CAF50"
        }
    }
}
