import SwiftUI
import FirebaseCore

@main
struct BettorOddsApp: App {
    init() {
        // Initialize Firebase configuration
        FirebaseConfig.shared
        
        #if DEBUG
        print("📝 Debug mode enabled")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
