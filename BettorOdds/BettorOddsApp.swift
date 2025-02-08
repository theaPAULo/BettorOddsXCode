import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
}

@main
struct BettorOddsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
