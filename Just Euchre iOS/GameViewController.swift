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
    private var seatEmojis = [ProfileStore.emoji, "🦊", "🦉", "🤖"] // You, W, N, E

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.background
        buildUI()

        game.humanName = ProfileStore.name
        game.setBotNames(BotNameGenerator.nextBotNames(count: 3))
        game.onUpdate = { [weak self] in
            self?.render()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(profileDidChange), name: ProfileStore.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        restoreIfPossible()
        render()
    }

    func startNewGameFromMenu() {
        loadViewIfNeeded()

        guard DailyGameStore.canStartNewGameToday() else { return }
        DailyGameStore.markStartedToday()

        selectedDiscardCard = nil
        didRecordOutcome = false
        gameOverNudge = nil
        hasInitializedGame = true
        seatEmojis[0] = ProfileStore.emoji

        game = EuchreGame()
        game.humanName = ProfileStore.name
        game.setBotNames(BotNameGenerator.nextBotNames(count: 3))
        game.onUpdate = { [weak self] in
            self?.render()
        }

        game.startNewHand()
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

        view.addSubview(titleLabel)
        view.addSubview(headerRow)
        view.addSubview(statusContainer)
        view.addSubview(tableContainer)
        view.addSubview(actionRow)
        view.addSubview(handRow)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        tableContainer.translatesAutoresizingMaskIntoConstraints = false
        actionRow.translatesAutoresizingMaskIntoConstraints = false
        handRow.translatesAutoresizingMaskIntoConstraints = false

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
        ])

        buildHeader()
        buildTable()
    }

    private func buildHeader() {
        playerBadges = []
        headerRow.arrangedSubviews.forEach { headerRow.removeArrangedSubview($0); $0.removeFromSuperview() }

        // Seat order (clockwise): 0 = You (South), 1 = West, 2 = North, 3 = East
        seatEmojis[0] = ProfileStore.emoji
        for index in 0..<4 {
            let badge = PlayerBadgeView(theme: theme)
            badge.setName(game.playerNames[index])
            badge.setEmoji(seatEmojis[index])
            playerBadges.append(badge)
            headerRow.addArrangedSubview(badge)
        }
    }

    @objc private func profileDidChange() {
        seatEmojis[0] = ProfileStore.emoji
        game.humanName = ProfileStore.name

        if !playerBadges.isEmpty {
            playerBadges[0].setName(game.playerNames[0])
            playerBadges[0].setEmoji(ProfileStore.emoji)
        }
        render()
    }

    private func recordOutcomeIfNeeded() {
        guard !didRecordOutcome else { return }
        guard game.winningTeam != nil else { return }
        didRecordOutcome = true

        // Prevent duplicate writes if we restore a finished game from persistence.
        let today = DailyGameStore.todayKeyDate()
        if let last = GameHistoryStore.entries().first, Calendar.current.isDate(last.date, inSameDayAs: today) {
            DailyGameStore.markCompletedToday()
            GameStateStore.clear()
            return
        }

        GameHistoryStore.addResult(yourScore: game.scores[0], theirScore: game.scores[1])
        DailyGameStore.markCompletedToday()
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
        game.humanName = ProfileStore.name
        seatEmojis[0] = ProfileStore.emoji
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

        // Upcard + trump
        if let upcard = game.upcard {
            let showUpcard = game.shouldShowUpcard
            upcardView.isHidden = !showUpcard
            if showUpcard {
                upcardView.setCard(upcard, faceDown: false)
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
        } else {
            trumpBadge.isHidden = true
        }

        if let led = game.ledSuitToDisplay {
            ledBadge.isHidden = false
            ledBadge.setText("Led: \(led.symbol)")
        } else {
            ledBadge.isHidden = true
        }
        indicatorRow.isHidden = trumpBadge.isHidden && ledBadge.isHidden

        // Trick
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

        // Hand
        rebuildHand()
        rebuildActions()

        game.kickAIIfNeeded()
        persistIfNeeded()
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

    private func rebuildHand() {
        handRow.arrangedSubviews.forEach { handRow.removeArrangedSubview($0); $0.removeFromSuperview() }
        handCardViews = []

        let hand = game.players[0].hand.sorted(by: { game.sortKey(for: $0) < game.sortKey(for: $1) })
        let selectable = Set(game.selectableCardsForHuman())

        for card in hand {
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
            return
        }

        if isLeadHighlighted {
            layer.borderWidth = 3
            layer.borderColor = theme.pillBorder.withAlphaComponent(0.90).cgColor
            alpha = 1.0
            return
        }

        if isChosen {
            layer.borderWidth = 3
            layer.borderColor = theme.accentRed.withAlphaComponent(0.95).cgColor
            alpha = 1.0
            return
        }

        let border = isSelectable ? theme.highlightBorder : UIColor.clear
        layer.borderWidth = isSelectable ? 2 : 0
        layer.borderColor = border.cgColor
        alpha = isSelectable ? 1.0 : 0.55
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
    private var handSerial: Int = 0

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

    private var phase: Phase = .makingTrumpRound1(turn: 1)
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
                buttons.append(HumanButton(title: "\(suit.symbol) \(suitName(suit))", kind: .callSuit(suit)))
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
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
                self.scheduleNextHandIfNeeded()
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

    private func scheduleNextHandIfNeeded() {
        guard winningTeam == nil else { return }
        guard !didScheduleNextHand else { return }
        didScheduleNextHand = true
        let scheduledForSerial = handSerial

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self else { return }
            guard self.handSerial == scheduledForSerial else { return }
            guard self.winningTeam == nil else { return }
            guard case .handOver = self.phase else { return }
            self.dealer = (self.dealer + 1) % 4
            self.startNewHand()
        }
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
