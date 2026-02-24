import SwiftUI

// MARK: - Reusable Card
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Progress Bar
struct BudgetProgressBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(progress > 1.0 ? AppTheme.danger : color)
                    .frame(width: min(geo.size.width * CGFloat(progress), geo.size.width), height: height)
                    .animation(.spring(response: 0.6), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Health Score Ring
struct HealthScoreRing: View {
    let score: Int
    var size: CGFloat = 80

    private var color: Color {
        if score >= 80 { return AppTheme.success }
        if score >= 60 { return AppTheme.warning }
        return AppTheme.danger
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0), value: score)

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundColor(color)
                Text("score")
                    .font(.system(size: size * 0.14))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Emoji Category Badge
struct CategoryBadge: View {
    let emoji: String
    let name: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 14))
            Text(name)
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

// MARK: - Amount Display
struct AmountText: View {
    let amount: Double
    let isIncome: Bool
    var fontSize: CGFloat = 17

    var body: some View {
        Text(isIncome ? "+\(amount.currencyFormatted)" : "-\(amount.currencyFormatted)")
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(isIncome ? AppTheme.success : AppTheme.danger)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            if let action = action {
                Button(actionLabel, action: action)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primary)
            }
        }
    }
}
