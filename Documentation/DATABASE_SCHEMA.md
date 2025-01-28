# BettorOdds Database Schema

## Collections

### Users Collection
```typescript
users/{userId}
{
    id: string               // User's unique identifier
    email: string           // User's email address
    dateJoined: timestamp   // When user created account
    yellowCoins: number     // Play money balance
    greenCoins: number      // Real money balance
    dailyGreenCoinsUsed: number  // Amount of real money used today
    lastBetDate: timestamp  // Last bet timestamp for daily limit reset
    preferences: {
        requireBiometricsForGreenCoins: boolean
        darkMode: boolean
        notificationsEnabled: boolean
    }
    stats: {
        totalBets: number
        wonBets: number
        lostBets: number
        totalWagered: number
        netProfit: number
    }
}
```

### Bets Collection
```typescript
bets/{betId}
{
    id: string             // Bet's unique identifier
    userId: string         // Reference to user
    gameId: string         // Reference to game
    coinType: string       // "yellow" or "green"
    amount: number         // Bet amount
    initialSpread: number  // Spread at time of bet
    currentSpread: number  // Current spread (for line movement)
    status: string         // "pending", "active", "won", "lost", "cancelled"
    createdAt: timestamp   // When bet was placed
    updatedAt: timestamp   // Last status update
    team: string          // Team bet on
    isHomeTeam: boolean   // Whether bet is on home team
}
```

### Transactions Collection
```typescript
transactions/{transactionId}
{
    id: string           // Transaction unique identifier
    userId: string       // Reference to user
    type: string         // "deposit", "withdrawal", "bet", "win", "loss"
    coinType: string     // "yellow" or "green"
    amount: number       // Transaction amount
    betId: string?      // Optional reference to related bet
    status: string      // "pending", "completed", "failed", "cancelled"
    createdAt: timestamp // When transaction occurred
    description: string  // Transaction description
}
```

### Games Collection
```typescript
games/{gameId}
{
    id: string           // Game unique identifier
    homeTeam: string     // Home team name
    awayTeam: string     // Away team name
    homeTeamColors: {    // Team color theme
        primary: string
        secondary: string
    }
    awayTeamColors: {
        primary: string
        secondary: string
    }
    league: string      // "NBA", "NFL", etc.
    startTime: timestamp // Game start time
    spread: number      // Current spread
    totalBets: number   // Number of bets placed
    status: string      // "upcoming", "live", "finished"
    score: {
        home: number
        away: number
    }
    spreadHistory: [    // Track line movements
        {
            spread: number
            timestamp: timestamp
        }
    ]
}
```

### Settings Collection
```typescript
settings/{settingId}
{
    id: string          // Setting identifier
    maxBetAmount: number // Maximum bet amount
    dailyGreenLimit: number // Daily limit for green coins
    maintenanceMode: boolean // App maintenance status
    minBetAmount: number // Minimum bet amount
    version: string     // Current app version
    requiredVersion: string // Minimum required app version
}
```

## Security Rules

Basic security rules structure:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }

    // Bets can be read by the bet owner
    match /bets/{betId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }

    // Transactions can be read by the transaction owner
    match /transactions/{transactionId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }

    // Games are publicly readable but only admin writable
    match /games/{gameId} {
      allow read: if true;
      allow write: if false;  // Only through admin SDK
    }

    // Settings are publicly readable but only admin writable
    match /settings/{settingId} {
      allow read: if true;
      allow write: if false;  // Only through admin SDK
    }
  }
}
```

## Indexes

Required indexes for queries:

1. Bets collection:
   - userId + status
   - userId + createdAt
   - gameId + status

2. Transactions collection:
   - userId + createdAt
   - userId + type
   - userId + coinType

3. Games collection:
   - league + startTime
   - status + startTime

## Data Flow

1. User Registration:
   - Create user document
   - Initialize with 100 yellow coins
   - Set up preferences

2. Placing Bets:
   - Validate user balance
   - Create bet document
   - Create transaction document
   - Update user balance

3. Game Updates:
   - Update game document
   - Update affected bets
   - Create transaction documents for winners
   - Update user balances

4. Daily Reset:
   - Reset dailyGreenCoinsUsed at midnight
   - Archive completed bets
   - Update user statistics