import Foundation
import Combine

// MARK: - Monobank API Service
final class MonobankService: ObservableObject {
    static let shared = MonobankService()

    private let baseURL = "https://api.monobank.ua"
    private var apiToken: String = ""
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 60  // Monobank rate limit: 1 req/min for statements

    @Published var isConnected: Bool = false
    @Published var isSyncing: Bool = false
    @Published var lastSyncError: String?
    @Published var clientInfo: MonobankClientInfo?

    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private init() {
        apiToken = UserDefaults.standard.string(forKey: "monobank_token") ?? ""
        isConnected = !apiToken.isEmpty
    }

    func setToken(_ token: String) {
        apiToken = token
        UserDefaults.standard.set(token, forKey: "monobank_token")
        isConnected = !token.isEmpty
    }

    func clearToken() {
        apiToken = ""
        UserDefaults.standard.removeObject(forKey: "monobank_token")
        isConnected = false
        clientInfo = nil
    }

    // MARK: - Fetch Client Info
    func fetchClientInfo() async throws -> MonobankClientInfo {
        let url = URL(string: "\(baseURL)/personal/client-info")!
        var request = URLRequest(url: url)
        request.addValue(apiToken, forHTTPHeaderField: "X-Token")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MonobankError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let info = try JSONDecoder().decode(MonobankClientInfo.self, from: data)
            await MainActor.run { self.clientInfo = info }
            return info
        case 401:
            throw MonobankError.unauthorized
        case 429:
            throw MonobankError.rateLimited
        default:
            throw MonobankError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Fetch Statement
    func fetchStatement(
        accountID: String,
        from: Date,
        to: Date
    ) async throws -> [MonobankStatement] {
        // Rate limit check
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < minRequestInterval {
            let wait = minRequestInterval - Date().timeIntervalSince(lastRequest)
            throw MonobankError.rateLimitWait(Int(wait))
        }

        let fromTimestamp = Int(from.timeIntervalSince1970)
        let toTimestamp = Int(to.timeIntervalSince1970)

        let urlString = "\(baseURL)/personal/statement/\(accountID)/\(fromTimestamp)/\(toTimestamp)"
        guard let url = URL(string: urlString) else {
            throw MonobankError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue(apiToken, forHTTPHeaderField: "X-Token")

        lastRequestTime = Date()
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MonobankError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([MonobankStatement].self, from: data)
        case 401:
            throw MonobankError.unauthorized
        case 429:
            throw MonobankError.rateLimited
        default:
            throw MonobankError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Sync Current Month
    func syncCurrentMonth(
        accountID: String,
        existingIDs: Set<String>
    ) async throws -> [TransactionModel] {
        await MainActor.run {
            isSyncing = true
            lastSyncError = nil
        }

        defer {
            Task { @MainActor in
                isSyncing = false
            }
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? now

        let statements = try await fetchStatement(
            accountID: accountID,
            from: startOfMonth,
            to: now
        )

        var newTransactions: [TransactionModel] = []

        for statement in statements {
            guard !existingIDs.contains(statement.id) else { continue }

            let categoryInfo = MCCCategoryMapper.category(
                forDescription: statement.description,
                mcc: statement.mcc
            )

            let transaction = TransactionModel(
                id: UUID().uuidString,
                amount: Double(statement.amount),
                currencyCode: statement.currencyCode,
                date: statement.date,
                description: statement.description,
                comment: statement.comment,
                categoryMCC: statement.mcc,
                categoryName: categoryInfo.name,
                categoryEmoji: categoryInfo.emoji,
                isIncome: statement.isIncome,
                source: .monobank,
                monobankID: statement.id,
                isManual: false
            )
            newTransactions.append(transaction)
        }

        return newTransactions
    }

    // MARK: - Validate Token
    func validateToken(_ token: String) async throws -> Bool {
        let savedToken = apiToken
        apiToken = token

        do {
            _ = try await fetchClientInfo()
            return true
        } catch {
            apiToken = savedToken
            throw error
        }
    }
}

// MARK: - Monobank Errors
enum MonobankError: LocalizedError {
    case unauthorized
    case rateLimited
    case rateLimitWait(Int)
    case invalidResponse
    case invalidURL
    case serverError(Int)
    case noToken

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid Monobank token. Please check your API token in Settings."
        case .rateLimited:
            return "Monobank API rate limit reached. Please wait before syncing again."
        case .rateLimitWait(let seconds):
            return "Please wait \(seconds) seconds before syncing again."
        case .invalidResponse:
            return "Received an invalid response from Monobank."
        case .invalidURL:
            return "Invalid request URL."
        case .serverError(let code):
            return "Monobank server error: \(code)"
        case .noToken:
            return "No Monobank token configured. Please add your token in Settings."
        }
    }
}
