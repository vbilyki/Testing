import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "house.fill"
        case budget = "chart.pie.fill"
        case transactions = "list.bullet.rectangle"
        case savings = "banknote.fill"
        case insights = "brain.head.profile"

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .budget: return "Budget"
            case .transactions: return "Transactions"
            case .savings: return "Savings"
            case .insights: return "AI Insights"
            }
        }
    }

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(isCompleted: $hasCompletedOnboarding)
        } else {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label(Tab.dashboard.title, systemImage: Tab.dashboard.rawValue)
                    }
                    .tag(Tab.dashboard)

                BudgetView()
                    .tabItem {
                        Label(Tab.budget.title, systemImage: Tab.budget.rawValue)
                    }
                    .tag(Tab.budget)

                TransactionsView()
                    .tabItem {
                        Label(Tab.transactions.title, systemImage: Tab.transactions.rawValue)
                    }
                    .tag(Tab.transactions)

                SavingsView()
                    .tabItem {
                        Label(Tab.savings.title, systemImage: Tab.savings.rawValue)
                    }
                    .tag(Tab.savings)

                AIInsightsView()
                    .tabItem {
                        Label(Tab.insights.title, systemImage: Tab.insights.rawValue)
                    }
                    .tag(Tab.insights)
            }
            .accentColor(AppTheme.primary)
        }
    }
}
