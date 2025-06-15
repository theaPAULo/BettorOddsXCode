//
//  DarkModeManager.swift
//  BettorOdds
//
//  Created by Paul Soni on 6/15/25.
//


//  Working Dark Mode Toggle
//  Add this to your SettingsView.swift or create DarkModeManager.swift
//

import SwiftUI

// MARK: - Dark Mode Manager (Create new file: Utilities/DarkModeManager.swift)

class DarkModeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            updateAppearance()
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        updateAppearance()
    }
    
    func updateAppearance() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
            }
        }
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
    }
}