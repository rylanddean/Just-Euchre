//
//  HomeViewController.swift
//  Just Euchre iOS
//

import GameKit
import UIKit

final class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onStartNewGame: (() -> Void)?
    var onResumeGame: (() -> Void)?

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)

    private let titleLabel = UILabel()

    // Streak row: win streak (flame) + completed streak (checkmark)
    private let streakRow = UIStackView()
    private let winStreakStack = UIStackView()
    private let winStreakIcon = UIImageView()
    private let winStreakLabel = UILabel()
    private let completedStreakStack = UIStackView()
    private let completedStreakIcon = UIImageView()
    private let completedStreakLabel = UILabel()

    private let cardsScroll = UIScrollView()
    private let cardsRow = UIStackView()
    private let primaryCard = HomeCardView(title: "New Game", subtitle: "Today's game", icon: "sparkles")
    private let shareCard = HomeCardView(title: "Share", subtitle: "Export today's result", icon: "square.and.arrow.up")

    private let nudgeLabel = UILabel()
    private var historyTitleTopToNudge: NSLayoutConstraint?
    private var historyTitleTopToCards: NSLayoutConstraint?

    private let historyTitle = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var history: [GameHistoryEntry] = []
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()

        NotificationCenter.default.addObserver(self, selector: #selector(historyDidChange), name: GameHistoryStore.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dailyDidChange), name: DailyGameStore.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gameCenterAuthDidChange), name: GameCenterManager.authDidChangeNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        primaryCard.resetConfirmation()
        reloadHistory()
        applyDailyState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GKAccessPoint.shared.location = .topTrailing
        GKAccessPoint.shared.isActive = GameCenterManager.shared.isAuthenticated
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        GKAccessPoint.shared.isActive = false
    }

    private func buildUI() {
        titleLabel.text = "Just Euchre"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Win streak (flame icon)
        let fireColor = UIColor(red: 1.0, green: 0.45, blue: 0.15, alpha: 1)
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        winStreakIcon.image = UIImage(systemName: "flame.fill", withConfiguration: iconConfig)?
            .withTintColor(fireColor, renderingMode: .alwaysOriginal)
        winStreakIcon.contentMode = .scaleAspectFit
        winStreakIcon.translatesAutoresizingMaskIntoConstraints = false

        winStreakLabel.textColor = .white
        winStreakLabel.font = UIFont.systemFont(ofSize: 46, weight: .regular)
        winStreakLabel.adjustsFontSizeToFitWidth = true
        winStreakLabel.minimumScaleFactor = 0.6
        winStreakLabel.textAlignment = .left
        winStreakLabel.translatesAutoresizingMaskIntoConstraints = false

        winStreakStack.axis = .horizontal
        winStreakStack.alignment = .center
        winStreakStack.spacing = 8
        winStreakStack.addArrangedSubview(winStreakIcon)
        winStreakStack.addArrangedSubview(winStreakLabel)
        winStreakStack.translatesAutoresizingMaskIntoConstraints = false

        // Completed-game streak (checkmark icon)
        let checkConfig = UIImage.SymbolConfiguration(pointSize: 42, weight: .medium)
        completedStreakIcon.image = UIImage(systemName: "checkmark.square.fill", withConfiguration: checkConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        completedStreakIcon.contentMode = .scaleAspectFit
        completedStreakIcon.translatesAutoresizingMaskIntoConstraints = false

        completedStreakLabel.textColor = .white
        completedStreakLabel.font = UIFont.systemFont(ofSize: 46, weight: .regular)
        completedStreakLabel.adjustsFontSizeToFitWidth = true
        completedStreakLabel.minimumScaleFactor = 0.6
        completedStreakLabel.textAlignment = .left
        completedStreakLabel.translatesAutoresizingMaskIntoConstraints = false

        completedStreakStack.axis = .horizontal
        completedStreakStack.alignment = .center
        completedStreakStack.spacing = 8
        completedStreakStack.addArrangedSubview(completedStreakIcon)
        completedStreakStack.addArrangedSubview(completedStreakLabel)
        completedStreakStack.translatesAutoresizingMaskIntoConstraints = false

        streakRow.axis = .horizontal
        streakRow.alignment = .center
        streakRow.spacing = 28
        streakRow.addArrangedSubview(winStreakStack)
        streakRow.addArrangedSubview(completedStreakStack)
        streakRow.translatesAutoresizingMaskIntoConstraints = false

        cardsScroll.showsHorizontalScrollIndicator = false
        cardsScroll.alwaysBounceHorizontal = true
        cardsScroll.translatesAutoresizingMaskIntoConstraints = false

        cardsRow.axis = .horizontal
        cardsRow.alignment = .center
        cardsRow.spacing = 16
        cardsRow.translatesAutoresizingMaskIntoConstraints = false

        primaryCard.addTarget(self, action: #selector(didTapPrimaryCard), for: .touchUpInside)
        shareCard.addTarget(self, action: #selector(didTapShareCard), for: .touchUpInside)
        shareCard.isHidden = true

        cardsRow.addArrangedSubview(primaryCard)
        cardsRow.addArrangedSubview(shareCard)

        cardsScroll.addSubview(cardsRow)
        nudgeLabel.numberOfLines = 0
        nudgeLabel.textColor = UIColor(white: 0.62, alpha: 1)
        nudgeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        nudgeLabel.isHidden = true
        nudgeLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(streakRow)
        view.addSubview(cardsScroll)
        view.addSubview(nudgeLabel)
        view.addSubview(historyTitle)
        view.addSubview(tableView)

        historyTitle.text = "Past games"
        historyTitle.textColor = UIColor(white: 0.85, alpha: 1)
        historyTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        historyTitle.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 20, right: 0)
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            winStreakIcon.widthAnchor.constraint(equalToConstant: 32),
            winStreakIcon.heightAnchor.constraint(equalToConstant: 40),
            completedStreakIcon.widthAnchor.constraint(equalToConstant: 40),
            completedStreakIcon.heightAnchor.constraint(equalToConstant: 40),

            streakRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            streakRow.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 14),

            cardsScroll.topAnchor.constraint(equalTo: streakRow.bottomAnchor, constant: 18),
            cardsScroll.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            cardsScroll.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            cardsScroll.heightAnchor.constraint(equalToConstant: 170),

            cardsRow.topAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.topAnchor),
            cardsRow.bottomAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.bottomAnchor),
            cardsRow.leadingAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.leadingAnchor, constant: 18),
            cardsRow.trailingAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.trailingAnchor, constant: -18),
            cardsRow.heightAnchor.constraint(equalTo: cardsScroll.frameLayoutGuide.heightAnchor),

            nudgeLabel.topAnchor.constraint(equalTo: cardsScroll.bottomAnchor, constant: 18),
            nudgeLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            nudgeLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            historyTitle.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            historyTitle.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            tableView.topAnchor.constraint(equalTo: historyTitle.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            tableView.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),
            tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
        ])

        historyTitleTopToNudge = historyTitle.topAnchor.constraint(equalTo: nudgeLabel.bottomAnchor, constant: 18)
        historyTitleTopToCards = historyTitle.topAnchor.constraint(equalTo: cardsScroll.bottomAnchor, constant: 18)
        historyTitleTopToCards?.isActive = true

        // Card sizing (Offsuit-like big rounded tiles)
        primaryCard.translatesAutoresizingMaskIntoConstraints = false
        primaryCard.widthAnchor.constraint(equalToConstant: 340).isActive = true
        primaryCard.heightAnchor.constraint(equalToConstant: 160).isActive = true

        shareCard.translatesAutoresizingMaskIntoConstraints = false
        shareCard.widthAnchor.constraint(equalToConstant: 200).isActive = true
        shareCard.heightAnchor.constraint(equalToConstant: 160).isActive = true
    }

    @objc private func didTapPrimaryCard() {
        guard !DailyGameStore.isCompletedToday() else { return }
        if DailyGameStore.canStartNewGameToday() {
            onStartNewGame?()
        } else {
            onResumeGame?()
        }
    }

    @objc private func didTapShareCard() {
        let todayEntry = history.first(where: { Calendar.current.isDateInToday($0.date) })
        let image = ShareCardRenderer.render(
            winStreak: DailyGameStore.currentWinStreak,
            completedStreak: DailyGameStore.currentCompletedStreak,
            result: todayEntry
        )
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = shareCard
        present(vc, animated: true)
    }

    @objc private func dailyDidChange() {
        applyDailyState()
    }

    @objc private func historyDidChange() {
        reloadHistory()
    }

    @objc private func gameCenterAuthDidChange() {
        GKAccessPoint.shared.isActive = GameCenterManager.shared.isAuthenticated && isViewLoaded && view.window != nil
    }

    private func reloadHistory() {
        history = GameHistoryStore.entries()
        tableView.reloadData()
    }

    private func applyDailyState() {
        winStreakLabel.text = "\(DailyGameStore.currentWinStreak)"
        completedStreakLabel.text = "\(DailyGameStore.currentCompletedStreak)"

        if DailyGameStore.canStartNewGameToday() {
            primaryCard.set(title: "New Game", subtitle: "Today's game", icon: "sparkles")
            primaryCard.isUserInteractionEnabled = true
            primaryCard.alpha = 1
            shareCard.isHidden = true
            setNudgeVisible(false)
        } else if DailyGameStore.isCompletedToday() {
            primaryCard.set(title: "All done!", subtitle: "Go enjoy the rest of your day", icon: "checkmark.circle.fill")
            primaryCard.isUserInteractionEnabled = false
            primaryCard.alpha = 0.55

            // Show share card with today's result
            let todayEntry = history.first(where: { Calendar.current.isDateInToday($0.date) })
            if let entry = todayEntry {
                let subtitle = "\(entry.didWin ? "Win" : "Loss") · \(entry.yourScore)–\(entry.theirScore)"
                shareCard.set(title: "Share", subtitle: subtitle, icon: "square.and.arrow.up")
            } else {
                shareCard.set(title: "Share", subtitle: "Export today's result", icon: "square.and.arrow.up")
            }
            shareCard.isHidden = false

            let nudge = UserDefaults.standard.string(forKey: "justeuchre.gameOverNudge")
            nudgeLabel.text = nudge
            setNudgeVisible(nudge != nil)
        } else {
            primaryCard.set(title: "Resume", subtitle: "Resume today's game", icon: "arrow.right")
            primaryCard.isUserInteractionEnabled = true
            primaryCard.alpha = 1
            shareCard.isHidden = true
            setNudgeVisible(false)
        }
    }

    private func setNudgeVisible(_ visible: Bool) {
        nudgeLabel.isHidden = !visible
        if visible {
            historyTitleTopToCards?.isActive = false
            historyTitleTopToNudge?.isActive = true
        } else {
            historyTitleTopToNudge?.isActive = false
            historyTitleTopToCards?.isActive = true
        }
    }

    // MARK: - Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(1, history.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.reuseIdentifier, for: indexPath) as! HistoryCell
        if history.isEmpty {
            cell.configure(dateText: nil, resultText: "Play a game to start a history.", scoreText: "")
        } else {
            let entry = history[indexPath.row]
            let dateText = dateFormatter.string(from: entry.date)
            let resultText = entry.didWin ? "Win" : "Loss"
            let scoreText = "\(entry.yourScore)–\(entry.theirScore)"
            cell.configure(dateText: dateText, resultText: resultText, scoreText: scoreText)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        68
    }
}

// MARK: - HomeCardView

private final class HomeCardView: UIControl {
    private let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var confirmed = false

    var isLongPressToConfirm: Bool = false

    override var isHighlighted: Bool {
        didSet {
            guard !isLongPressToConfirm else { return }
            let target = isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
            UIView.animate(withDuration: 0.10) { self.transform = target }
        }
    }

    init(title: String, subtitle: String, icon: String) {
        super.init(frame: .zero)

        backgroundColor = surface
        layer.cornerRadius = 14

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = UIColor(white: 1, alpha: 0.65)
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)

        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor(white: 0.75, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)

        [iconView, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -18),

            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -18),
        ])

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func set(title: String, subtitle: String, icon: String) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    func resetConfirmation() {
        confirmed = false
        transform = .identity
    }

    @objc private func didTap() {
        sendActions(for: .primaryActionTriggered)
    }
}

// MARK: - HistoryCell

private final class HistoryCell: UITableViewCell {
    static let reuseIdentifier = "HistoryCell"
    private let monthLabel = UILabel()
    private let dayLabel = UILabel()
    private let resultLabel = UILabel()
    private let scoreLabel = UILabel()
    private let resultStack = UIStackView()
    private var dateColumnWidth: NSLayoutConstraint?
    private var resultLeadingToDate: NSLayoutConstraint?
    private var resultLeadingToEdge: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        monthLabel.textColor = UIColor(white: 0.55, alpha: 1)
        monthLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        monthLabel.textAlignment = .center

        dayLabel.textColor = UIColor(white: 0.85, alpha: 1)
        dayLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        dayLabel.textAlignment = .center

        resultLabel.textColor = .white
        resultLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        resultLabel.textAlignment = .left

        scoreLabel.textColor = UIColor(white: 0.72, alpha: 1)
        scoreLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        scoreLabel.textAlignment = .left

        resultStack.axis = .vertical
        resultStack.alignment = .leading
        resultStack.spacing = 2
        resultStack.addArrangedSubview(resultLabel)
        resultStack.addArrangedSubview(scoreLabel)

        [monthLabel, dayLabel, resultStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        dateColumnWidth = monthLabel.widthAnchor.constraint(equalToConstant: 52)
        resultLeadingToDate = resultStack.leadingAnchor.constraint(equalTo: monthLabel.trailingAnchor, constant: 16)
        resultLeadingToEdge = resultStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)

        NSLayoutConstraint.activate([
            // Month label — upper half of date column
            monthLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dateColumnWidth!,
            monthLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -1),

            // Day label — lower half of date column
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dayLabel.widthAnchor.constraint(equalTo: monthLabel.widthAnchor),
            dayLabel.topAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 1),

            // Result+score stack — top aligned with month label
            resultLeadingToDate!,
            resultStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            resultStack.topAnchor.constraint(equalTo: monthLabel.topAnchor),
        ])

        resultLeadingToEdge?.isActive = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(dateText: String?, resultText: String, scoreText: String) {
        let parts = dateText?.split(separator: " ", maxSplits: 1) ?? []
        monthLabel.text = parts.count > 0 ? String(parts[0]).uppercased() : ""
        dayLabel.text = parts.count > 1 ? String(parts[1]) : ""
        let hasDate = dateText != nil
        monthLabel.isHidden = !hasDate
        dayLabel.isHidden = !hasDate

        resultLabel.text = resultText
        scoreLabel.text = scoreText
        scoreLabel.isHidden = scoreText.isEmpty

        if hasDate {
            dateColumnWidth?.constant = 52
            resultLeadingToEdge?.isActive = false
            resultLeadingToDate?.isActive = true
        } else {
            dateColumnWidth?.constant = 0
            resultLeadingToDate?.isActive = false
            resultLeadingToEdge?.isActive = true
        }
    }
}

// MARK: - ShareCardRenderer

private enum ShareCardRenderer {

    static func render(winStreak: Int, completedStreak: Int, result: GameHistoryEntry?) -> UIImage {
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size, format: {
            let f = UIGraphicsImageRendererFormat()
            f.scale = 1
            f.opaque = true
            return f
        }())

        return renderer.image { _ in
            drawBackground(size: size)
            drawSuitWatermarks(size: size)
            drawCard(size: size)
            drawAppName(size: size)
            drawStreaks(winStreak: winStreak, completedStreak: completedStreak, size: size)
            drawDivider(size: size)
            if let result = result {
                drawResult(result: result, size: size)
            }
            drawBranding(size: size)
        }
    }

    // MARK: Layers

    private static func drawBackground(size: CGSize) {
        let bg = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
        bg.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
    }

    private static func drawSuitWatermarks(size: CGSize) {
        let suits = ["♠", "♥", "♦", "♣"]
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 320, weight: .regular),
            .foregroundColor: UIColor(white: 1, alpha: 0.025)
        ]
        let positions: [CGPoint] = [
            CGPoint(x: -60, y: -60),
            CGPoint(x: size.width - 260, y: -60),
            CGPoint(x: -60, y: size.height - 280),
            CGPoint(x: size.width - 260, y: size.height - 280),
        ]
        for (suit, point) in zip(suits, positions) {
            NSAttributedString(string: suit, attributes: attrs).draw(at: point)
        }
    }

    private static func drawCard(size: CGSize) {
        let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
        let margin: CGFloat = 64
        let cardRect = CGRect(x: margin, y: margin, width: size.width - margin * 2, height: size.height - margin * 2)
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 40)
        surface.setFill()
        path.fill()
    }

    private static func drawAppName(size: CGSize) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .semibold),
            .foregroundColor: UIColor(white: 0.45, alpha: 1)
        ]
        NSAttributedString(string: "Just Euchre", attributes: attrs).draw(at: CGPoint(x: 112, y: 116))
    }

    private static func drawStreaks(winStreak: Int, completedStreak: Int, size: CGSize) {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 72, weight: .medium)
        let numAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 112, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .medium),
            .foregroundColor: UIColor(white: 0.38, alpha: 1)
        ]

        // Left: win streak (flame)
        let fireColor = UIColor(red: 1.0, green: 0.45, blue: 0.15, alpha: 1)
        if let flame = UIImage(systemName: "flame.fill", withConfiguration: iconConfig)?
            .withTintColor(fireColor, renderingMode: .alwaysOriginal) {
            flame.draw(in: CGRect(x: 110, y: 210, width: 72, height: 84))
        }
        NSAttributedString(string: "\(winStreak)", attributes: numAttrs).draw(at: CGPoint(x: 196, y: 196))
        NSAttributedString(string: "winning streak", attributes: labelAttrs).draw(at: CGPoint(x: 110, y: 336))

        // Vertical separator
        UIColor(white: 0.18, alpha: 1).setFill()
        UIRectFill(CGRect(x: 500, y: 200, width: 1, height: 150))

        // Right: completed streak (checkmark square)
        if let check = UIImage(systemName: "checkmark.square.fill", withConfiguration: iconConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal) {
            check.draw(in: CGRect(x: 556, y: 210, width: 72, height: 84))
        }
        NSAttributedString(string: "\(completedStreak)", attributes: numAttrs).draw(at: CGPoint(x: 642, y: 196))
        NSAttributedString(string: "completed streak", attributes: labelAttrs).draw(at: CGPoint(x: 556, y: 336))
    }

    private static func drawDivider(size: CGSize) {
        UIColor(white: 0.18, alpha: 1).setFill()
        UIRectFill(CGRect(x: 112, y: 406, width: size.width - 224, height: 1))
    }

    private static func drawResult(result: GameHistoryEntry, size: CGSize) {
        let winColor  = UIColor(red: 52/255, green: 211/255, blue: 153/255, alpha: 1)
        let lossColor = UIColor(red: 248/255, green: 113/255, blue: 113/255, alpha: 1)
        let resultColor = result.didWin ? winColor : lossColor

        // "Win" / "Loss"
        let resultAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 110, weight: .bold),
            .foregroundColor: resultColor
        ]
        NSAttributedString(string: result.didWin ? "Win" : "Loss", attributes: resultAttrs)
            .draw(at: CGPoint(x: 112, y: 438))

        // Score
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 52, weight: .medium),
            .foregroundColor: UIColor(white: 0.6, alpha: 1)
        ]
        NSAttributedString(string: "\(result.yourScore)–\(result.theirScore)", attributes: scoreAttrs)
            .draw(at: CGPoint(x: 112, y: 574))

        // Date
        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy"
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .regular),
            .foregroundColor: UIColor(white: 0.35, alpha: 1)
        ]
        NSAttributedString(string: df.string(from: result.date), attributes: dateAttrs)
            .draw(at: CGPoint(x: 112, y: 658))
    }

    private static func drawBranding(size: CGSize) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .regular),
            .foregroundColor: UIColor(white: 0.22, alpha: 1)
        ]
        let str = NSAttributedString(string: "justeuchre.app", attributes: attrs)
        let strSize = str.size()
        str.draw(at: CGPoint(x: (size.width - strSize.width) / 2, y: size.height - 112))
    }
}
