BettorOdds Mobile App
Overview
BettorOdds is a sports betting platform focused on responsible gambling and user experience. The app features a dual-currency system, daily betting limits, and real-time odds updates.
Current Version

Version: 1.0.0
Last Updated: January 29, 2025
Status: Development

Technical Stack
Frontend

SwiftUI for iOS native development
React Native components for cross-platform shared components
Custom UI components with Tailwind CSS

Backend

Firebase

Authentication
Firestore Database
Cloud Functions (planned)
Storage


The Odds API for sports data

Development Environment

Xcode 15+
iOS 15.0+ deployment target
Firebase iOS SDK
SwiftUI 4.0

Core Features
Authentication System

Email/password registration
Secure session management
Future: Email verification, social login

Dual Currency System
Yellow Coins (Practice)

Starting balance: 100 coins
No real value
Unlimited daily usage
Training purpose

Green Coins (Real Money)

1:1 USD ratio
$100 daily limit
Biometric authentication
Transaction history

Betting Features

Real-time odds updates (5-minute intervals)
Spread betting
Multiple sports support
Bet tracking
Win/loss history

Security Features

Biometric authentication
Daily betting limits
Auto-logout (30 minutes)
Transaction confirmations

Project Structure
Swift Files Organization
CopyBettorOdds/
├── App/
│   ├── BettorOddsApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Bet.swift
│   ├── Game.swift
│   ├── Transaction.swift
│   └── User.swift
├── Views/
│   ├── Authentication/
│   ├── Betting/
│   ├── Profile/
│   └── Common/
├── ViewModels/
│   ├── AuthenticationViewModel.swift
│   ├── BetModalViewModel.swift
│   └── GamesViewModel.swift
├── Services/
│   ├── BetService.swift
│   ├── GameService.swift
│   └── UserService.swift
└── Utilities/
    ├── BiometricHelper.swift
    └── Theme.swift
Database Schema
The database schema is defined in DATABASE_SCHEMA.md and includes:

Users collection
Bets collection
Transactions collection
Games collection
Settings collection

Setup Instructions
Prerequisites

Xcode 15 or higher
CocoaPods
Firebase account
The Odds API key

Initial Setup

Clone the repository
Install dependencies:
bashCopypod install

Configure Firebase:

Add GoogleService-Info.plist
Initialize Firebase in BettorOddsApp.swift


Configure The Odds API:

Add API key to Configuration.swift



Environment Configuration

Development: localhost:8080
Production: Firebase production environment

Current Status
Completed Features

✅ User authentication (basic)
✅ Dual currency system
✅ Basic betting functionality
✅ Real-time odds integration
✅ Biometric authentication
✅ User profiles
✅ Transaction history
✅ Daily limits

In Progress

🟡 Email verification
🟡 Admin dashboard
🟡 Advanced analytics
🟡 Payment processing

Planned Features

📋 Social login
📋 Push notifications
📋 Chat support
📋 Advanced betting types
📋 Referral system

Known Issues

No email verification on signup
Limited admin controls
Basic error handling in some areas
Need for more comprehensive testing

Next Steps
Immediate Priorities

Implement email verification
Create admin dashboard
Enhance error handling
Add comprehensive logging

Medium-term Goals

Add payment processing
Implement push notifications
Create chat support system
Add social features

Long-term Vision

Expand to additional sports
Add advanced betting types
Implement AI-driven odds analysis
Create social betting features

Development Guidelines
Code Style

Follow Swift style guide
Use SwiftUI best practices
Implement comprehensive error handling
Add documentation for all public interfaces

Testing

Unit tests for business logic
UI tests for critical flows
Integration tests for API calls

Security

Implement proper authentication flows
Secure sensitive data
Follow Firebase security rules
Regular security audits

Maintenance
Database

Regular backups
Performance monitoring
Data cleanup routines
Usage analytics

API

Monitor rate limits
Cache responses
Handle errors gracefully
Update odds efficiently

User Management

Monitor user growth
Track engagement metrics
Handle support requests
Manage verification processes

Contributing

Fork the repository
Create feature branch
Submit pull request
Follow code review process

License
Proprietary - All rights reserved
Contact
[Your Contact Information]
Acknowledgments

Firebase team
The Odds API
SwiftUI community
