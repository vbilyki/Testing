import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "💰",
            title: "Pay Yourself First",
            description: "The #1 rule of personal finance: save before you spend. WealthWise automatically sets aside your savings the moment income arrives.",
            gradient: LinearGradient(colors: [Color(hex: "#6C63FF"), Color(hex: "#9C27B0")], startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        OnboardingPage(
            emoji: "📊",
            title: "Smart Budget Planning",
            description: "Plan your monthly budget by category. WealthWise uses the proven 50/30/20 rule to suggest how to allocate your money.",
            gradient: LinearGradient(colors: [Color(hex: "#00BCD4"), Color(hex: "#2196F3")], startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        OnboardingPage(
            emoji: "🏦",
            title: "Monobank Auto-Sync",
            description: "Connect your Monobank account and transactions are automatically imported, categorized, and tracked against your budget.",
            gradient: LinearGradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#00BCD4")], startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        OnboardingPage(
            emoji: "🧠",
            title: "AI Financial Coach",
            description: "Claude AI analyzes your spending patterns and provides personalized tips to optimize your budget and accelerate savings.",
            gradient: LinearGradient(colors: [Color(hex: "#FF9800"), Color(hex: "#F44336")], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    ]

    var body: some View {
        ZStack {
            pages[currentPage].gradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                Spacer()

                // Content
                VStack(spacing: 24) {
                    Text(pages[currentPage].emoji)
                        .font(.system(size: 80))
                        .shadow(radius: 10)

                    VStack(spacing: 12) {
                        Text(pages[currentPage].title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(pages[currentPage].description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentPage)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                Spacer()

                // Navigation
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == currentPage ? 10 : 6, height: index == currentPage ? 10 : 6)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button {
                                currentPage -= 1
                            } label: {
                                Text("Back")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 100)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(14)
                            }
                        }

                        Button {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                isCompleted = true
                            }
                        } label: {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#6C63FF"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 32)

                    if currentPage < pages.count - 1 {
                        Button {
                            isCompleted = true
                        } label: {
                            Text("Skip")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let emoji: String
    let title: String
    let description: String
    let gradient: LinearGradient
}
