import SwiftUI

@main
struct Week9VehicleRentalManagementSystemApp: App {
    @StateObject private var store = RentalStore()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store).tint(.indigo)
        }
    }
}
