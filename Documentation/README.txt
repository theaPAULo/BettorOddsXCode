# BettorOdds Mobile App

## Overview
BettorOdds is a sports betting platform focused on responsible gambling and user experience. The app features a dual-currency system, daily betting limits, and real-time odds updates.

## Current Version
- **Version**: 1.0.0
- **Last Updated**: February 2025
- **Status**: Development

## Technical Stack

### Frontend
- SwiftUI for iOS native development
- Custom UI components with modern design patterns
- Real-time data updates and animations

### Backend
- **Firebase**
  - Authentication (Email/Password + Phone verification)
  - Firestore Database
  - Cloud Functions
  - Storage
  - Remote Notifications
- **The Odds API** for sports data and live scores

### Development Environment
- Xcode 15+
- iOS 15.0+ deployment target
- Firebase iOS SDK (managed via Swift Package Manager)
- SwiftUI 4.0

## Core Features

### Authentication System
- Email/password registration and login
- Phone number verification support
- Biometric authentication (Face ID/Touch ID)
- Secure session management
- Keychain credential storage

### Dual Currency System

**Yellow Coins (Practice)**
- Starting balance: 100 coins
- No real value
- Unlimited daily usage
- Training and practice purpose

**Green Coins (Real Money)**
- 1:1 USD ratio
- $100 daily limit
- Biometric authentication required
- Full transaction history
- Secure payment processing

### Betting Features
- Real-time odds updates (5-minute intervals)
- Spread betting system
- Multiple sports support (NBA, NFL)
- Live score integration
- Bet tracking and history
- Win/loss analytics
- Featured games system

### Security Features
- Biometric authentication for real money transactions
- Daily betting limits enforcement
- Auto-logout (30 minutes)
- Transaction confirmations
- Secure Firebase rules
- Encrypted credential storage

### Admin Features
- Game management dashboard
- User management tools
- Bet monitoring system
- Transaction oversight
- System health monitoring
- Risk alert system

## Project Structure

```
BettorOdds/
├── BettorOdds/                     # Main app files
│   ├── BettorOddsApp.swift        # App entry point
│   ├── ContentView.swift          # Root view controller
│   └── Info.plist                 # App configuration
├── Models/                         # Data models
│   ├── Bet.swift                  # Betting system models
│   ├── Game.swift                 # Game and sports data
│   ├── Transaction.swift          # Financial transactions
│   ├── User.swift                 # User accounts and preferences
│   └── TeamColors.swift           # Team branding
├── Views/                          # SwiftUI views
│   ├── Auth/                      # Authentication screens
│   ├── Games/                     # Game browsing and betting
│   ├── Betting/                   # Bet management
│   ├── Profile/                   # User profile and admin
│   └── Shared/                    # Reusable components
├── ViewModels/                     # Business logic
│   ├── AuthenticationViewModel.swift
│   ├── GamesViewModel.swift
│   └── BetModalViewModel.swift
├── Services/                       # API and data services
│   ├── Core/                      # Core business services
│   ├── OddsService.swift          # Sports data integration
│   └── ScoreService.swift         # Live score updates
├── Repositories/                   # Data access layer
│   └── Core/                      # Repository implementations
├── Utilities/                      # Helper functions
│   ├── BiometricHelper.swift      # Biometric authentication
│   ├── Theme.swift                # App theming
│   └── Color+AppTheme.swift       # Color system
├── Components/                     # Reusable UI components
│   └── UI/                        # Custom UI elements
├── Extensions/                     # Swift extensions
└── Documentation/                  # Project documentation
```

## Database Schema
The database schema is defined in `DATABASE_SCHEMA.md` and includes:
- Users collection (authentication, preferences, balances)
- Bets collection (betting data, P2P matching)
- Transactions collection (financial records)
- Games collection (sports data, odds, scores)
- Settings collection (app configuration)

## Setup Instructions

### Prerequisites
- Xcode 15 or higher
- iOS 15.0+ target device or simulator
- Firebase account with project setup
- The Odds API account and key

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone [your-repository-url]
   cd BettorOdds
   ```

2. **Open the project**
   ```bash
   open BettorOdds.xcodeproj
   ```
   
3. **Dependencies are automatically managed**
   - Swift Package Manager will automatically resolve Firebase dependencies
   - No additional installation steps required
   - Dependencies are defined in the Xcode project file

4. **Configure Firebase**
   - Ensure `GoogleService-Info.plist` is properly added to the project
   - Firebase is initialized in `BettorOddsApp.swift`
   - All Firebase services are configured in `FirebaseConfig.swift`

5. **Configure The Odds API**
   - Add your API key to `Configuration.swift`
   - Update the API configuration as needed

### Environment Configuration
- **Development**: Uses Firebase development environment
- **Production**: Uses Firebase production environment
- **API Keys**: Stored in `Configuration.swift` (move to secure storage for production)

## Current Status

### ✅ Completed Features
- User authentication (email/password + phone verification)
- Dual currency system with daily limits
- Real-time betting functionality
- Live odds integration from The Odds API
- Live score updates and game resolution
- Biometric authentication for security
- User profiles and preferences
- Transaction history and tracking
- Admin dashboard with game management
- P2P bet matching system
- Featured games system
- Modern UI with animations and theming

### 🟡 In Progress
- Advanced analytics and reporting
- Enhanced admin controls
- Payment processing integration
- Push notifications system

### 📋 Planned Features
- Social login options
- Advanced betting types (parlays, teasers)
- Chat support system
- Referral program
- Enhanced risk management
- Multi-language support

## Known Issues
- Phone verification requires proper APNs setup for production
- Some admin features require additional testing
- Payment processing integration pending
- Advanced analytics need optimization

## Next Steps

### Immediate Priorities
1. Complete payment processing integration
2. Enhance admin dashboard functionality
3. Implement comprehensive logging
4. Add more comprehensive error handling

### Medium-term Goals
1. Add push notifications
2. Implement advanced betting types
3. Create comprehensive help system
4. Add social features

### Long-term Vision
1. Expand to additional sports
2. Add AI-driven odds analysis
3. Create social betting features
4. Implement advanced risk management

## Development Guidelines

### Code Style
- Follow Swift style guide
- Use SwiftUI best practices
- Implement comprehensive error handling
- Add documentation for all public interfaces
- Use meaningful commit messages

### Testing
- Unit tests for business logic
- UI tests for critical user flows
- Integration tests for API calls
- Regular testing on physical devices

### Security
- Implement proper authentication flows
- Secure sensitive data with Keychain
- Follow Firebase security best practices
- Regular security audits
- Proper error handling without exposing sensitive information

## Maintenance

### Database
- Regular Firestore backups
- Performance monitoring via Firebase Console
- Data cleanup routines for old games/bets
- Usage analytics and optimization

### API Management
- Monitor The Odds API rate limits
- Implement proper caching strategies
- Handle API errors gracefully
- Efficient odds update scheduling

### User Management
- Monitor user growth and engagement
- Track key performance metrics
- Handle user support requests
- Manage verification processes

## Dependencies (Managed via Swift Package Manager)
- Firebase iOS SDK (v11.7.0+)
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseCore
  - FirebaseMessaging
  - FirebaseStorage
  - FirebaseCrashlytics

## Contributing
1. Fork the repository
2. Create a feature branch
3. Follow coding standards
4. Add appropriate tests
5. Submit pull request
6. Ensure code review approval

## License
Proprietary - All rights reserved

## Support
For technical issues or questions:
- Check the documentation in the `/Documentation` folder
- Review Firebase Console for backend issues
- Check The Odds API documentation for sports data issues
- Consult the admin dashboard for system health monitoring

## Acknowledgments
- Firebase team for backend infrastructure
- The Odds API for sports data
- SwiftUI community for UI patterns and best practices
- iOS development community for security and performance guidance
