//
//  DependencyContainer.swift
//  BettorOdds
//
//  Version: 3.0.0 - Clean, focused dependency injection for your needs
//  Created: June 2025
//  Add this file to: Utilities/
//

import Foundation

// MARK: - Dependency Container Protocol
protocol DependencyContainerProtocol {
    func register<T>(_ type: T.Type, instance: T)
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T
    func reset() // For testing
}

// MARK: - Main Dependency Container
class DependencyContainer: DependencyContainerProtocol {
    static let shared = DependencyContainer()
    
    // Storage for instances and factories
    private var instances: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private let queue = DispatchQueue(label: "dependency.container", attributes: .concurrent)
    
    private init() {
        registerDefaultServices()
        print("🔧 DependencyContainer initialized")
    }
    
    /// Register a singleton instance
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.instances[key] = instance
            print("📦 Registered singleton: \(key)")
        }
    }
    
    /// Register a factory function (creates new instance each time)
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        queue.async(flags: .barrier) {
            self.factories[key] = factory
            print("🏭 Registered factory: \(key)")
        }
    }
    
    /// Resolve a dependency
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        return queue.sync {
            // First check for existing instance
            if let instance = instances[key] as? T {
                return instance
            }
            
            // Then check for factory
            if let factory = factories[key] {
                let instance = factory() as! T
                // Store singleton instances
                instances[key] = instance
                return instance
            }
            
            fatalError("❌ Service \(key) not registered in DependencyContainer")
        }
    }
    
    /// Reset for testing
    func reset() {
        queue.async(flags: .barrier) {
            self.instances.removeAll()
            self.factories.removeAll()
            self.registerDefaultServices()
            print("🧹 DependencyContainer reset")
        }
    }
    
    /// Register all your default services here
    private func registerDefaultServices() {
        // Services (Singletons)
        register(OddsService.self, instance: OddsService.shared)
        register(ScoreService.self, instance: ScoreService.shared)
        
        // Repositories (New instances - they should be lightweight)
        register(GameRepository.self, factory: { GameRepository() })
        register(UserRepository.self, factory: { UserRepository() })
        register(BetRepository.self, factory: { BetRepository() })
        register(TransactionRepository.self, factory: { TransactionRepository() })
        
        // Note: ViewModels with @MainActor and special parameters are created directly
        // where they're needed, not through the DI container
        
        print("✅ Default services registered")
    }
}

// MARK: - Property Wrapper for Easy Injection
@propertyWrapper
struct Inject<T> {
    private let container: DependencyContainerProtocol
    
    var wrappedValue: T {
        container.resolve(T.self)
    }
    
    init(container: DependencyContainerProtocol = DependencyContainer.shared) {
        self.container = container
    }
}

// MARK: - Testing Support
#if DEBUG
class MockDependencyContainer: DependencyContainerProtocol {
    private var mocks: [String: Any] = [:]
    
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        mocks[key] = instance
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        mocks[key] = factory()
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let mock = mocks[key] as? T else {
            fatalError("Mock for \(key) not registered")
        }
        return mock
    }
    
    func reset() {
        mocks.removeAll()
    }
}
#endif

// MARK: - Usage Examples and Migration Guide
/*
// BEFORE (in your ViewModels):
class GamesViewModel: ListViewModel<Game> {
    private let gameRepository = GameRepository()
    private let oddsService = OddsService.shared
    private let scoreService = ScoreService.shared
}

// AFTER (with DI):
class GamesViewModel: ListViewModel<Game> {
    @Inject private var gameRepository: GameRepository
    @Inject private var oddsService: OddsService
    @Inject private var scoreService: ScoreService
    
    // Everything else stays the same!
}

// For ViewModels with parameters (like BetModalViewModel), create them normally:
let betModal = BetModalViewModel(game: selectedGame, user: currentUser)

// For testing, you can override services:
func testSetup() {
    DependencyContainer.shared.register(OddsService.self, instance: MockOddsService())
    DependencyContainer.shared.register(GameRepository.self, instance: MockGameRepository())
}
*/
