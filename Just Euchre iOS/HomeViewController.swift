//
//  HomeViewController.swift
//  Just Euchre iOS
//

import UIKit

final class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var onStartNewGame: (() -> Void)?
    var onResumeGame: (() -> Void)?

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)

    private let titleLabel = UILabel()
    private let streakLabel = UILabel()
    private let cardsScroll = UIScrollView()
    private let cardsRow = UIStackView()
    private let primaryCard = HomeCardView(title: "New Game", subtitle: "Today’s game", icon: "sparkles")
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        primaryCard.resetConfirmation()
        reloadHistory()
        applyDailyState()
    }

    private func buildUI() {
        titleLabel.text = "Just Euchre"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        streakLabel.textColor = .white
        streakLabel.font = UIFont.systemFont(ofSize: 58, weight: .regular)
        streakLabel.adjustsFontSizeToFitWidth = true
        streakLabel.minimumScaleFactor = 0.6
        streakLabel.textAlignment = .left
        streakLabel.translatesAutoresizingMaskIntoConstraints = false

        cardsScroll.showsHorizontalScrollIndicator = false
        cardsScroll.alwaysBounceHorizontal = true
        cardsScroll.translatesAutoresizingMaskIntoConstraints = false

        cardsRow.axis = .horizontal
        cardsRow.alignment = .center
        cardsRow.spacing = 16
        cardsRow.translatesAutoresizingMaskIntoConstraints = false

        primaryCard.addTarget(self, action: #selector(didTapPrimaryCard), for: .touchUpInside)
        cardsRow.addArrangedSubview(primaryCard)

        cardsScroll.addSubview(cardsRow)
        view.addSubview(titleLabel)
        view.addSubview(streakLabel)
        view.addSubview(cardsScroll)
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

            streakLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            streakLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            streakLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            cardsScroll.topAnchor.constraint(equalTo: streakLabel.bottomAnchor, constant: 18),
            cardsScroll.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            cardsScroll.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            cardsScroll.heightAnchor.constraint(equalToConstant: 170),

            cardsRow.topAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.topAnchor),
            cardsRow.bottomAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.bottomAnchor),
            cardsRow.leadingAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.leadingAnchor, constant: 18),
            cardsRow.trailingAnchor.constraint(equalTo: cardsScroll.contentLayoutGuide.trailingAnchor, constant: -18),
            cardsRow.heightAnchor.constraint(equalTo: cardsScroll.frameLayoutGuide.heightAnchor),

            historyTitle.topAnchor.constraint(equalTo: cardsScroll.bottomAnchor, constant: 18),
            historyTitle.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            historyTitle.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            tableView.topAnchor.constraint(equalTo: historyTitle.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            tableView.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),
            tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
        ])

        // Card sizing (Offsuit-like big rounded tiles)
        primaryCard.translatesAutoresizingMaskIntoConstraints = false
        primaryCard.widthAnchor.constraint(equalToConstant: 340).isActive = true
        primaryCard.heightAnchor.constraint(equalToConstant: 160).isActive = true
    }

    @objc private func didTapPrimaryCard() {
        if DailyGameStore.canStartNewGameToday() {
            onStartNewGame?()
        } else {
            onResumeGame?()
        }
    }

    @objc private func dailyDidChange() {
        applyDailyState()
    }

    @objc private func historyDidChange() {
        reloadHistory()
    }

    private func reloadHistory() {
        history = GameHistoryStore.entries()
        tableView.reloadData()
    }

    private func applyDailyState() {
        let streak = DailyGameStore.currentStreak
        streakLabel.text = "\(streak)"

        if DailyGameStore.canStartNewGameToday() {
            primaryCard.set(title: "New Game", subtitle: "Today’s game", icon: "sparkles")
        } else {
            let subtitle = DailyGameStore.isCompletedToday() ? "Today’s game (finished)" : "Resume today’s game"
            primaryCard.set(title: "Resume", subtitle: subtitle, icon: "arrow.right")
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

            // Result+score stack — centered vertically in the cell
            resultLeadingToDate!,
            resultStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            resultStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
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
