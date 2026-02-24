import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [MonobankAccountModel]
    @AppStorage("monobank_token") private var monobankToken = ""
    @AppStorage("anthropic_api_key") private var anthropicKey = ""
    @AppStorage("defaultCurrency") private var currency = "UAH"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    @State private var showingMonobankSetup = false
    @State private var showingAIKeySetup = false
    @State private var isFetchingMonobank = false
    @State private var monobankError: String?
    @State private var monobankSuccess: String?

    var body: some View {
        NavigationStack {
            Form {
                // Monobank Section
                Section {
                    if accounts.isEmpty {
                        Button {
                            showingMonobankSetup = true
                        } label: {
                            HStack {
                                Image(systemName: "link.badge.plus")
                                    .foregroundColor(AppTheme.primary)
                                Text("Connect Monobank")
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    } else {
                        ForEach(accounts) { account in
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(AppTheme.primary)
                                VStack(alignment: .leading) {
                                    Text(account.clientName.isEmpty ? "Monobank Account" : account.clientName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(account.displayName)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                if account.isLinked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.success)
                                }
                            }
                        }

                        if let lastSync = accounts.first?.lastSyncDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("Last sync: \(DateFormatter.shortDate.string(from: lastSync))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        Button(role: .destructive) {
                            disconnectMonobank()
                        } label: {
                            Label("Disconnect Monobank", systemImage: "link.badge.minus")
                        }
                    }
                } header: {
                    Label("Monobank Integration", systemImage: "building.columns.fill")
                } footer: {
                    Text("Connect your Monobank account to automatically sync transactions and track spending in real-time.")
                }

                // AI Section
                Section {
                    if anthropicKey.isEmpty {
                        Button {
                            showingAIKeySetup = true
                        } label: {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(AppTheme.primary)
                                Text("Add Anthropic API Key")
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.success)
                            Text("AI Insights enabled")
                                .font(.subheadline)
                        }
                        Button(role: .destructive) {
                            anthropicKey = ""
                            AIService.shared.setAPIKey("")
                        } label: {
                            Label("Remove API Key", systemImage: "key.slash")
                        }
                    }
                } header: {
                    Label("AI Financial Coach", systemImage: "brain.head.profile")
                } footer: {
                    Text("Get personalized financial advice powered by Claude AI. Your data is sent to Anthropic's servers for analysis.")
                }

                // Preferences
                Section("Preferences") {
                    Toggle("Budget Alerts", isOn: $notificationsEnabled)
                    LabeledContent("Currency", value: "UAH (₴)")
                }

                // Financial Principles
                Section {
                    financialPrincipleRow(
                        title: "Pay Yourself First",
                        description: "Save before spending. Set your savings rate and it's automatically deducted from income.",
                        icon: "dollarsign.circle.fill",
                        color: AppTheme.primary
                    )
                    financialPrincipleRow(
                        title: "50/30/20 Rule",
                        description: "50% needs, 30% wants, 20% savings. WealthWise uses this as the basis for budget suggestions.",
                        icon: "chart.pie.fill",
                        color: AppTheme.secondary
                    )
                    financialPrincipleRow(
                        title: "Zero-Based Budgeting",
                        description: "Every hryvnia has a job. Allocate all income across savings and spending categories.",
                        icon: "equal.circle.fill",
                        color: AppTheme.success
                    )
                } header: {
                    Label("Financial Principles", systemImage: "book.fill")
                }

                // About
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Built with", value: "SwiftUI + Claude AI")
                    Link("Monobank API Docs", destination: URL(string: "https://api.monobank.ua")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingMonobankSetup) {
                MonobankSetupView(onSuccess: { account in
                    modelContext.insert(account)
                    try? modelContext.save()
                    showingMonobankSetup = false
                })
            }
            .sheet(isPresented: $showingAIKeySetup) {
                AIKeySetupView()
            }
        }
    }

    private func disconnectMonobank() {
        for account in accounts {
            modelContext.delete(account)
        }
        try? modelContext.save()
        MonobankService.shared.clearToken()
    }

    private func financialPrincipleRow(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Monobank Setup View
struct MonobankSetupView: View {
    let onSuccess: (MonobankAccountModel) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var token = ""
    @State private var isValidating = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Monobank API Token", text: $token)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("API Token")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to get your token:")
                            .fontWeight(.medium)
                        Text("1. Open Monobank app")
                        Text("2. Go to Settings → Other → API")
                        Text("3. Request an API token")
                        Text("4. Paste it here")
                    }
                    .font(.caption)
                }

                if let error = error {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(AppTheme.danger)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await validateAndConnect() }
                    } label: {
                        HStack {
                            Spacer()
                            if isValidating {
                                ProgressView().tint(.white)
                            } else {
                                Label("Connect Monobank", systemImage: "link")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.primary)
                    .foregroundColor(.white)
                    .disabled(token.isEmpty || isValidating)
                }
            }
            .navigationTitle("Connect Monobank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func validateAndConnect() async {
        isValidating = true
        error = nil

        do {
            let service = MonobankService.shared
            service.setToken(token)
            let info = try await service.fetchClientInfo()

            guard let firstAccount = info.accounts.first else {
                error = "No accounts found in your Monobank profile."
                isValidating = false
                return
            }

            let account = MonobankAccountModel(
                accountID: firstAccount.id,
                clientID: info.clientId,
                clientName: info.name,
                cardNumber: firstAccount.maskedPan.first ?? "",
                accountType: firstAccount.type,
                currencyCode: firstAccount.currencyCode,
                cashbackType: firstAccount.cashbackType,
                balance: Double(firstAccount.balance),
                creditLimit: Double(firstAccount.creditLimit),
                isLinked: true,
                lastSyncDate: Date(),
                apiToken: token
            )

            await MainActor.run {
                onSuccess(account)
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isValidating = false
            }
        }
    }
}

// MARK: - AI Key Setup View
struct AIKeySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("anthropic_api_key") private var anthropicKey = ""
    @State private var key = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-...", text: $key)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text("Get your API key from console.anthropic.com. Your key is stored locally and never shared.")
                        .font(.caption)
                }
            }
            .navigationTitle("AI Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        anthropicKey = key
                        AIService.shared.setAPIKey(key)
                        dismiss()
                    }
                    .disabled(key.isEmpty)
                }
            }
        }
    }
}
