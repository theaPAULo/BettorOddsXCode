BettorOdds - September Launch Roadmap
Timeline Overview: June - September 2025
🎯 Launch Goal: Limited beta in 1-2 states before NFL season starts

Phase 1: Core P2P System Completion
Timeline: June 1-30, 2025
Critical Features (Must Have)
1. Subscription Billing System
Priority: CRITICAL

 Integrate RevenueCat or Stripe for subscription management
 Implement $9.99/month billing
 Add 7-day free trial period
 Handle subscription status in user profiles
 Payment failure handling and retry logic
 Subscription cancellation flow

Files to modify:

Create SubscriptionService.swift
Update User.swift model
Add SubscriptionView.swift
Update AuthenticationViewModel.swift

2. Enhanced P2P Matching
Priority: HIGH

 Prevent users from matching with themselves
 Implement partial bet matching UI
 Add bet queue visibility for users
 Improve matching algorithm efficiency
 Add bet cancellation window (5 minutes)

Files to modify:

BetMatchingService.swift
BetModal.swift
Create BetQueueView.swift

3. Loss Streak Protection
Priority: CRITICAL

 Track consecutive losses per user
 Implement 3-loss daily lockout
 Add lockout notifications
 Reset counters at midnight
 Admin override capabilities

Files to modify:

User.swift (add lossStreak, lockoutUntil fields)
BetService.swift (add validation)
Create EthicalGuardrailsService.swift

4. Green Coin Cash-Out System
Priority: HIGH

 Bank account linking (Plaid integration)
 Withdrawal request interface
 ACH transfer implementation
 Minimum withdrawal amounts ($10)
 Processing time notifications (3-5 business days)

Files to create:

WithdrawalService.swift
BankAccountView.swift
WithdrawalHistoryView.swift


Phase 2: Legal & Compliance Foundation
Timeline: July 1-31, 2025
Legal Requirements
1. KYC/AML Implementation
Priority: CRITICAL

 Identity verification (driver's license)
 Address verification
 Age verification (21+)
 SSN collection for tax reporting
 Document upload and review system

Integration Options:

Jumio for identity verification
Persona.com (easier integration)
Manual review process initially

2. Responsible Gambling Features
Priority: CRITICAL

 Self-exclusion tools (24hr, 7 days, 30 days, permanently)
 Deposit limits (daily/weekly/monthly)
 Reality checks (time spent notifications)
 Problem gambling resources
 Cool-off periods

3. Legal Documentation
Priority: CRITICAL

 Terms of Service (gambling-specific)
 Privacy Policy (financial data handling)
 Responsible Gambling Policy
 State-specific compliance documentation
 User agreement acknowledgments

4. Tax Compliance
Priority: HIGH

 1099 generation for winnings over $600
 Tax reporting integration
 Withholding calculations
 Annual tax document delivery


Phase 3: User Experience & Testing
Timeline: August 1-31, 2025
UI/UX Enhancements
1. Onboarding Flow
Priority: HIGH

 Welcome screens explaining P2P concept
 Subscription sign-up flow
 KYC verification walkthrough
 Practice mode with yellow coins
 Responsible gambling education

2. Yellow Coin Sweepstakes
Priority: MEDIUM

 Weekly prize pool system
 Entry mechanics (bet with yellow coins)
 Prize distribution (gift cards, merchandise)
 Leaderboard system
 Winner announcement system

3. Enhanced Admin Dashboard
Priority: MEDIUM

 Real-time P2P matching monitoring
 User verification queue
 Financial transaction oversight
 Fraud detection alerts
 Responsible gambling flag monitoring

Testing & QA
1. Beta Testing Program
Priority: HIGH

 Recruit 50-100 beta users
 Implement feedback collection
 A/B test key user flows
 Load testing with simultaneous users
 Payment processing tests

2. Security Testing
Priority: CRITICAL

 Penetration testing
 Financial data encryption audit
 API security review
 User data protection validation
 PCI compliance verification


Phase 4: Launch Preparation
Timeline: September 1-15, 2025
Pre-Launch Checklist
1. State Selection & Licensing
Priority: CRITICAL

 Legal review complete for target states
 Required licenses obtained
 Compliance documentation filed
 Legal counsel on standby

Recommended Target States:

Nevada (gambling-friendly)
New Jersey (established online betting)
Pennsylvania (large market)

2. Operations Setup
Priority: CRITICAL

 Customer support system
 24/7 monitoring setup
 Incident response procedures
 Banking relationships established
 Insurance coverage secured

3. Marketing Preparation
Priority: MEDIUM

 Landing page and marketing site
 App Store optimization
 Social media presence
 Influencer partnerships (sports personalities)
 PR strategy for launch


Technical Priorities by Week
Weeks 1-2 (June 1-14): Foundation

Subscription billing integration
Loss streak protection implementation
P2P matching improvements

Weeks 3-4 (June 15-30): Financial Systems

Cash-out system development
Enhanced transaction tracking
Tax compliance preparation

Weeks 5-8 (July): Legal & Compliance

KYC/AML implementation
Responsible gambling features
Legal documentation and policies

Weeks 9-12 (August): Polish & Testing

Beta user testing
UI/UX improvements
Security and performance testing

Weeks 13-14 (September 1-15): Launch

Final bug fixes
App Store submission
Launch in target state(s)


Resource Requirements
Development Team Needs

iOS Developer (you + potentially 1 more)
Backend Developer (Firebase/Node.js)
UI/UX Designer (part-time)
QA Tester (part-time)

External Services Budget

RevenueCat/Stripe: ~$99/month + transaction fees
KYC Service: ~$2-5 per verification
The Odds API: Upgrade to paid plan (~$200/month)
Legal Consultation: $10,000-50,000
Insurance: $5,000-15,000/year

Critical Decision Points

By June 15: Choose target launch state(s)
By July 1: Complete legal review and compliance strategy
By August 1: Begin beta testing with real users
By August 15: Finalize launch date and marketing strategy


Success Metrics for Launch
User Acquisition (Month 1)

100+ verified users
50+ active bettors
$1,000+ in monthly subscription revenue

Product Performance

<2 second bet matching time
99%+ uptime
<1% payment processing failures

Compliance

Zero regulatory issues
100% KYC completion rate
All required reporting completed