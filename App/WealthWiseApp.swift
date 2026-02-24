import SwiftUI
import SwiftData

@main
struct WealthWiseApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                TransactionModel.self,
                BudgetModel.self,
                CategoryModel.self,
                SavingsGoalModel.self,
                MonobankAccountModel.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
