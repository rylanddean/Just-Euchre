# GameKit Real-Time Multiplayer

**Status:** Planning
**Framework:** GameKit (`GKMatch`, `GKMatchmaker`)
**Scope:** 2–4 human players over internet or local network, with AI filling empty seats

---

## Overview

GameKit real-time matches use Apple's servers as a relay — no backend infrastructure required. Players are matched via Game Center, then send data directly through Apple's relay. Just Euchre's turn-based, low-bandwidth nature makes this a good fit.

---

## Architecture Changes Required

### 1. Extract `EuchreGame` from `GameViewController`

Currently all game logic lives inside `GameViewController.swift` as a private nested class. Before any multiplayer work, the engine must be a standalone, independently testable module.

**Goal:** `EuchreGame` takes player moves as input and emits state — no assumptions about who is human, local, or remote.

### 2. Abstract the `Player` type

Today:
```swift
struct Player {
    var hand: [Card] = []
    let isHuman: Bool   // true only for seat 0
}
```

Replace with a protocol:
```swift
protocol EuchrePlayer {
    var seatIndex: Int { get }
    func requestMove(for phase: EuchreGame.Phase, game: EuchreGame) async -> EuchreMove
}
```

Three concrete types:
- `LocalHumanPlayer` — waits for UI input
- `AIPlayer` — wraps existing `performAIMove` logic
- `RemotePlayer` — waits for a move message over GKMatch

### 3. Define the move protocol

All player actions reduce to one small `Codable` enum:

```swift
enum EuchreMove: Codable {
    case orderUp(alone: Bool)           // Round 1 bid: pick it up
    case pass                           // Any bid round: pass
    case callSuit(Card.Suit, alone: Bool) // Round 2 bid: name trump
    case discard(Card)                  // Dealer discard after pickup
    case playCard(Card)                 // Play a card in a trick
}
```

This is the only thing that ever crosses the network. State is derived locally on each device by replaying moves against a shared starting seed.

### 4. Seat assignment protocol

On game start, the host broadcasts seat assignments. Each device only controls its own seat; all others are `RemotePlayer` instances (or `AIPlayer` if a seat is empty/bot).

```swift
struct SeatAssignment: Codable {
    let seatIndex: Int          // 0–3
    let playerID: String        // GKPlayer.gamePlayerID
    let playerName: String
    let isBot: Bool
}
```

---

## GameKit Integration

### Key APIs

| API | Purpose |
|-----|---------|
| `GKMatchmaker` | Find and invite other players |
| `GKMatch` | The live session; send/receive data |
| `GKMatchmakerViewController` | Built-in UI for inviting friends or random matching |
| `GKLocalPlayer` | Authenticate the local user |

### Message envelope

Every network message wraps a move with metadata:

```swift
struct MatchMessage: Codable {
    let seatIndex: Int
    let move: EuchreMove
    let handSerial: Int   // Matches EuchreGamePersistedState.handSerial — guards against stale moves
}
```

### Connection lifecycle

```
1. GKLocalPlayer.local.authenticateHandler
      ↓ authenticated
2. Present GKMatchmakerViewController
      ↓ match found (2–4 players)
3. Host (lowest GKPlayer.gamePlayerID alphabetically) assigns seats,
   broadcasts SeatAssignment[] to all peers
      ↓ all peers acknowledge
4. Host broadcasts initial deck seed (random UInt64)
      ↓ all peers reconstruct identical starting hand
5. Game runs — each player sends their EuchreMove when it's their turn
6. All peers apply the move locally, advance state
7. On disconnect: vacant seat becomes AIPlayer, game continues
```

### Authoritative model

No single device is a "server." Instead, the game uses a **shared seed + move log** approach:

- All devices start from the same shuffled deck (seeded RNG, seed broadcast by host)
- Each device applies moves in order — state stays identical across all devices
- No state sync messages needed; only moves are transmitted
- `handSerial` prevents applying moves from a previous hand

This keeps the existing `EuchreGame` logic completely unchanged — it just receives moves from different sources.

---

## `MultiplayerSessionManager` (new class)

Owns the `GKMatch` and bridges it to the game engine.

**Responsibilities:**
- Authenticate with Game Center on app launch
- Present matchmaker UI
- Receive raw `Data` from `GKMatch`, decode into `MatchMessage`, forward to `RemotePlayer`
- Encode local `EuchreMove` and send via `GKMatch.sendData(toAllPlayers:)`
- Handle `playerDidDisconnect` — swap that seat to `AIPlayer`
- Handle app backgrounding — pause game, attempt reconnect on foreground

---

## UI Changes

### Home screen
- New "Play with Friends" entry point (alongside daily game)
- Uses pill button style, secondary treatment — daily game stays primary

### In-game
- Player name badges (seats 1–3) show actual player names instead of bot names
- Connection indicator — subtle dot on each remote badge (connected / reconnecting)
- "Waiting for player…" state when a remote player is slow

### Matchmaking
- Use `GKMatchmakerViewController` as-is (Apple-provided UI)
- No custom matchmaking UI needed for v1

---

## What Does NOT Change

- Daily game mode is completely unaffected
- Game Center achievements continue working as-is
- `EuchreGamePersistedState` / `GameStateStore` — only used for daily game save/restore, not multiplayer
- All existing rendering code in `GameViewController` — seat layout, card animations, etc.

---

## Open Questions

1. **Multiplayer game length** — Full game (10 points) or a fixed number of hands? Full game could take 20–30 min.
2. **Daily game gating** — Does multiplayer count against the daily game limit, or is it a separate mode entirely?
3. **Bot difficulty in empty seats** — Use existing AI, or let the host choose difficulty?
4. **Rematch flow** — After a game ends, offer a rematch with the same players?
5. **Minimum player count** — Require all 4 humans, or allow 2v2 with 2 bots filling in?

---

## Implementation Order

1. **Refactor:** Extract `EuchreGame` into its own file; verify nothing breaks
2. **Refactor:** Add `EuchrePlayer` protocol; wire `LocalHumanPlayer` and `AIPlayer`; verify daily game still works
3. **Engine:** Add `EuchreMove` enum; make game engine accept moves via protocol instead of direct method calls
4. **Networking:** Build `MultiplayerSessionManager`; test with 2 devices on local network
5. **Seat assignment:** Implement host election + seat broadcast
6. **Disconnect handling:** Swap disconnected seats to `AIPlayer` mid-game
7. **UI:** Player name badges, connection state, "Play with Friends" entry point
8. **Polish:** Matchmaker presentation, rematch flow, error states

---

## Dependencies

- `GameKit` (already linked — used for achievements)
- No new third-party dependencies
- Requires Game Center entitlement (already present)
- Requires iOS 16+ for `async/await` GKMatch APIs (already minimum deployment target)
