import SwiftUI

@main
struct Midterm_2026_2027App: App {
    @StateObject private var store = RentalStore()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store).tint(.indigo)
        }
    }
}
