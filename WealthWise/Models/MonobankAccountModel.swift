import Foundation
import SwiftData

@Model
final class MonobankAccountModel {
    var id: String
    var accountID: String       // Monobank account ID
    var clientID: String
    var clientName: String
    var cardNumber: String      // masked
    var accountType: String
    var currencyCode: Int
    var cashbackType: String?
    var balance: Double         // in minor units
    var creditLimit: Double
    var isLinked: Bool
    var lastSyncDate: Date?
    var apiToken: String        // stored but should use Keychain in production

    init(
        id: String = UUID().uuidString,
        accountID: String,
        clientID: String = "",
        clientName: String = "",
        cardNumber: String = "",
        accountType: String = "black",
        currencyCode: Int = 980,
        cashbackType: String? = nil,
        balance: Double = 0,
        creditLimit: Double = 0,
        isLinked: Bool = true,
        lastSyncDate: Date? = nil,
        apiToken: String = ""
    ) {
        self.id = id
        self.accountID = accountID
        self.clientID = clientID
        self.clientName = clientName
        self.cardNumber = cardNumber
        self.accountType = accountType
        self.currencyCode = currencyCode
        self.cashbackType = cashbackType
        self.balance = balance
        self.creditLimit = creditLimit
        self.isLinked = isLinked
        self.lastSyncDate = lastSyncDate
        self.apiToken = apiToken
    }

    var balanceFormatted: String {
        let value = balance / 100.0
        return value.currencyFormatted
    }

    var displayName: String {
        let last4 = String(cardNumber.suffix(4))
        return last4.isEmpty ? clientName : "**** \(last4)"
    }
}

// MARK: - Monobank API Response Models

struct MonobankClientInfo: Codable {
    let clientId: String
    let name: String
    let webHookUrl: String?
    let permissions: String
    let accounts: [MonobankAccount]
    let jars: [MonobankJar]?
}

struct MonobankAccount: Codable, Identifiable {
    let id: String
    let sendId: String
    let balance: Int
    let creditLimit: Int
    let type: String
    let currencyCode: Int
    let cashbackType: String?
    let maskedPan: [String]
    let iban: String
}

struct MonobankJar: Codable, Identifiable {
    let id: String
    let sendId: String
    let title: String
    let description: String?
    let currencyCode: Int
    let balance: Int
    let goal: Int?
}

struct MonobankStatement: Codable {
    let id: String
    let time: Int            // Unix timestamp
    let description: String
    let mcc: Int
    let originalMcc: Int
    let hold: Bool
    let amount: Int          // in minor currency units
    let operationAmount: Int
    let currencyCode: Int
    let commissionRate: Int
    let cashbackAmount: Int
    let balance: Int
    let comment: String?
    let receiptId: String?
    let invoiceId: String?
    let counterEdrpou: String?
    let counterIban: String?
    let counterName: String?

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(time))
    }

    var isIncome: Bool {
        amount > 0
    }
}
