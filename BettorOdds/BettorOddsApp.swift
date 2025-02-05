import SwiftUI
import FirebaseCore

@main
struct BettorOddsApp: App {
    @State private var showLaunch = true
    
    init() {
        // Keep existing Firebase initialization
        FirebaseConfig.shared
        
        #if DEBUG
        print("📝 Debug mode enabled")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                if showLaunch {
                    LaunchScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showLaunch = false
                    }
                }
            }
        }
    }
}
