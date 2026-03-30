//
//  GameViewController.swift
//  Just Euchre iOS
//
//  Offsuit-inspired minimal UI, but for a playable Euchre hand:
//  - 4 players (you + 3 bots), 24-card deck (9-A)
//  - Two-round trump making, dealer pick-up/discard, optional going alone
//  - 5-trick play with right/left bower rules and standard scoring
//

import UIKit

final class GameViewController: UIViewController {

    private let theme = Theme()
    private var seatEmojis = ["🙂", "🦊", "🦉", "🤖"] // You, W, N, E

    private let titleLabel = UILabel()
    private let headerRow = UIStackView()
    private let statusContainer = UIView()
    private let statusLabel = UILabel()
    private let tableContainer = UIView()
    private let upcardView = CardView()
    private let indicatorRow = UIStackView()
    private let trumpBadge = BadgeView()
    private let ledBadge = BadgeView()
    private var indicatorTopToUpcard: NSLayoutConstraint?
    private var indicatorTopToContainer: NSLayoutConstraint?

    private let trickNorth = CardView()
    private let trickWest = CardView()
    private let trickEast = CardView()
    private let trickSouth = CardView()

    private let gameOverLabel = UILabel()

    private let actionRow = UIStackView()
    private let handRow = UIStackView()

    private var playerBadges: [PlayerBadgeView] = []
    private var handCardViews: [CardView] = []

    private var game = EuchreGame()
    private var selectedDiscardCard: EuchreGame.Card?
    private var didRecordOutcome = false
    private var gameOverNudge: String?
    private var hasInitializedGame = false

    // Partner persona + table talk
    private var partnerPersona: PartnerPersona?
    private var needsPartnerIntro = false
    private let partnerBubble = UIView()
    private let partnerBubbleLabel = UILabel()
    private var partnerBubbleTimer: Timer?
    // Trigger deduplication: track last hand serial and scores we fired dialog for
    private var lastDialogHandSerial = -1
    private var lastDialogScores: [Int] = [-1, -1]
    private var lastDialogWinningTeam: Int? = nil
    private var idleDialogTrickCount = 0  // how many tricks since last idle comment

    private var suggestionTimer: Timer?
    private weak var hintedCardView: CardView?
    private let hintPillView = UIView()
    private let hintLabel = UILabel()

    // Card-fly animation tracking. -1 means "not yet initialised" (skip first render).
    private var previousTrickCount: Int = -1
    private var pendingPlaySourceRect: CGRect? // tableContainer coords, set before humanPlayCard

    // Trick-sweep animation: tracks which trickOver winner we've already scheduled a sweep for.
    private var scheduledSweepWinner: Int? = nil

    // Euchre/March banner
    private let bannerView  = UIView()
    private let bannerLabel = UILabel()
    private var lastBannerHandSerial: Int = -1

    // Trump suit flash
    private let trumpFlashLabel = UILabel()
    private var lastFlashedTrump: EuchreGame.Card.Suit? = nil

    // Deal-stagger animation: tracks the last hand serial we animated so restoring a saved
    // game mid-hand never re-plays the deal animation.
    private var lastSeenHandSerial: Int = 0

    // Score badge bounce: tracks last known scores so we only bounce when a score actually changes.
    private var lastKnownScores: [Int] = [-1, -1]

    // Upcard flip reveal: tracks which upcard we've already flipped so we only animate once
    // per deal, and never re-fire on app restore. Flag guards mid-flip render() calls.
    private var lastFlippedUpcard: EuchreGame.Card? = nil
    private var upcardFlipInProgress = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.background
        buildUI()

        game.humanName = "You"
        game.setBotNames(BotNameGenerator.nextBotNames(count: 3))
        game.onUpdate = { [weak self] in
            self?.render()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        restoreIfPossible()
        lastSeenHandSerial  = game.handSerial // don't stagger cards that were already dealt
        lastBannerHandSerial = game.handSerial // don't re-fire a banner for a restored handOver
        lastFlashedTrump    = game.trump       // don't flash trump for a restored mid-hand state
        lastKnownScores     = game.scores      // don't bounce badges for a restored score
        lastFlippedUpcard   = game.upcard      // don't flip the upcard for a restored game
        render()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentPartnerIntroIfNeeded()
    }

    func startNewGameFromMenu() {
        loadViewIfNeeded()

        guard DailyGameStore.canStartNewGameToday() else { return }
        DailyGameStore.markStartedToday()

        selectedDiscardCard = nil
        didRecordOutcome = false
        gameOverNudge = nil
        hasInitializedGame = true

        // Pick a partner persona for this game.
        let persona = PartnerPersona.next()
        partnerPersona = persona
        seatEmojis[2] = persona.emoji    // North badge emoji

        game = EuchreGame()
        game.humanName = "You"
        let botNames = BotNameGenerator.nextBotNames(count: 3)
        // Override the North slot (index 1 of the 3 bots) with the persona's name.
        let partnerBotIndex = 1
        var adjustedNames = botNames
        if adjustedNames.count > partnerBotIndex {
            adjustedNames[partnerBotIndex] = persona.name
        }
        game.setBotNames(adjustedNames)
        game.onUpdate = { [weak self] in
            self?.render()
        }
        lastSeenHandSerial = -1 // ensure the first deal always staggers

        // Reset dialog tracking for the new game
        lastDialogHandSerial = -1
        lastDialogScores = [-1, -1]
        lastDialogWinningTeam = nil
        idleDialogTrickCount = 0
        dismissPartnerBubble()

        // Show partner intro — game.startNewHand() fires after the user dismisses it.
        needsPartnerIntro = true
    }

    private func presentPartnerIntroIfNeeded() {
        guard needsPartnerIntro, let persona = partnerPersona else { return }
        needsPartnerIntro = false

        // Rebuild header so the badge shows the persona name/emoji before the intro.
        buildHeader()
        render()

        let intro = PartnerIntroViewController(persona: persona)
        intro.onReady = { [weak self] in
            self?.game.startNewHand()
        }
        present(intro, animated: false)
    }

    private func buildUI() {
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .equalSpacing
        headerRow.spacing = 14

        actionRow.axis = .horizontal
        actionRow.alignment = .center
        actionRow.distribution = .fill
        actionRow.spacing = 12

        handRow.axis = .horizontal
        // Card views have no intrinsic height; use `.fill` so they size to the row height.
        handRow.alignment = .fill
        handRow.distribution = .fillEqually
        handRow.spacing = 10

        titleLabel.text = "Just Euchre"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textAlignment = .center

        statusLabel.textColor = theme.mutedText
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        statusLabel.numberOfLines = 1
        statusLabel.textAlignment = .center

        trumpBadge.isHidden = true
        ledBadge.isHidden = true
        indicatorRow.isHidden = true

        hintPillView.backgroundColor = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
        hintPillView.layer.cornerRadius = 12
        hintPillView.layer.borderWidth = 1
        hintPillView.layer.borderColor = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 0.5).cgColor
        hintPillView.alpha = 0
        hintPillView.translatesAutoresizingMaskIntoConstraints = false

        hintLabel.textColor = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)
        hintLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintPillView.addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.leadingAnchor.constraint(equalTo: hintPillView.leadingAnchor, constant: 12),
            hintLabel.trailingAnchor.constraint(equalTo: hintPillView.trailingAnchor, constant: -12),
            hintLabel.topAnchor.constraint(equalTo: hintPillView.topAnchor, constant: 6),
            hintLabel.bottomAnchor.constraint(equalTo: hintPillView.bottomAnchor, constant: -6),
        ])

        view.addSubview(titleLabel)
        view.addSubview(headerRow)
        view.addSubview(statusContainer)
        view.addSubview(tableContainer)
        view.addSubview(actionRow)
        view.addSubview(hintPillView)
        view.addSubview(handRow)
        view.addSubview(partnerBubble)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        tableContainer.translatesAutoresizingMaskIntoConstraints = false
        actionRow.translatesAutoresizingMaskIntoConstraints = false
        handRow.translatesAutoresizingMaskIntoConstraints = false
        partnerBubble.translatesAutoresizingMaskIntoConstraints = false

        statusContainer.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
        ])

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            headerRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            headerRow.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            headerRow.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            statusContainer.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 10),
            statusContainer.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            statusContainer.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),
            statusContainer.heightAnchor.constraint(equalToConstant: 44),

            tableContainer.topAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: 14),
            tableContainer.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            tableContainer.trailingAnchor.constraint(equalTo: safe.trailingAnchor),

            actionRow.topAnchor.constraint(equalTo: tableContainer.bottomAnchor, constant: 14),
            actionRow.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            actionRow.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -18),
            actionRow.centerXAnchor.constraint(equalTo: safe.centerXAnchor),

            handRow.topAnchor.constraint(equalTo: actionRow.bottomAnchor, constant: 14),
            handRow.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            handRow.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),
            handRow.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -18),
            handRow.heightAnchor.constraint(equalToConstant: 116),

            hintPillView.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            hintPillView.bottomAnchor.constraint(equalTo: handRow.topAnchor, constant: -6),
            hintPillView.leadingAnchor.constraint(greaterThanOrEqualTo: safe.leadingAnchor, constant: 18),
            hintPillView.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -18),

            // Partner speech bubble — floats below the header row, horizontally centered
            partnerBubble.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 6),
            partnerBubble.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            partnerBubble.leadingAnchor.constraint(greaterThanOrEqualTo: safe.leadingAnchor, constant: 18),
            partnerBubble.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -18),
        ])

        buildHeader()
        buildTable()
        buildBanner()
        buildTrumpFlash()
        buildPartnerBubble()
    }

    private func buildHeader() {
        playerBadges = []
        headerRow.arrangedSubviews.forEach { headerRow.removeArrangedSubview($0); $0.removeFromSuperview() }

        // Seat order (clockwise): 0 = You (South), 1 = West, 2 = North, 3 = East
        for index in 0..<4 {
            let badge = PlayerBadgeView(theme: theme)
            badge.setName(game.playerNames[index])
            badge.setEmoji(seatEmojis[index])
            playerBadges.append(badge)
            headerRow.addArrangedSubview(badge)
        }
    }

    private func recordOutcomeIfNeeded() {
        guard !didRecordOutcome else { return }
        guard game.winningTeam != nil else { return }
        didRecordOutcome = true

        let didWin = game.winningTeam == 0

        // Prevent duplicate writes if we restore a finished game from persistence.
        let today = DailyGameStore.todayKeyDate()
        if let last = GameHistoryStore.entries().first, Calendar.current.isDate(last.date, inSameDayAs: today) {
            DailyGameStore.markCompletedToday(didWin: didWin)
            GameStateStore.clear()
            return
        }

        GameHistoryStore.addResult(yourScore: game.scores[0], theirScore: game.scores[1])
        DailyGameStore.markCompletedToday(didWin: didWin)
        GameStateStore.clear()
    }

    @objc private func appDidEnterBackground() {
        persistIfNeeded()
    }

    @objc private func appWillResignActive() {
        persistIfNeeded()
    }

    private func persistIfNeeded() {
        guard DailyGameStore.hasStartedToday() else { return }
        guard game.winningTeam == nil else { return }
        guard hasInitializedGame else { return }

        let today = DailyGameStore.todayKeyDate()
        let state = game.persistedState(now: Date())
        guard let data = try? JSONEncoder().encode(state) else { return }
        GameStateStore.save(day: today, state: data)
    }

    private func restoreIfPossible() {
        guard DailyGameStore.hasStartedToday() else { return }
        let today = DailyGameStore.todayKeyDate()
        guard let data = GameStateStore.loadIfToday(today: today) else { return }
        guard let state = try? JSONDecoder().decode(EuchreGamePersistedState.self, from: data) else { return }
        game.applyPersistedState(state)
        game.humanName = "You"
        hasInitializedGame = true
    }

    private func buildTable() {
        tableContainer.subviews.forEach { $0.removeFromSuperview() }

        tableContainer.addSubview(upcardView)
        tableContainer.addSubview(indicatorRow)
        tableContainer.addSubview(trickNorth)
        tableContainer.addSubview(trickWest)
        tableContainer.addSubview(trickEast)
        tableContainer.addSubview(trickSouth)

        [upcardView, trickNorth, trickWest, trickEast, trickSouth].forEach { view in
            view.theme = theme
            view.isHidden = true
            view.isUserInteractionEnabled = false
        }

        indicatorRow.axis = .horizontal
        indicatorRow.alignment = .center
        indicatorRow.distribution = .fill
        indicatorRow.spacing = 10

        trumpBadge.theme = theme
        ledBadge.theme = theme
        indicatorRow.arrangedSubviews.forEach { indicatorRow.removeArrangedSubview($0); $0.removeFromSuperview() }
        indicatorRow.addArrangedSubview(trumpBadge)
        indicatorRow.addArrangedSubview(ledBadge)

        upcardView.translatesAutoresizingMaskIntoConstraints = false
        indicatorRow.translatesAutoresizingMaskIntoConstraints = false
        trickNorth.translatesAutoresizingMaskIntoConstraints = false
        trickWest.translatesAutoresizingMaskIntoConstraints = false
        trickEast.translatesAutoresizingMaskIntoConstraints = false
        trickSouth.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),

            upcardView.centerXAnchor.constraint(equalTo: tableContainer.centerXAnchor),
            upcardView.topAnchor.constraint(equalTo: tableContainer.topAnchor, constant: 6),
            upcardView.widthAnchor.constraint(equalToConstant: 78),
            upcardView.heightAnchor.constraint(equalToConstant: 108),
            indicatorRow.centerXAnchor.constraint(equalTo: tableContainer.centerXAnchor),

            trickSouth.centerXAnchor.constraint(equalTo: tableContainer.centerXAnchor),
            trickSouth.bottomAnchor.constraint(equalTo: tableContainer.bottomAnchor, constant: -6),
            trickSouth.widthAnchor.constraint(equalToConstant: 78),
            trickSouth.heightAnchor.constraint(equalToConstant: 108),

            trickNorth.centerXAnchor.constraint(equalTo: tableContainer.centerXAnchor),
            trickNorth.topAnchor.constraint(equalTo: tableContainer.topAnchor, constant: 64),
            trickNorth.widthAnchor.constraint(equalToConstant: 78),
            trickNorth.heightAnchor.constraint(equalToConstant: 108),

            trickWest.centerYAnchor.constraint(equalTo: tableContainer.centerYAnchor, constant: 20),
            trickWest.leadingAnchor.constraint(equalTo: tableContainer.leadingAnchor, constant: 36),
            trickWest.widthAnchor.constraint(equalToConstant: 78),
            trickWest.heightAnchor.constraint(equalToConstant: 108),

            trickEast.centerYAnchor.constraint(equalTo: tableContainer.centerYAnchor, constant: 20),
            trickEast.trailingAnchor.constraint(equalTo: tableContainer.trailingAnchor, constant: -36),
            trickEast.widthAnchor.constraint(equalToConstant: 78),
            trickEast.heightAnchor.constraint(equalToConstant: 108),
        ])

        indicatorTopToUpcard = indicatorRow.topAnchor.constraint(equalTo: upcardView.bottomAnchor, constant: 10)
        indicatorTopToContainer = indicatorRow.topAnchor.constraint(equalTo: tableContainer.topAnchor, constant: 14)
        indicatorTopToUpcard?.isActive = true

        gameOverLabel.numberOfLines = 0
        gameOverLabel.textAlignment = .center
        gameOverLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        gameOverLabel.textColor = .white
        gameOverLabel.isHidden = true
        gameOverLabel.translatesAutoresizingMaskIntoConstraints = false
        tableContainer.addSubview(gameOverLabel)
        NSLayoutConstraint.activate([
            gameOverLabel.leadingAnchor.constraint(equalTo: tableContainer.leadingAnchor, constant: 24),
            gameOverLabel.trailingAnchor.constraint(equalTo: tableContainer.trailingAnchor, constant: -24),
            gameOverLabel.centerYAnchor.constraint(equalTo: tableContainer.centerYAnchor),
        ])
    }

    private func render() {
        if !game.isAwaitingHumanDiscard {
            selectedDiscardCard = nil
        }

        // Header
        let winningPlayer = game.trickWinnerPlayer ?? game.currentWinningPlayer
        for index in 0..<4 {
            let badge = playerBadges[index]
            if game.playerNames.count == 4 {
                badge.setName(game.playerNames[index])
            }
            let team = game.team(of: index)
            badge.setScore(game.scores[game.team(of: index)])
            badge.setTricks(game.tricksWonByTeam[team], visible: game.shouldShowTrickTally)
            badge.setTeam(team)
            badge.setMaker(index == game.makerPlayerToDisplay, tint: game.trump.map(suitTint))
            badge.setDealer(index == game.dealer)
            badge.setActive(game.isPlayerActive(index))
            badge.setTurn(index == game.currentTurnPlayer)
            badge.setWinning(index == winningPlayer)
        }

        // Score badge bounce — fire once when a team's score increases at handOver.
        if case .handOver = game.phase {
            for team in 0..<2 {
                let newScore = game.scores[team]
                if newScore != lastKnownScores[team] {
                    lastKnownScores[team] = newScore
                    playerBadges[team].bounce()
                    playerBadges[team + 2].bounce()
                }
            }
        }

        // Status
        if game.winningTeam != nil {
            if gameOverNudge == nil {
                gameOverNudge = OnDeviceNudgeGenerator.nextNudge()
            }
            statusLabel.text = game.statusText
            gameOverLabel.text = gameOverNudge
            gameOverLabel.isHidden = false
        } else {
            statusLabel.text = game.statusText
            gameOverLabel.isHidden = true
        }
        recordOutcomeIfNeeded()

        // Euchre / March banner — show once per hand when the hand ends.
        if case .handOver = game.phase, game.handSerial != lastBannerHandSerial {
            lastBannerHandSerial = game.handSerial
            if let text = handOutcomeBannerText() {
                showBanner(text)
            }
        }

        // Upcard + trump
        if let upcard = game.upcard {
            let showUpcard = game.shouldShowUpcard
            if showUpcard {
                if upcard != lastFlippedUpcard {
                    // New upcard this hand — play the flip reveal once.
                    lastFlippedUpcard = upcard
                    flipUpcardReveal(upcard)
                } else {
                    // Already flipped — just keep it visible. Guard against
                    // setCard calls while the flip animation is still running.
                    upcardView.isHidden = false
                    if !upcardFlipInProgress {
                        upcardView.setCard(upcard, faceDown: false)
                    }
                }
            } else {
                upcardView.isHidden = true
            }

            indicatorTopToUpcard?.isActive = showUpcard
            indicatorTopToContainer?.isActive = !showUpcard
        } else {
            upcardView.isHidden = true
            indicatorTopToUpcard?.isActive = false
            indicatorTopToContainer?.isActive = true
        }

        if let trump = game.trump {
            trumpBadge.isHidden = false
            trumpBadge.setText("Trump: \(trump.symbol)")
            // Flash the suit symbol the first time trump is set this hand.
            // Skip during dealerDiscard — the upcard is still on screen and would be
            // obscured. Leave lastFlashedTrump unchanged so the flash fires as soon as
            // play begins and the table is clear.
            if trump != lastFlashedTrump, case .dealerDiscard = game.phase {
                // deferred — do nothing
            } else if trump != lastFlashedTrump {
                lastFlashedTrump = trump
                flashTrumpSuit(trump)
            }
        } else {
            trumpBadge.isHidden = true
            lastFlashedTrump = nil
        }

        if let led = game.ledSuitToDisplay {
            ledBadge.isHidden = false
            ledBadge.setText("Led: \(led.symbol)")
        } else {
            ledBadge.isHidden = true
        }
        indicatorRow.isHidden = trumpBadge.isHidden && ledBadge.isHidden

        // Trick
        // Detect whether a new card was just played so we can animate it flying onto the table.
        let newTrickCount = game.currentTrick.count
        var cardToAnimate: CardView?
        var animSourceRect: CGRect?

        if previousTrickCount >= 0, newTrickCount == previousTrickCount + 1,
           let newPlay = game.currentTrick.last {
            cardToAnimate = trickView(for: newPlay.player)
            if newPlay.player == 0 {
                // Human: use the rect we captured just before humanPlayCard was called.
                animSourceRect = pendingPlaySourceRect
            } else {
                // AI: fly from the player's badge in the header.
                let badge = playerBadges[newPlay.player]
                animSourceRect = badge.convert(badge.bounds, to: tableContainer)
            }
        }
        pendingPlaySourceRect = nil
        previousTrickCount = newTrickCount

        // Reset visual state before hiding so the next trick always starts clean
        // (a sweep may have left alpha=0 / non-identity transforms on the views).
        [trickNorth, trickEast, trickWest, trickSouth].forEach {
            $0.alpha = 1
            $0.transform = .identity
        }
        trickNorth.isHidden = true
        trickEast.isHidden = true
        trickWest.isHidden = true
        trickSouth.isHidden = true
        [trickNorth, trickEast, trickWest, trickSouth].forEach { $0.clearPlayerMarker() }
        [trickNorth, trickEast, trickWest, trickSouth].forEach { $0.isWinnerHighlighted = false }
        [trickNorth, trickEast, trickWest, trickSouth].forEach { $0.isLeadHighlighted = false }

        for play in game.currentTrick {
            let view = trickView(for: play.player)
            view.isHidden = false
            view.setCard(play.card, faceDown: false)
            view.setPlayerMarker(text: seatMarkerText(for: play.player))
            if winningPlayer == play.player {
                view.isWinnerHighlighted = true
            }
            if let lead = game.leadPlayToDisplay, lead.player == play.player, lead.card == play.card {
                view.isLeadHighlighted = true
            }
        }

        if let cv = cardToAnimate, let src = animSourceRect {
            animateCardFly(cv, from: src)
        }

        // Trick-sweep: schedule cards flying to the winner when trickOver first fires.
        if let winner = game.trickWinnerPlayer {
            if scheduledSweepWinner != winner {
                scheduledSweepWinner = winner
                scheduleTrickSweep(winner: winner)
            }
        } else {
            scheduledSweepWinner = nil
        }

        // Hand
        let isNewDeal = game.handSerial != lastSeenHandSerial
        if isNewDeal { lastSeenHandSerial = game.handSerial }
        rebuildHand(animateDeal: isNewDeal)
        rebuildActions()

        // Partner dialog hooks
        firePartnerDialogIfNeeded()

        manageSuggestionTimer()
        game.kickAIIfNeeded()
        persistIfNeeded()
    }

    // MARK: - Partner Dialog Firing

    private func firePartnerDialogIfNeeded() {
        guard let persona = partnerPersona else { return }

        // ── Game-over reaction ────────────────────────────────────────────
        if let winTeam = game.winningTeam, winTeam != lastDialogWinningTeam {
            lastDialogWinningTeam = winTeam
            let trigger: PartnerDialogTrigger = (winTeam == 0) ? .weWon : .weLost
            let staticLine = persona.randomLine(for: trigger)
            let ctx = PartnerDialogContext(
                trigger: trigger,
                ourScore: game.scores[0],
                theirScore: game.scores[1],
                partnerName: persona.name
            )
            PartnerDialogAIBridge.generate(for: persona, context: ctx) { [weak self] aiLine in
                self?.showPartnerDialog(aiLine ?? staticLine, delay: 1.0)
            }
            return
        }

        // ── Hand-over reactions (score / euchre / march) ──────────────────
        if case .handOver = game.phase, game.handSerial != lastDialogHandSerial {
            lastDialogHandSerial = game.handSerial

            let ourScore   = game.scores[0]
            let theirScore = game.scores[1]
            let ourDelta   = max(0, ourScore  - max(0, lastDialogScores[0]))
            let theirDelta = max(0, theirScore - max(0, lastDialogScores[1]))
            lastDialogScores = [ourScore, theirScore]

            let trigger: PartnerDialogTrigger
            if let makerIndex = game.makerPlayerToDisplay {
                let makerTeam   = makerIndex % 2
                let makerTricks = game.tricksWonByTeam[makerTeam]
                if makerTricks < 3 {
                    trigger = .euchred
                } else if makerTricks == 5 {
                    trigger = .marched
                } else if ourDelta > 0 {
                    trigger = .weScored
                } else if theirDelta > 0 {
                    trigger = .theyScored
                } else {
                    return
                }
            } else if ourDelta > 0 {
                trigger = .weScored
            } else if theirDelta > 0 {
                trigger = .theyScored
            } else {
                return
            }

            let staticLine = persona.randomLine(for: trigger)
            let ctx = PartnerDialogContext(
                trigger: trigger,
                ourScore: ourScore,
                theirScore: theirScore,
                partnerName: persona.name
            )
            PartnerDialogAIBridge.generate(for: persona, context: ctx) { [weak self] aiLine in
                self?.showPartnerDialog(aiLine ?? staticLine, delay: 0.7)
            }
            return
        }

        // ── Trick-won reactions (occasional, ~1-in-3) ─────────────────────
        if let trickWinner = game.trickWinnerPlayer {
            let trickTeam = trickWinner % 2
            if scheduledSweepWinner == trickWinner {
                idleDialogTrickCount += 1
                if idleDialogTrickCount % 3 == 1 {
                    let trigger: PartnerDialogTrigger = (trickTeam == 0) ? .weTookTrick : .theyTookTrick
                    showPartnerDialog(persona.randomLine(for: trigger), delay: 0.5)
                }
            }
        }

        // ── Trump-made reaction (50% chance, fires once per hand) ─────────
        if game.trump != nil,
           !game.shouldShowUpcard,
           game.handSerial != lastDialogHandSerial,
           Bool.random() {
            showPartnerDialog(persona.randomLine(for: .trumpMade), delay: 0.3)
        }

        // ── Idle comment during play phase (~1-in-4 tricks, 33% chance) ───
        if case .playing = game.phase,
           game.winningTeam == nil,
           idleDialogTrickCount > 0,
           idleDialogTrickCount % 4 == 0,
           partnerBubble.alpha < 0.1,
           Int.random(in: 0..<3) == 0 {
            idleDialogTrickCount = 0
            showPartnerDialog(persona.randomLine(for: .idleComment), delay: 0.4)
        }
    }

    private func trickView(for playerIndex: Int) -> CardView {
        // Seats (clockwise): 0 = You (South), 1 = West, 2 = North, 3 = East
        switch playerIndex {
        case 0: return trickSouth
        case 1: return trickWest
        case 2: return trickNorth
        default: return trickEast
        }
    }

    private func rebuildHand(animateDeal: Bool = false) {
        handRow.arrangedSubviews.forEach { handRow.removeArrangedSubview($0); $0.removeFromSuperview() }
        handCardViews = []
        hintedCardView = nil

        let hand = game.players[0].hand.sorted(by: { game.sortKey(for: $0) < game.sortKey(for: $1) })
        let selectable = Set(game.selectableCardsForHuman())

        for (index, card) in hand.enumerated() {
            let cardView = CardView()
            cardView.theme = theme
            cardView.setCard(card, faceDown: false)
            cardView.clearPlayerMarker()
            cardView.isSelectable = selectable.contains(card)
            cardView.isChosen = game.isAwaitingHumanDiscard && (card == selectedDiscardCard)
            // Discard selection should feel instant: choose on touch-down, play on touch-up.
            cardView.addTarget(self, action: #selector(didTouchDownHandCard(_:)), for: .touchDown)
            cardView.addTarget(self, action: #selector(didTapHandCard(_:)), for: .touchUpInside)
            handCardViews.append(cardView)
            handRow.addArrangedSubview(cardView)

            if animateDeal {
                // Start each card below its resting position, invisible.
                cardView.alpha = 0
                cardView.transform = CGAffineTransform(translationX: 0, y: 32)
                UIView.animate(
                    withDuration: 0.22,
                    delay: Double(index) * 0.07,
                    usingSpringWithDamping: 0.78,
                    initialSpringVelocity: 0.3,
                    options: []
                ) {
                    cardView.alpha = 1
                    cardView.transform = .identity
                }
            }
        }
    }

    private func seatMarkerText(for player: Int) -> String {
        guard game.playerNames.indices.contains(player) else { return "?" }
        let name = game.playerNames[player].trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "?" }
        return String(name.prefix(1)).uppercased()
    }

    private func suitTint(_ suit: EuchreGame.Card.Suit) -> UIColor {
        suit.isRed ? theme.accentRed : .white
    }

    private func rebuildActions() {
        actionRow.arrangedSubviews.forEach { actionRow.removeArrangedSubview($0); $0.removeFromSuperview() }

        if game.isAwaitingHumanDiscard {
            let discard = makePillButton(title: "Discard")
            let canDiscard = (selectedDiscardCard != nil)
            discard.isEnabled = canDiscard
            discard.alpha = canDiscard ? 1.0 : 0.55
            discard.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                guard let card = self.selectedDiscardCard else { return }
                self.selectedDiscardCard = nil
                self.game.humanPlayCard(card)
            }, for: .touchUpInside)
            actionRow.addArrangedSubview(discard)

            let auto = makePillButton(title: "Auto Discard")
            auto.addAction(UIAction { [weak self] _ in
                self?.selectedDiscardCard = nil
                self?.game.humanAutoDiscard()
            }, for: .touchUpInside)
            actionRow.addArrangedSubview(auto)
            return
        }

        if game.showAloneToggle {
            let alone = makePillButton(title: game.aloneToggleOn ? "Solo ✓" : "Solo")
            alone.addTarget(self, action: #selector(didToggleAlone), for: .touchUpInside)
            actionRow.addArrangedSubview(alone)
        }

        for action in game.availableHumanButtons() {
            let title = action.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            let button = makePillButton(title: title)
            button.addAction(UIAction { [weak self] _ in
                self?.performHumanAction(action)
            }, for: .touchUpInside)
            actionRow.addArrangedSubview(button)
        }
    }

    private func performHumanAction(_ action: EuchreGame.HumanButton) {
        switch action.kind {
        case .pass:
            game.humanPass()
        case .orderUp:
            game.humanOrderUp(alone: game.aloneToggleOn)
        case .callSuit(let suit):
            game.humanCallSuit(suit, alone: game.aloneToggleOn)
        case .autoDiscard:
            game.humanAutoDiscard()
        case .newHand:
            game.startNextHand()
        case .newGame:
            game.startNewGame()
        }
    }

    @objc private func didToggleAlone() {
        game.aloneToggleOn.toggle()
        render()
    }

    @objc private func didTapHandCard(_ sender: CardView) {
        guard let card = sender.card else { return }
        if game.isAwaitingHumanDiscard { return }
        let selectable = Set(game.selectableCardsForHuman())
        guard selectable.contains(card) else {
            showIllegalPlayFeedback()
            return
        }
        cancelSuggestion()
        // Capture the card view's screen position so we can animate it flying to the table.
        if let cv = handCardViews.first(where: { $0.card == card }) {
            pendingPlaySourceRect = cv.convert(cv.bounds, to: tableContainer)
        }
        game.humanPlayCard(card)
    }

    @objc private func didTouchDownHandCard(_ sender: CardView) {
        guard let card = sender.card else { return }
        guard game.isAwaitingHumanDiscard else { return }
        let selectable = Set(game.selectableCardsForHuman())
        guard selectable.contains(card) else {
            showIllegalPlayFeedback()
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if selectedDiscardCard == card {
            selectedDiscardCard = nil
        } else {
            selectedDiscardCard = card
        }
        render()
    }

    private func makePillButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        button.titleLabel?.lineBreakMode = .byClipping
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.backgroundColor = theme.pillBackground
        button.layer.cornerRadius = 22
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        button.layer.borderWidth = 1
        button.layer.borderColor = theme.pillBorder.cgColor
        return button
    }

    private func showIllegalPlayFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        UIView.animate(withDuration: 0.08, animations: {
            self.statusLabel.textColor = self.theme.accentRed
        }, completion: { _ in
            UIView.animate(withDuration: 0.18) {
                self.statusLabel.textColor = self.theme.mutedText
            }
        })

        let legal = self.handCardViews.filter { $0.isSelectable }
        for view in legal {
            UIView.animate(withDuration: 0.10, animations: {
                view.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            }, completion: { _ in
                UIView.animate(withDuration: 0.14) {
                    view.transform = .identity
                }
            })
        }
    }

    // MARK: - Trump Suit Flash

    private func buildTrumpFlash() {
        trumpFlashLabel.numberOfLines = 0
        trumpFlashLabel.textAlignment = .center
        trumpFlashLabel.alpha = 0
        trumpFlashLabel.isUserInteractionEnabled = false
        trumpFlashLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(trumpFlashLabel)
        NSLayoutConstraint.activate([
            trumpFlashLabel.centerXAnchor.constraint(equalTo: tableContainer.centerXAnchor),
            trumpFlashLabel.centerYAnchor.constraint(equalTo: tableContainer.centerYAnchor),
        ])
    }

    private func flashTrumpSuit(_ suit: EuchreGame.Card.Suit) {
        let color: UIColor = suit.isRed ? theme.accentRed : .white
        let wordAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: color.withAlphaComponent(0.65),
        ]
        let symbolAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 64, weight: .bold),
            .foregroundColor: color,
        ]
        let text = NSMutableAttributedString(string: "Trump\n", attributes: wordAttrs)
        text.append(NSAttributedString(string: suit.symbol, attributes: symbolAttrs))
        trumpFlashLabel.attributedText = text
        trumpFlashLabel.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        trumpFlashLabel.alpha = 0

        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8, options: []) {
            self.trumpFlashLabel.transform = .identity
            self.trumpFlashLabel.alpha = 1
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) {
                    self?.trumpFlashLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    self?.trumpFlashLabel.alpha = 0
                } completion: { _ in
                    self?.trumpFlashLabel.transform = .identity
                }
            }
        }
    }

    // MARK: - Partner Speech Bubble

    private func buildPartnerBubble() {
        partnerBubble.backgroundColor = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
        partnerBubble.layer.cornerRadius = 14
        partnerBubble.layer.borderWidth = 1
        partnerBubble.layer.borderColor = UIColor(white: 0.30, alpha: 1).cgColor
        partnerBubble.alpha = 0
        partnerBubble.isUserInteractionEnabled = false

        partnerBubbleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        partnerBubbleLabel.textColor = .white
        partnerBubbleLabel.textAlignment = .center
        partnerBubbleLabel.numberOfLines = 2
        partnerBubbleLabel.translatesAutoresizingMaskIntoConstraints = false

        partnerBubble.addSubview(partnerBubbleLabel)
        NSLayoutConstraint.activate([
            partnerBubbleLabel.topAnchor.constraint(equalTo: partnerBubble.topAnchor, constant: 8),
            partnerBubbleLabel.bottomAnchor.constraint(equalTo: partnerBubble.bottomAnchor, constant: -8),
            partnerBubbleLabel.leadingAnchor.constraint(equalTo: partnerBubble.leadingAnchor, constant: 14),
            partnerBubbleLabel.trailingAnchor.constraint(equalTo: partnerBubble.trailingAnchor, constant: -14),
        ])
    }

    /// Shows a speech bubble from the partner for ~3 seconds, then fades out.
    /// Safe to call from any render pass — dismisses any prior bubble cleanly.
    func showPartnerDialog(_ text: String, delay: TimeInterval = 0) {
        partnerBubbleTimer?.invalidate()
        partnerBubbleTimer = nil

        guard !text.isEmpty else { return }

        let show = { [weak self] in
            guard let self else { return }
            self.partnerBubbleLabel.text = text
            self.partnerBubble.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.72,
                initialSpringVelocity: 0.4,
                options: []
            ) {
                self.partnerBubble.alpha = 1
                self.partnerBubble.transform = .identity
            }
            self.partnerBubbleTimer = Timer.scheduledTimer(withTimeInterval: 3.2, repeats: false) { [weak self] _ in
                UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
                    self?.partnerBubble.alpha = 0
                }
            }
        }

        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: show)
        } else {
            show()
        }
    }

    private func dismissPartnerBubble() {
        partnerBubbleTimer?.invalidate()
        partnerBubbleTimer = nil
        partnerBubble.alpha = 0
    }

    // MARK: - Euchre / March Banner

    private func buildBanner() {
        bannerView.backgroundColor = theme.surface
        bannerView.layer.cornerRadius = 14
        bannerView.layer.borderWidth = 1
        bannerView.layer.borderColor = theme.pillBorder.cgColor
        bannerView.alpha = 0
        bannerView.isUserInteractionEnabled = false
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        bannerLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        bannerLabel.textColor = .white
        bannerLabel.textAlignment = .center
        bannerLabel.translatesAutoresizingMaskIntoConstraints = false

        bannerView.addSubview(bannerLabel)
        view.addSubview(bannerView) // sits on top of tableContainer

        NSLayoutConstraint.activate([
            bannerLabel.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 14),
            bannerLabel.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: -14),
            bannerLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 24),
            bannerLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -24),

            bannerView.centerXAnchor.constraint(equalTo: tableContainer.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: tableContainer.centerYAnchor),
        ])
    }

    /// Returns the banner text for a special hand outcome, or nil for an ordinary win.
    private func handOutcomeBannerText() -> String? {
        guard let makerIndex = game.makerPlayerToDisplay else { return nil }
        let makerTeam   = makerIndex % 2
        let makerTricks = game.tricksWonByTeam[makerTeam]
        if makerTricks < 3  { return "Euchre!" }
        if makerTricks == 5 { return "March!" }
        return nil
    }

    private func showBanner(_ text: String) {
        bannerLabel.text = text
        bannerView.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
        bannerView.alpha = 0

        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.bannerView.transform = .identity
            self.bannerView.alpha = 1
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                UIView.animate(withDuration: 0.20, delay: 0, options: [.curveEaseIn]) {
                    self?.bannerView.alpha = 0
                }
            }
        }
    }

    // MARK: - Card Animations

    // MARK: Trick sweep

    /// Schedules the trick-sweep animation to fire after a brief pause so players can
    /// absorb the winner highlight before cards disappear.
    private func scheduleTrickSweep(winner: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            guard let self else { return }
            // Bail if the game has already moved on (e.g. restored state cleared trickOver).
            guard self.game.trickWinnerPlayer == winner else { return }
            self.animateTrickSweep(to: winner)
        }
    }

    /// Animates all visible trick-card views converging on the winning player's badge,
    /// shrinking and fading as they go.
    private func animateTrickSweep(to winner: Int) {
        guard winner < playerBadges.count else { return }

        let badge = playerBadges[winner]
        let badgeRect = badge.convert(badge.bounds, to: tableContainer)
        let destCenter = CGPoint(x: badgeRect.midX, y: badgeRect.midY)

        let visibleViews = [trickNorth, trickWest, trickEast, trickSouth]
            .filter { !$0.isHidden }
        guard !visibleViews.isEmpty else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        for cardView in visibleViews {
            let dx = destCenter.x - cardView.center.x
            let dy = destCenter.y - cardView.center.y

            UIView.animate(
                withDuration: 0.32,
                delay: 0,
                options: [.curveEaseIn]
            ) {
                cardView.transform = CGAffineTransform(translationX: dx, y: dy)
                    .scaledBy(x: 0.22, y: 0.22)
                cardView.alpha = 0
            }
        }
    }

    // MARK: Card fly

    /// Flips the upcard from face-down to face-up with a horizontal fold animation.
    /// Two-phase: compress to scaleX 0 (face-down), swap content, expand back to identity (face-up).
    private func flipUpcardReveal(_ card: EuchreGame.Card) {
        upcardFlipInProgress = true
        upcardView.setCard(card, faceDown: true)
        upcardView.transform = .identity
        upcardView.isHidden = false

        UIView.animate(withDuration: 0.13, delay: 0, options: [.curveEaseIn]) {
            self.upcardView.transform = CGAffineTransform(scaleX: 0.01, y: 1.0)
        } completion: { _ in
            self.upcardView.setCard(card, faceDown: false)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UIView.animate(withDuration: 0.17, delay: 0,
                           usingSpringWithDamping: 0.70, initialSpringVelocity: 0.5,
                           options: []) {
                self.upcardView.transform = .identity
            } completion: { _ in
                self.upcardFlipInProgress = false
            }
        }
    }

    /// Animates `cardView` flying from `sourceRect` (in `tableContainer` coordinates) to its
    /// AutoLayout-determined resting position. Stays well under the 300 ms brand guideline.
    private func animateCardFly(_ cardView: CardView, from sourceRect: CGRect) {
        // The trick card views have fixed constraints, so their centers are valid immediately.
        let destCenter = cardView.center // already in tableContainer coords
        let srcCenter  = CGPoint(x: sourceRect.midX, y: sourceRect.midY)

        let dx = srcCenter.x - destCenter.x
        let dy = srcCenter.y - destCenter.y

        // Snap to the source position (invisible so there's no pop).
        cardView.alpha     = 0
        cardView.transform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: 0.88, y: 0.88)

        UIView.animate(
            withDuration: 0.26,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut]
        ) {
            cardView.transform = .identity
            cardView.alpha     = 1
        }
    }

    // MARK: - Friendly Suggestions

    private var isFriendlySuggestionsEnabled: Bool {
        UserDefaults.standard.bool(forKey: "friendlySuggestions")
    }

    private func manageSuggestionTimer() {
        let isHumanPlayTurn: Bool
        if case .playing(let turn, _) = game.phase, turn == 0 {
            isHumanPlayTurn = true
        } else {
            isHumanPlayTurn = false
        }

        guard isFriendlySuggestionsEnabled && isHumanPlayTurn else {
            cancelSuggestion()
            return
        }

        // Only start if no timer is already running.
        guard suggestionTimer == nil else { return }
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            self?.showSuggestion()
        }
    }

    private func cancelSuggestion() {
        suggestionTimer?.invalidate()
        suggestionTimer = nil
        if let cv = hintedCardView {
            UIView.animate(withDuration: 0.2) { cv.isHinted = false }
            hintedCardView = nil
        }
        guard hintPillView.alpha > 0 else { return }
        UIView.animate(withDuration: 0.2) { self.hintPillView.alpha = 0 }
    }

    private func showSuggestion() {
        suggestionTimer = nil
        guard let suggestion = game.suggestedPlayForHuman() else { return }

        // Find the CardView matching the suggested card.
        let hand = game.players[0].hand.sorted(by: { game.sortKey(for: $0) < game.sortKey(for: $1) })
        guard let idx = hand.firstIndex(of: suggestion.card), idx < handCardViews.count else { return }
        let cardView = handCardViews[idx]

        // Haptic feedback.
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        // Wiggle the card, then lift it to mark it as the suggestion.
        let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        wiggle.values = [0, -0.14, 0.14, -0.10, 0.10, -0.06, 0.06, 0]
        wiggle.keyTimes = [0, 0.1, 0.3, 0.5, 0.65, 0.78, 0.9, 1.0]
        wiggle.duration = 0.65
        wiggle.timingFunction = CAMediaTimingFunction(name: .easeOut)
        cardView.layer.add(wiggle, forKey: "suggestion_wiggle")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self, weak cardView] in
            guard let self, let cardView else { return }
            UIView.animate(withDuration: 0.25) { cardView.isHinted = true }
            self.hintedCardView = cardView
        }

        // Show hint label.
        hintLabel.text = "💡 \(suggestion.reason)"
        UIView.animate(withDuration: 0.25) { self.hintPillView.alpha = 1 }
    }
}

// MARK: - Theme + Views

private struct Theme {
    // Offsuit-inspired: near-black slate background, soft surfaces, neon accent.
    let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
    let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
    let cardBackground = UIColor(white: 0.985, alpha: 1)
    let mutedText = UIColor(white: 0.72, alpha: 1)
    let accent = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)
    let accentRed = UIColor(red: 0.98, green: 0.35, blue: 0.43, alpha: 1)
    let crown = UIColor(red: 0.98, green: 0.84, blue: 0.35, alpha: 1)
    let ink = UIColor(white: 0.12, alpha: 1)
    let pillBackground = UIColor(red: 22/255, green: 28/255, blue: 38/255, alpha: 1)
    let pillBorder = UIColor(white: 0.28, alpha: 1)
    let highlightBorder = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 0.65)
}

private final class BadgeView: UIView {
    var theme = Theme() { didSet { updateTheme() } }
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 14
        layer.borderWidth = 1
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
        updateTheme()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setText(_ text: String, tint: UIColor? = nil) {
        label.text = text
        if let tint {
            label.textColor = tint
            layer.borderColor = tint.withAlphaComponent(0.35).cgColor
        } else {
            updateTheme()
        }
    }

    private func updateTheme() {
        backgroundColor = theme.surface
        layer.borderColor = theme.pillBorder.cgColor
        label.textColor = .white
    }
}

private final class PlayerBadgeView: UIView {
    private let theme: Theme
    private let avatarContainer = UIView()
    private let avatar = UIView()
    private let crown = UIImageView()
    private let makerFlag = UIImageView()
    private let initials = UILabel()
    private let nameLabel = UILabel()
    private let scoreLabel = UILabel()
    private let tricksLabel = UILabel()
    private var tricksHeight: NSLayoutConstraint?
    private var teamColor: UIColor = UIColor(white: 0.92, alpha: 1)
    private var isDealer: Bool = false
    private var isMaker: Bool = false
    private var makerTint: UIColor?
    private var isTurn: Bool = false
    private var isWinning: Bool = false
    private var crownCenterX: NSLayoutConstraint?
    private var crownTrailingToCenter: NSLayoutConstraint?
    private var flagCenterX: NSLayoutConstraint?
    private var flagLeadingToCenter: NSLayoutConstraint?

    init(theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.widthAnchor.constraint(equalToConstant: 46).isActive = true
        // Extra vertical room so the crown/flag sit above the avatar with a small gap.
        avatarContainer.heightAnchor.constraint(equalToConstant: 64).isActive = true

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 42).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 42).isActive = true
        avatar.layer.cornerRadius = 21
        avatar.backgroundColor = UIColor(white: 0.12, alpha: 1)
        avatar.layer.borderWidth = 1
        avatar.layer.borderColor = UIColor(white: 0.25, alpha: 1).cgColor

        avatarContainer.addSubview(avatar)
        NSLayoutConstraint.activate([
            avatar.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatar.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
        ])

        crown.translatesAutoresizingMaskIntoConstraints = false
        crown.image = UIImage(systemName: "crown.fill")
        crown.tintColor = UIColor(white: 0.92, alpha: 1)
        crown.contentMode = .scaleAspectFit
        crown.isHidden = true
        avatarContainer.addSubview(crown)
        crownCenterX = crown.centerXAnchor.constraint(equalTo: avatar.centerXAnchor)
        crownTrailingToCenter = crown.trailingAnchor.constraint(equalTo: avatar.centerXAnchor, constant: -2)
        NSLayoutConstraint.activate([
            crown.topAnchor.constraint(equalTo: avatarContainer.topAnchor, constant: 0),
            crown.widthAnchor.constraint(equalToConstant: 16),
            crown.heightAnchor.constraint(equalToConstant: 16),
            crownCenterX!,
        ])

        makerFlag.translatesAutoresizingMaskIntoConstraints = false
        makerFlag.image = UIImage(systemName: "flag.fill")
        makerFlag.tintColor = UIColor(white: 0.92, alpha: 1)
        makerFlag.contentMode = .scaleAspectFit
        makerFlag.isHidden = true
        avatarContainer.addSubview(makerFlag)
        flagCenterX = makerFlag.centerXAnchor.constraint(equalTo: avatar.centerXAnchor)
        flagLeadingToCenter = makerFlag.leadingAnchor.constraint(equalTo: avatar.centerXAnchor, constant: 2)
        NSLayoutConstraint.activate([
            makerFlag.topAnchor.constraint(equalTo: avatarContainer.topAnchor, constant: 0),
            makerFlag.widthAnchor.constraint(equalToConstant: 16),
            makerFlag.heightAnchor.constraint(equalToConstant: 16),
            flagCenterX!,
        ])

        initials.textColor = .white
        initials.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        initials.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initials)
        NSLayoutConstraint.activate([
            initials.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            initials.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
        ])

        nameLabel.textColor = theme.mutedText
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)

        scoreLabel.textColor = .white
        scoreLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)

        tricksLabel.textColor = theme.mutedText
        tricksLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        tricksLabel.alpha = 0.0
        tricksLabel.text = "Tricks 0"
        tricksHeight = tricksLabel.heightAnchor.constraint(equalToConstant: 14)
        tricksHeight?.isActive = true

        let labels = UIStackView(arrangedSubviews: [nameLabel, scoreLabel, tricksLabel])
        labels.axis = .vertical
        labels.alignment = .center
        labels.spacing = 0

        stack.addArrangedSubview(avatarContainer)
        stack.addArrangedSubview(labels)

        setTeam(0)
        updateHeaderIconsLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setName(_ name: String) {
        nameLabel.text = name
        // Default fallback; prefer calling `setEmoji` from the controller.
        initials.text = String(name.prefix(1))
    }

    func setEmoji(_ emoji: String) {
        initials.text = emoji
    }

    func setScore(_ score: Int) {
        scoreLabel.text = "\(score)"
    }

    func bounce() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UIView.animate(withDuration: 0.10, delay: 0, options: [.curveEaseOut]) {
            self.transform = CGAffineTransform(scaleX: 1.14, y: 1.14)
        } completion: { _ in
            UIView.animate(withDuration: 0.20, delay: 0,
                           usingSpringWithDamping: 0.45, initialSpringVelocity: 0.6,
                           options: []) {
                self.transform = .identity
            }
        }
    }

    func setTricks(_ tricks: Int, visible: Bool) {
        tricksLabel.text = "Tricks \(tricks)"
        tricksLabel.alpha = visible ? 1.0 : 0.0
    }

    func setTeam(_ team: Int) {
        _ = team
        // Monochrome avatars (de-emphasize team colors; draw attention to cards).
        teamColor = UIColor(white: 0.92, alpha: 1)
        avatar.backgroundColor = UIColor(white: 0.12, alpha: 1)
        updateAvatarBorder()
        updateHeaderIconsLayout()
    }

    func setMaker(_ isMaker: Bool, tint: UIColor?) {
        self.isMaker = isMaker
        self.makerTint = tint
        updateHeaderIconsLayout()
    }

    func setDealer(_ isDealer: Bool) {
        self.isDealer = isDealer
        updateHeaderIconsLayout()
    }

    func setActive(_ active: Bool) {
        avatar.alpha = active ? 1.0 : 0.25
        crown.alpha = active ? 1.0 : 0.25
        makerFlag.alpha = active ? 1.0 : 0.25
        nameLabel.alpha = active ? 1.0 : 0.25
        scoreLabel.alpha = active ? 1.0 : 0.25
        tricksLabel.alpha = active ? 1.0 : 0.25
    }

    func setTurn(_ isTurn: Bool) {
        self.isTurn = isTurn
        updateAvatarBorder()
    }

    func setWinning(_ isWinning: Bool) {
        self.isWinning = isWinning
        updateAvatarBorder()
    }

    private func updateAvatarBorder() {
        // Priority: winning highlight > turn highlight > default border.
        if isWinning {
            avatar.layer.borderWidth = 3
            avatar.layer.borderColor = theme.accent.withAlphaComponent(0.90).cgColor
        } else if isTurn {
            avatar.layer.borderWidth = 2
            avatar.layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor
        } else {
            avatar.layer.borderWidth = 1
            avatar.layer.borderColor = UIColor(white: 0.30, alpha: 1).cgColor
        }
    }

    private func updateHeaderIconsLayout() {
        crown.isHidden = !isDealer
        makerFlag.isHidden = !isMaker
        _ = makerTint
        makerFlag.tintColor = UIColor(white: 0.92, alpha: 1)

        let showBoth = isDealer && isMaker
        crownCenterX?.isActive = !showBoth
        crownTrailingToCenter?.isActive = showBoth
        flagCenterX?.isActive = !showBoth
        flagLeadingToCenter?.isActive = showBoth
    }
}

private final class CardView: UIControl {
    var theme = Theme() { didSet { updateTheme() } }
    private let valueLabel = UILabel()
    private let suitLabel = UILabel()
    private let patternLabel = UILabel()
    private let markerLabel = UILabel()

    fileprivate(set) var card: EuchreGame.Card?
    var isSelectable: Bool = false { didSet { updateSelectable() } }
    var isChosen: Bool = false { didSet { updateSelectable() } }
    var isWinnerHighlighted: Bool = false { didSet { updateSelectable() } }
    var isLeadHighlighted: Bool = false { didSet { updateSelectable() } }
    var isHinted: Bool = false { didSet { updateSelectable() } }

    override var isHighlighted: Bool {
        didSet {
            let target = isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            UIView.animate(withDuration: 0.08) { self.transform = target }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = theme.cardBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.14
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 8)

        markerLabel.translatesAutoresizingMaskIntoConstraints = false
        markerLabel.isUserInteractionEnabled = false
        markerLabel.textColor = UIColor(white: 0.92, alpha: 1)
        markerLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        markerLabel.isHidden = true
        addSubview(markerLabel)
        NSLayoutConstraint.activate([
            markerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            markerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])

        valueLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        suitLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        valueLabel.isUserInteractionEnabled = false
        suitLabel.isUserInteractionEnabled = false

        let stack = UIStackView(arrangedSubviews: [valueLabel, suitLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        // Ensure taps on the text still register as taps on the card control.
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        patternLabel.text = "/////////"
        patternLabel.textColor = UIColor(white: 0.7, alpha: 1)
        patternLabel.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .semibold)
        patternLabel.transform = CGAffineTransform(rotationAngle: -.pi / 8)
        patternLabel.isHidden = true
        patternLabel.isUserInteractionEnabled = false
        addSubview(patternLabel)
        patternLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            patternLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            patternLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        updateTheme()
        updateSelectable()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCard(_ card: EuchreGame.Card, faceDown: Bool) {
        self.card = card
        if faceDown {
            valueLabel.isHidden = true
            suitLabel.isHidden = true
            patternLabel.isHidden = false
            layer.borderWidth = 2
            layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor
        } else {
            valueLabel.isHidden = false
            suitLabel.isHidden = false
            patternLabel.isHidden = true
            valueLabel.text = card.rank.short
            suitLabel.text = card.suit.symbol
            let color = card.suit.isRed ? theme.accentRed : theme.ink
            valueLabel.textColor = color
            suitLabel.textColor = color
            layer.borderWidth = 0
        }
    }

    private func updateTheme() {
        backgroundColor = theme.cardBackground
    }

    func setPlayerMarker(text: String) {
        markerLabel.isHidden = false
        markerLabel.text = text
    }

    func clearPlayerMarker() {
        markerLabel.isHidden = true
        markerLabel.text = nil
    }

    private func updateSelectable() {
        if isWinnerHighlighted {
            layer.borderWidth = 4
            layer.borderColor = theme.accent.withAlphaComponent(0.90).cgColor
            alpha = 1.0
            transform = .identity
            return
        }

        if isLeadHighlighted {
            layer.borderWidth = 3
            layer.borderColor = theme.pillBorder.withAlphaComponent(0.90).cgColor
            alpha = 1.0
            transform = .identity
            return
        }

        if isChosen {
            layer.borderWidth = 3
            layer.borderColor = theme.accentRed.withAlphaComponent(0.95).cgColor
            alpha = 1.0
            transform = .identity
            return
        }

        if isHinted {
            layer.borderWidth = 3
            layer.borderColor = UIColor(red: 0.98, green: 0.84, blue: 0.35, alpha: 0.95).cgColor
            alpha = 1.0
            transform = CGAffineTransform(translationX: 0, y: -10)
            return
        }

        let border = isSelectable ? theme.highlightBorder : UIColor.clear
        layer.borderWidth = isSelectable ? 2 : 0
        layer.borderColor = border.cgColor
        alpha = isSelectable ? 1.0 : 0.55
        transform = .identity
    }
}

// MARK: - Euchre Engine (minimal, local)

private final class EuchreGame {

    struct Card: Hashable, Codable {
        enum Suit: String, CaseIterable, Codable {
            case clubs, diamonds, hearts, spades

            var isRed: Bool { self == .hearts || self == .diamonds }
            var symbol: String {
                switch self {
                case .clubs: return "♣"
                case .diamonds: return "♦"
                case .hearts: return "♥"
                case .spades: return "♠"
                }
            }

            var sameColorOther: Suit {
                switch self {
                case .clubs: return .spades
                case .spades: return .clubs
                case .hearts: return .diamonds
                case .diamonds: return .hearts
                }
            }
        }

        enum Rank: Int, CaseIterable, Codable {
            case nine = 9, ten = 10, jack = 11, queen = 12, king = 13, ace = 14

            var short: String {
                switch self {
                case .nine: return "9"
                case .ten: return "10"
                case .jack: return "J"
                case .queen: return "Q"
                case .king: return "K"
                case .ace: return "A"
                }
            }
        }

        let suit: Suit
        let rank: Rank
    }

    struct Player {
        var hand: [Card] = []
        let isHuman: Bool
    }

    enum Phase: Equatable, Codable {
        case makingTrumpRound1(turn: Int)
        case makingTrumpRound2(turn: Int)
        case dealerDiscard
        case playing(turn: Int, trickIndex: Int)
        case trickOver(winner: Int, trickIndex: Int)
        case handOver

        private enum CodingKeys: String, CodingKey {
            case kind
            case turn
            case trickIndex
            case winner
        }

        private enum Kind: String, Codable {
            case makingTrumpRound1
            case makingTrumpRound2
            case dealerDiscard
            case playing
            case trickOver
            case handOver
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .kind)
            switch kind {
            case .makingTrumpRound1:
                let turn = try container.decode(Int.self, forKey: .turn)
                self = .makingTrumpRound1(turn: turn)
            case .makingTrumpRound2:
                let turn = try container.decode(Int.self, forKey: .turn)
                self = .makingTrumpRound2(turn: turn)
            case .dealerDiscard:
                self = .dealerDiscard
            case .playing:
                let turn = try container.decode(Int.self, forKey: .turn)
                let trickIndex = try container.decode(Int.self, forKey: .trickIndex)
                self = .playing(turn: turn, trickIndex: trickIndex)
            case .trickOver:
                let winner = try container.decode(Int.self, forKey: .winner)
                let trickIndex = try container.decode(Int.self, forKey: .trickIndex)
                self = .trickOver(winner: winner, trickIndex: trickIndex)
            case .handOver:
                self = .handOver
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .makingTrumpRound1(let turn):
                try container.encode(Kind.makingTrumpRound1, forKey: .kind)
                try container.encode(turn, forKey: .turn)
            case .makingTrumpRound2(let turn):
                try container.encode(Kind.makingTrumpRound2, forKey: .kind)
                try container.encode(turn, forKey: .turn)
            case .dealerDiscard:
                try container.encode(Kind.dealerDiscard, forKey: .kind)
            case .playing(let turn, let trickIndex):
                try container.encode(Kind.playing, forKey: .kind)
                try container.encode(turn, forKey: .turn)
                try container.encode(trickIndex, forKey: .trickIndex)
            case .trickOver(let winner, let trickIndex):
                try container.encode(Kind.trickOver, forKey: .kind)
                try container.encode(winner, forKey: .winner)
                try container.encode(trickIndex, forKey: .trickIndex)
            case .handOver:
                try container.encode(Kind.handOver, forKey: .kind)
            }
        }
    }

    enum HumanButtonKind: Equatable {
        case pass
        case orderUp
        case callSuit(Card.Suit)
        case autoDiscard
        case newHand
        case newGame
    }

    struct HumanButton: Equatable {
        let title: String
        let kind: HumanButtonKind
    }

    struct TrickPlay: Codable, Hashable {
        let player: Int
        let card: Card
    }

    var onUpdate: (() -> Void)?

    private(set) var players: [Player] = [
        Player(isHuman: true),
        Player(isHuman: false),
        Player(isHuman: false),
        Player(isHuman: false),
    ]

    private(set) var dealer: Int = 0
    private(set) var scores: [Int] = [0, 0] // teams: 0 = (0,2), 1 = (1,3)
    private(set) var winningTeam: Int?

    private(set) var upcard: Card?
    private(set) var trump: Card.Suit?
    private var deck: [Card] = []

    private var pickedUpCard: Card?
    private var maker: Int?
    private var makerAlone: Bool = false
    private var active: [Bool] = [true, true, true, true]

    private var trickLeader: Int = 1
    private var trickIndex: Int = 0
    private var trickPlays: [TrickPlay] = []
    private(set) var tricksWonByTeam: [Int] = [0, 0]
    private var ledSuit: Card.Suit?
    private var leadPlay: TrickPlay?
    private var lastTrickPlays: [TrickPlay] = []
    private var lastTrickWinner: Int?
    private var lastTrickLeadPlay: TrickPlay?

    private var didScheduleAI = false
    private var didScheduleNextHand = false
    private var didScheduleTrickAdvance = false
    private(set) var handSerial: Int = 0

    var aloneToggleOn: Bool = false
    var playerNames: [String] = ["You", "W", "N", "E"]

    var humanName: String = "You" {
        didSet {
            if playerNames.isEmpty { playerNames = ["You", "W", "N", "E"] }
            if playerNames.count < 4 { playerNames = Array(playerNames.prefix(4)) + Array(repeating: "?", count: max(0, 4 - playerNames.count)) }
            playerNames[0] = humanName
        }
    }

    func setBotNames(_ names: [String]) {
        if playerNames.count != 4 { playerNames = ["You", "W", "N", "E"] }
        let bots = Array(names.prefix(3))
        if bots.count == 3 {
            playerNames[1] = bots[0]
            playerNames[2] = bots[1]
            playerNames[3] = bots[2]
        }
        playerNames[0] = humanName
    }

    var statusText: String {
        switch phase {
        case .makingTrumpRound1(let turn):
            return "Make trump (round 1). Upcard is \(upcard?.suit.symbol ?? "?").\nPlayer \(seatName(turn)) to act."
        case .makingTrumpRound2(let turn):
            return "Make trump (round 2). Can't pick \(bannedSuit?.symbol ?? "?").\nPlayer \(seatName(turn)) to act."
        case .dealerDiscard:
            return "Dealer picks up \(upcard?.rank.short ?? "?")\(upcard?.suit.symbol ?? "?").\nTap a card to discard (upcard locked)."
        case .playing(let turn, let trick):
            let trumpText = trump.map { $0.symbol } ?? "?"
            return "Trump: \(trumpText). Trick \(trick + 1) of 5.\nPlayer \(seatName(turn)) to play."
        case .trickOver(let winner, let trick):
            let trumpText = trump.map { $0.symbol } ?? "?"
            return "Trump: \(trumpText). Trick \(trick + 1) won by \(seatName(winner))."
        case .handOver:
            let trumpText = trump.map { $0.symbol } ?? "?"
            if let winningTeam {
                return "Game over. Team \(teamName(winningTeam)) wins \(scores[0])–\(scores[1])."
            }
            return "Hand over. Trump was \(trumpText). Makers: \(maker.map(seatName) ?? "?")."
        }
    }

    var currentTrick: [TrickPlay] {
        switch phase {
        case .trickOver:
            return lastTrickPlays
        default:
            return trickPlays
        }
    }

    var leadPlayToDisplay: TrickPlay? {
        switch phase {
        case .trickOver:
            return lastTrickLeadPlay
        case .playing:
            return leadPlay
        default:
            return nil
        }
    }

    var trickWinnerPlayer: Int? {
        if case .trickOver = phase { return lastTrickWinner }
        return nil
    }

    var currentWinningPlayer: Int? {
        guard case .playing = phase else { return nil }
        guard let trump else { return nil }
        guard !trickPlays.isEmpty else { return nil }
        let led = ledSuit ?? effectiveSuit(for: trickPlays[0].card, trump: trump)
        return trickWinner(trickPlays, ledSuit: led, trump: trump)
    }

    var makerPlayerToDisplay: Int? { maker }

    var ledSuitToDisplay: Card.Suit? {
        switch phase {
        case .playing, .trickOver:
            return ledSuit
        default:
            return nil
        }
    }

    var currentTurnPlayer: Int? {
        switch phase {
        case .makingTrumpRound1(let turn): return turn
        case .makingTrumpRound2(let turn): return turn
        case .dealerDiscard: return dealer
        case .playing(let turn, _): return turn
        case .trickOver: return nil
        case .handOver: return nil
        }
    }

    var isUpcardFaceDown: Bool {
        // Deprecated: use `shouldShowUpcard` for UI.
        if case .playing = phase { return true }
        if case .handOver = phase { return true }
        return false
    }

    var shouldShowUpcard: Bool {
        switch phase {
        case .makingTrumpRound1, .makingTrumpRound2, .dealerDiscard:
            return true
        case .playing, .trickOver, .handOver:
            return false
        }
    }

    var showAloneToggle: Bool {
        switch phase {
        case .makingTrumpRound1, .makingTrumpRound2:
            return currentTurnPlayer == 0
        default:
            return false
        }
    }

    var shouldShowTrickTally: Bool {
        switch phase {
        case .playing, .trickOver, .handOver:
            return true
        default:
            return false
        }
    }

    var isAwaitingHumanDiscard: Bool {
        phase == .dealerDiscard && dealer == 0
    }

    private(set) var phase: Phase = .makingTrumpRound1(turn: 1)
    private var bannedSuit: Card.Suit? { upcard?.suit }

    func startNewHand() {
        if winningTeam != nil { return }
        handSerial += 1
        didScheduleAI = false
        didScheduleNextHand = false
        didScheduleTrickAdvance = false
        aloneToggleOn = false
        maker = nil
        makerAlone = false
        pickedUpCard = nil
        tricksWonByTeam = [0, 0]
        trickIndex = 0
        trickPlays = []
        ledSuit = nil
        leadPlay = nil
        lastTrickPlays = []
        lastTrickWinner = nil
        lastTrickLeadPlay = nil
        trump = nil
        active = [true, true, true, true]

        deck = makeDeck24().shuffled()
        for i in 0..<4 { players[i].hand = [] }

        // Deal 5 each starting left of dealer.
        for round in 0..<5 {
            for offset in 1...4 {
                let p = (dealer + offset) % 4
                players[p].hand.append(deck.removeFirst())
            }
            _ = round
        }

        upcard = deck.removeFirst()
        phase = .makingTrumpRound1(turn: (dealer + 1) % 4)

        notify()
    }

    func startNextHand() {
        guard winningTeam == nil else { return }
        if didScheduleNextHand { return }
        didScheduleNextHand = true
        dealer = (dealer + 1) % 4
        startNewHand()
    }

    func startNewGame() {
        scores = [0, 0]
        // Start with you acting first (left of dealer), so you immediately see Pass/Order Up.
        dealer = 3
        winningTeam = nil
        startNewHand()
    }

    func team(of player: Int) -> Int { player % 2 }

    func isPlayerActive(_ index: Int) -> Bool { active[index] }

    func selectableCardsForHuman() -> [Card] {
        guard isHumansTurn else { return [] }
        switch phase {
        case .dealerDiscard:
            if let pickedUpCard {
                return players[0].hand.filter { $0 != pickedUpCard }
            }
            return players[0].hand
        case .playing:
            return legalPlays(for: 0)
        default:
            return []
        }
    }

    func availableHumanButtons() -> [HumanButton] {
        guard currentTurnPlayer == 0 else { return [] }

        switch phase {
        case .makingTrumpRound1:
            return [
                HumanButton(title: "Pass", kind: .pass),
                HumanButton(title: "Order Up", kind: .orderUp),
            ]
        case .makingTrumpRound2:
            let banned = bannedSuit
            let suits = Card.Suit.allCases.filter { $0 != banned }
            var buttons: [HumanButton] = [HumanButton(title: "Pass", kind: .pass)]
            for suit in suits {
                buttons.append(HumanButton(title: suit.symbol, kind: .callSuit(suit)))
            }
            return buttons
        case .dealerDiscard:
            return [HumanButton(title: "Auto Discard", kind: .autoDiscard)]
        case .handOver:
            if winningTeam != nil {
                return [HumanButton(title: "New Game", kind: .newGame)]
            }
            return [HumanButton(title: "Next Hand", kind: .newHand)]
        default:
            return []
        }
    }

    func humanPass() {
        guard currentTurnPlayer == 0 else { return }
        aloneToggleOn = false
        advanceBidding(pass: true)
    }

    func humanOrderUp(alone: Bool) {
        guard currentTurnPlayer == 0 else { return }
        aloneToggleOn = false
        acceptUpcard(by: 0, alone: alone)
    }

    func humanCallSuit(_ suit: Card.Suit, alone: Bool) {
        guard currentTurnPlayer == 0 else { return }
        aloneToggleOn = false
        nameTrump(suit: suit, by: 0, alone: alone)
    }

    func humanAutoDiscard() {
        guard phase == .dealerDiscard, dealer == 0 else { return }
        let discard = chooseDiscard(for: 0, trump: trump)
        discardFromDealer(discard)
    }

    func humanPlayCard(_ card: Card) {
        guard isHumansTurn else { return }
        switch phase {
        case .dealerDiscard:
            discardFromDealer(card)
        case .playing(let turn, _):
            guard turn == 0 else { return }
            guard legalPlays(for: 0).contains(card) else { return }
            play(card: card, by: 0)
        default:
            break
        }
    }

    func kickAIIfNeeded() {
        guard !didScheduleAI else { return }
        guard let turn = currentTurnPlayer, turn != 0 else { return }
        didScheduleAI = true

        // Bidding gets a longer beat so the player can read what each bot decides.
        // The first trick of a hand gets an extra pause so the trump announcement can land.
        let delay: Double
        switch phase {
        case .makingTrumpRound1, .makingTrumpRound2:
            delay = 0.85
        case .playing(_, let trickIndex) where trickIndex == 0:
            delay = 1.5
        default:
            delay = 0.55
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.didScheduleAI = false
            self.performAIMove(for: turn)
        }
    }

    func sortKey(for card: Card) -> Int {
        let suitOrder: [Card.Suit] = [.clubs, .spades, .hearts, .diamonds]
        let suitIndex = suitOrder.firstIndex(of: card.suit) ?? 0
        return suitIndex * 100 + card.rank.rawValue
    }

    // MARK: - Bidding

    private var isHumansTurn: Bool { currentTurnPlayer == 0 }

    private func advanceBidding(pass: Bool) {
        switch phase {
        case .makingTrumpRound1(let turn):
            let next = nextActive(after: turn)
            if next == (dealer + 1) % 4 {
                phase = .makingTrumpRound2(turn: (dealer + 1) % 4)
            } else {
                phase = .makingTrumpRound1(turn: next)
            }
            notify()
        case .makingTrumpRound2(let turn):
            let next = nextActive(after: turn)
            if next == (dealer + 1) % 4 {
                // Everyone passed twice: gather/shuffle and next dealer deals.
                dealer = (dealer + 1) % 4
                startNewHand()
                return
            } else {
                phase = .makingTrumpRound2(turn: next)
            }
            notify()
        default:
            _ = pass
        }
    }

    private func acceptUpcard(by player: Int, alone: Bool) {
        guard let upcard else { return }
        trump = upcard.suit
        maker = player
        makerAlone = alone
        setAloneIfNeeded(maker: player, alone: alone)

        // Dealer picks up upcard and discards.
        players[dealer].hand.append(upcard)
        pickedUpCard = upcard
        self.upcard = upcard // keep for display; hidden once play starts

        if dealer == 0 {
            phase = .dealerDiscard
            notify()
        } else {
            let discard = chooseDiscard(for: dealer, trump: trump)
            discardFromDealer(discard)
        }
    }

    private func nameTrump(suit: Card.Suit, by player: Int, alone: Bool) {
        trump = suit
        maker = player
        makerAlone = alone
        setAloneIfNeeded(maker: player, alone: alone)
        pickedUpCard = nil
        beginPlay()
    }

    private func setAloneIfNeeded(maker: Int, alone: Bool) {
        active = [true, true, true, true]
        if alone {
            let partner = (maker + 2) % 4
            active[partner] = false
        }
    }

    private func discardFromDealer(_ discard: Card) {
        guard dealer >= 0 && dealer < 4 else { return }
        guard let idx = players[dealer].hand.firstIndex(of: discard) else { return }
        players[dealer].hand.remove(at: idx)
        pickedUpCard = nil
        beginPlay()
    }

    // MARK: - Play

    private func beginPlay() {
        trickIndex = 0
        trickPlays = []
        ledSuit = nil
        leadPlay = nil
        lastTrickPlays = []
        lastTrickWinner = nil
        lastTrickLeadPlay = nil
        didScheduleTrickAdvance = false

        // Opening lead: left of dealer, unless that player's partner is playing alone (then across from dealer).
        let leftOfDealer = (dealer + 1) % 4
        let acrossFromDealer = (dealer + 2) % 4
        var leader = leftOfDealer
        if !active[leftOfDealer] {
            leader = acrossFromDealer
        }

        trickLeader = leader
        phase = .playing(turn: leader, trickIndex: 0)
        notify()
    }

    private func play(card: Card, by player: Int) {
        guard let trump else { return }
        remove(card, from: player)
        trickPlays.append(TrickPlay(player: player, card: card))

        if ledSuit == nil {
            let play = TrickPlay(player: player, card: card)
            ledSuit = effectiveSuit(for: card, trump: trump)
            leadPlay = play
        }

        if trickPlays.count == activeCount() {
            let winner = trickWinner(trickPlays, ledSuit: ledSuit!, trump: trump)
            tricksWonByTeam[team(of: winner)] += 1

            // Hold the trick on-table, highlight the winner, then advance after a pause.
            lastTrickPlays = trickPlays
            lastTrickWinner = winner
            lastTrickLeadPlay = leadPlay
            phase = .trickOver(winner: winner, trickIndex: trickIndex)
            notify()
            scheduleTrickAdvanceIfNeeded()
            return
        }

        let next = nextPlayerToAct(after: player)
        phase = .playing(turn: next, trickIndex: trickIndex)
        notify()
    }

    private func scheduleTrickAdvanceIfNeeded() {
        guard !didScheduleTrickAdvance else { return }
        guard case .trickOver(let winner, let completedIndex) = phase else { return }
        didScheduleTrickAdvance = true
        let scheduledForSerial = handSerial

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            guard self.handSerial == scheduledForSerial else { return }
            guard case .trickOver = self.phase else { return }

            self.didScheduleTrickAdvance = false
            self.trickPlays = []
            self.ledSuit = nil
            self.leadPlay = nil
            self.lastTrickPlays = []
            self.lastTrickWinner = nil
            self.lastTrickLeadPlay = nil

            let nextIndex = completedIndex + 1
            if nextIndex >= 5 {
                self.scoreHand()
                self.phase = .handOver
                self.notify()
                return
            }

            self.trickIndex = nextIndex
            self.trickLeader = winner
            self.phase = .playing(turn: winner, trickIndex: nextIndex)
            self.notify()
        }
    }

    private func scoreHand() {
        guard let maker, let trump else { return }
        _ = trump

        let makerTeam = team(of: maker)
        let makerTricks = tricksWonByTeam[makerTeam]
        let defendersTeam = 1 - makerTeam
        let defendersTricks = tricksWonByTeam[defendersTeam]

        if makerTricks >= 3 {
            if makerAlone {
                // Bicycle rules: lone hand 3-4 = 1 point; 5 = 4 points.
                scores[makerTeam] += (makerTricks == 5 ? 4 : 1)
            } else {
                scores[makerTeam] += (makerTricks == 5 ? 2 : 1)
            }
        } else {
            // Euchred
            _ = defendersTricks
            scores[defendersTeam] += 2
        }

        if scores[0] >= 10 { winningTeam = 0 }
        if scores[1] >= 10 { winningTeam = 1 }
    }

    // MARK: - AI

    private func performAIMove(for player: Int) {
        guard player != 0 else { return }
        guard isPlayerActive(player) else { return }

        switch phase {
        case .makingTrumpRound1 where currentTurnPlayer == player:
            if shouldOrderUp(player: player) {
                acceptUpcard(by: player, alone: shouldGoAlone(player: player, trumpCandidate: upcard?.suit))
            } else {
                advanceBidding(pass: true)
            }
        case .makingTrumpRound2 where currentTurnPlayer == player:
            if let suit = chooseTrumpInRound2(player: player) {
                nameTrump(suit: suit, by: player, alone: shouldGoAlone(player: player, trumpCandidate: suit))
            } else {
                advanceBidding(pass: true)
            }
        case .dealerDiscard where dealer == player:
            let discard = chooseDiscard(for: player, trump: trump)
            discardFromDealer(discard)
        case .playing(let turn, _) where turn == player:
            let card = choosePlay(for: player)
            play(card: card, by: player)
        default:
            break
        }
    }

    private func shouldOrderUp(player: Int) -> Bool {
        guard let suit = upcard?.suit else { return false }
        let threshold = (player == dealer) ? 11 : 8
        return handStrength(player: player, trumpCandidate: suit) >= threshold
    }

    private func chooseTrumpInRound2(player: Int) -> Card.Suit? {
        let banned = bannedSuit
        let options = Card.Suit.allCases.filter { $0 != banned }
        let best = options
            .map { ($0, handStrength(player: player, trumpCandidate: $0)) }
            .max(by: { $0.1 < $1.1 })
        let threshold = (player == dealer) ? 11 : 9
        guard let best, best.1 >= threshold else { return nil }
        return best.0
    }

    private func shouldGoAlone(player: Int, trumpCandidate: Card.Suit?) -> Bool {
        guard let trumpCandidate else { return false }
        return handStrength(player: player, trumpCandidate: trumpCandidate) >= 13
    }

    private func handStrength(player: Int, trumpCandidate: Card.Suit) -> Int {
        var score = 0
        for card in players[player].hand {
            if isRightBower(card, trump: trumpCandidate) { score += 7; continue }
            if isLeftBower(card, trump: trumpCandidate) { score += 6; continue }
            if effectiveSuit(for: card, trump: trumpCandidate) == trumpCandidate {
                switch card.rank {
                case .ace: score += 5
                case .king: score += 4
                case .queen: score += 3
                case .jack: score += 2
                case .ten: score += 1
                case .nine: score += 1
                }
            } else if card.rank == .ace {
                score += 2
            }
        }
        return score
    }

    private func chooseDiscard(for player: Int, trump: Card.Suit?) -> Card {
        // Prefer discarding lowest non-trump; otherwise lowest trump.
        let trump = trump ?? upcard?.suit
        let hand = players[player].hand
        let sorted = hand.sorted(by: { sortKey(for: $0) < sortKey(for: $1) })
        if let trump {
            if let nonTrump = sorted.first(where: { effectiveSuit(for: $0, trump: trump) != trump && $0 != pickedUpCard }) {
                return nonTrump
            }
        }
        if let first = sorted.first(where: { $0 != pickedUpCard }) {
            return first
        }
        return sorted.first!
    }

    private func choosePlay(for player: Int) -> Card {
        guard let trump else { return players[player].hand.first! }
        let legal = legalPlays(for: player)

        // Simple: if leading, lead highest trump else highest off-suit ace, else lowest.
        let isLeading = trickPlays.isEmpty
        if isLeading {
            if let bestTrump = legal
                .filter({ effectiveSuit(for: $0, trump: trump) == trump })
                .max(by: { cardPower($0, ledSuit: trump, trump: trump) < cardPower($1, ledSuit: trump, trump: trump) }) {
                return bestTrump
            }

            if let ace = legal.first(where: { $0.rank == .ace }) {
                return ace
            }

            return legal.sorted(by: { sortKey(for: $0) < sortKey(for: $1) }).first!
        }

        // If someone played trump, try to overtrump if possible; otherwise follow suit low.
        let led = ledSuit!
        let currentWinning = trickWinner(trickPlays, ledSuit: led, trump: trump)
        let myTeam = team(of: player)
        let winningTeam = team(of: currentWinning)

        let sortedLegal = legal.sorted(by: { cardPower($0, ledSuit: led, trump: trump) < cardPower($1, ledSuit: led, trump: trump) })
        if myTeam != winningTeam {
            // Try to win: play lowest card that wins.
            for card in sortedLegal {
                let hypothetical = trickPlays + [TrickPlay(player: player, card: card)]
                if trickWinner(hypothetical, ledSuit: led, trump: trump) == player {
                    return card
                }
            }
        }
        // Otherwise lose cheaply.
        return sortedLegal.first!
    }

    // MARK: - Friendly Suggestion

    func suggestedPlayForHuman() -> (card: Card, reason: String)? {
        guard case .playing(let turn, _) = phase, turn == 0 else { return nil }
        guard let trump else { return nil }
        let card = choosePlay(for: 0)
        let reason = suggestionReason(for: card, trump: trump)
        return (card, reason)
    }

    private func suggestionReason(for card: Card, trump: Card.Suit) -> String {
        let isLeading = trickPlays.isEmpty
        let cardSuit = effectiveSuit(for: card, trump: trump)
        let isTrump = cardSuit == trump

        if isLeading {
            if isRightBower(card, trump: trump) { return "Lead the right bower — strongest card" }
            if isLeftBower(card, trump: trump)  { return "Lead the left bower — second best" }
            if isTrump                          { return "Lead trump to pull out their trumps" }
            if card.rank == .ace                { return "Lead your ace — hard to beat off-suit" }
            return "Nothing great — lead your lowest card"
        }

        let led = ledSuit ?? trump
        let myTeam = team(of: 0)
        if let winner = currentWinningPlayer, team(of: winner) == myTeam {
            return "Partner's winning — play your lowest"
        }
        if isTrump { return "Trump in to steal the trick" }
        if card.rank == .ace { return "Best shot — play your ace" }
        return "Can't win this one — dump your lowest"
    }

    // MARK: - Rules

    private func legalPlays(for player: Int) -> [Card] {
        guard let trump else { return players[player].hand }
        guard let ledSuit else { return players[player].hand }

        let hand = players[player].hand
        let follow = hand.filter { effectiveSuit(for: $0, trump: trump) == ledSuit }
        return follow.isEmpty ? hand : follow
    }

    private func trickWinner(_ plays: [TrickPlay], ledSuit: Card.Suit, trump: Card.Suit) -> Int {
        let winning = plays.max { a, b in
            cardPower(a.card, ledSuit: ledSuit, trump: trump) < cardPower(b.card, ledSuit: ledSuit, trump: trump)
        }
        return winning?.player ?? plays.first!.player
    }

    private func cardPower(_ card: Card, ledSuit: Card.Suit, trump: Card.Suit) -> Int {
        // Higher is better. Trump always beats non-trump.
        let suit = effectiveSuit(for: card, trump: trump)
        let isTrump = suit == trump

        if isRightBower(card, trump: trump) { return 10_000 }
        if isLeftBower(card, trump: trump) { return 9_000 }

        let rankOrderTrump: [Card.Rank: Int] = [
            .ace: 800,
            .king: 700,
            .queen: 600,
            .jack: 500,
            .ten: 400,
            .nine: 300
        ]

        let rankOrderPlain: [Card.Rank: Int] = [
            .ace: 80,
            .king: 70,
            .queen: 60,
            .jack: 50,
            .ten: 40,
            .nine: 30
        ]

        if isTrump {
            return 5_000 + (rankOrderTrump[card.rank] ?? 0)
        }

        if suit == ledSuit {
            return 1_000 + (rankOrderPlain[card.rank] ?? 0)
        }

        return rankOrderPlain[card.rank] ?? 0
    }

    private func effectiveSuit(for card: Card, trump: Card.Suit) -> Card.Suit {
        if isLeftBower(card, trump: trump) { return trump }
        return card.suit
    }

    private func isRightBower(_ card: Card, trump: Card.Suit) -> Bool {
        return card.rank == .jack && card.suit == trump
    }

    private func isLeftBower(_ card: Card, trump: Card.Suit) -> Bool {
        return card.rank == .jack && card.suit == trump.sameColorOther
    }

    // MARK: - Helpers

    private func remove(_ card: Card, from player: Int) {
        guard let idx = players[player].hand.firstIndex(of: card) else { return }
        players[player].hand.remove(at: idx)
    }

    private func nextActive(after player: Int) -> Int {
        var p = player
        repeat {
            p = (p + 1) % 4
        } while !active[p]
        return p
    }

    private func nextPlayerToAct(after player: Int) -> Int {
        var p = player
        repeat {
            p = (p + 1) % 4
        } while !active[p]
        return p
    }

    private func activeCount() -> Int { active.filter { $0 }.count }

    private func seatName(_ player: Int) -> String {
        guard player >= 0 && player < playerNames.count else { return "?" }
        return playerNames[player]
    }

    private func suitName(_ suit: Card.Suit) -> String {
        switch suit {
        case .clubs: return "Clubs"
        case .diamonds: return "Diamonds"
        case .hearts: return "Hearts"
        case .spades: return "Spades"
        }
    }

    private func teamName(_ team: Int) -> String {
        switch team {
        case 0:
            let partner = playerNames.count > 2 ? playerNames[2] : "N"
            return "\(humanName)+\(partner)"
        default:
            let west = playerNames.count > 1 ? playerNames[1] : "W"
            let east = playerNames.count > 3 ? playerNames[3] : "E"
            return "\(west)+\(east)"
        }
    }

    private func notify() { onUpdate?() }

    private func makeDeck24() -> [Card] {
        let ranks: [Card.Rank] = [.nine, .ten, .jack, .queen, .king, .ace]
        var cards: [Card] = []
        for suit in Card.Suit.allCases {
            for rank in ranks {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
        return cards
    }

    // MARK: - Persistence

    func persistedState(now: Date) -> EuchreGamePersistedState {
        EuchreGamePersistedState(
            version: 1,
            savedAt: now,
            dealer: dealer,
            scores: scores,
            winningTeam: winningTeam,
            upcard: upcard,
            trump: trump,
            pickedUpCard: pickedUpCard,
            maker: maker,
            makerAlone: makerAlone,
            active: active,
            trickLeader: trickLeader,
            trickIndex: trickIndex,
            trickPlays: trickPlays,
            tricksWonByTeam: tricksWonByTeam,
            ledSuit: ledSuit,
            leadPlay: leadPlay,
            lastTrickPlays: lastTrickPlays,
            lastTrickWinner: lastTrickWinner,
            lastTrickLeadPlay: lastTrickLeadPlay,
            handSerial: handSerial,
            aloneToggleOn: aloneToggleOn,
            playerNames: playerNames,
            playersHands: players.map(\.hand),
            phase: phase
        )
    }

    func applyPersistedState(_ state: EuchreGamePersistedState) {
        guard state.version == 1 else { return }
        guard state.playersHands.count == 4 else { return }
        guard state.active.count == 4 else { return }
        guard state.scores.count == 2 else { return }

        dealer = max(0, min(3, state.dealer))
        scores = state.scores
        winningTeam = state.winningTeam

        upcard = state.upcard
        trump = state.trump
        pickedUpCard = state.pickedUpCard
        maker = state.maker
        makerAlone = state.makerAlone
        active = state.active

        trickLeader = max(0, min(3, state.trickLeader))
        trickIndex = max(0, min(4, state.trickIndex))
        trickPlays = state.trickPlays
        tricksWonByTeam = state.tricksWonByTeam.count == 2 ? state.tricksWonByTeam : [0, 0]
        ledSuit = state.ledSuit
        leadPlay = state.leadPlay
        lastTrickPlays = state.lastTrickPlays
        lastTrickWinner = state.lastTrickWinner
        lastTrickLeadPlay = state.lastTrickLeadPlay

        handSerial = state.handSerial
        aloneToggleOn = state.aloneToggleOn

        if state.playerNames.count == 4 {
            playerNames = state.playerNames
        }

        for i in 0..<4 {
            players[i].hand = state.playersHands[i]
        }

        phase = state.phase

        // Reset ephemeral scheduling flags on restore.
        didScheduleAI = false
        didScheduleNextHand = false
        didScheduleTrickAdvance = false
    }
}

fileprivate struct EuchreGamePersistedState: Codable {
    let version: Int
    let savedAt: Date

    let dealer: Int
    let scores: [Int]
    let winningTeam: Int?

    let upcard: EuchreGame.Card?
    let trump: EuchreGame.Card.Suit?
    let pickedUpCard: EuchreGame.Card?

    let maker: Int?
    let makerAlone: Bool
    let active: [Bool]

    let trickLeader: Int
    let trickIndex: Int
    let trickPlays: [EuchreGame.TrickPlay]
    let tricksWonByTeam: [Int]
    let ledSuit: EuchreGame.Card.Suit?
    let leadPlay: EuchreGame.TrickPlay?

    let lastTrickPlays: [EuchreGame.TrickPlay]
    let lastTrickWinner: Int?
    let lastTrickLeadPlay: EuchreGame.TrickPlay?

    let handSerial: Int
    let aloneToggleOn: Bool
    let playerNames: [String]
    let playersHands: [[EuchreGame.Card]]
    let phase: EuchreGame.Phase
}
