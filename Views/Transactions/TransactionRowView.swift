import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionModel

    var body: some View {
        CardView {
            HStack(spacing: 12) {
                // Category emoji circle
                ZStack {
                    Circle()
                        .fill(transaction.isIncome ? AppTheme.success.opacity(0.15) : AppTheme.danger.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Text(transaction.categoryEmoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.transactionDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(transaction.categoryName)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("·")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(DateFormatter.shortDate.string(from: transaction.date))
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        if transaction.source == .monobank {
                            Image(systemName: "creditcard.fill")
                                .font(.caption2)
                                .foregroundColor(AppTheme.primary.opacity(0.7))
                        }
                    }
                }

                Spacer()

                AmountText(amount: transaction.absoluteAmount, isIncome: transaction.isIncome)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}
