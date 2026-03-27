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
        54
    }
}

private final class HomeCardView: UIControl {
    private let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
    private let border = UIColor(white: 0.28, alpha: 1)
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
        layer.cornerRadius = 22
        layer.borderWidth = 1
        layer.borderColor = border.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.20
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 14)

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)

        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor(white: 0.75, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)

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
        layer.borderColor = border.cgColor
        transform = .identity
    }

    @objc private func didTap() {
        sendActions(for: .primaryActionTriggered)
    }
}

private final class HistoryCell: UITableViewCell {
    static let reuseIdentifier = "HistoryCell"
    private let dateLabel = UILabel()
    private let resultLabel = UILabel()
    private let scoreLabel = UILabel()
    private var dateWidth: NSLayoutConstraint?
    private var resultLeadingToDate: NSLayoutConstraint?
    private var resultLeadingToEdge: NSLayoutConstraint?
    private var resultTrailingToScore: NSLayoutConstraint?
    private var resultTrailingToEdge: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        dateLabel.textColor = UIColor(white: 0.62, alpha: 1)
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        dateLabel.textAlignment = .left

        resultLabel.textColor = .white
        resultLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        resultLabel.textAlignment = .left
        resultLabel.numberOfLines = 2
        resultLabel.lineBreakMode = .byWordWrapping

        scoreLabel.textColor = UIColor(white: 0.72, alpha: 1)
        scoreLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        scoreLabel.textAlignment = .right

        [dateLabel, resultLabel, scoreLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        dateWidth = dateLabel.widthAnchor.constraint(equalToConstant: 72)
        resultLeadingToDate = resultLabel.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 14)
        resultLeadingToEdge = resultLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        resultTrailingToScore = resultLabel.trailingAnchor.constraint(lessThanOrEqualTo: scoreLabel.leadingAnchor, constant: -12)
        resultTrailingToEdge = resultLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateWidth!,

            resultLeadingToDate!,
            resultLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            resultTrailingToScore!,

            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scoreLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            scoreLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])

        resultLeadingToEdge?.isActive = false
        resultTrailingToEdge?.isActive = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(dateText: String?, resultText: String, scoreText: String) {
        dateLabel.text = dateText ?? ""
        dateLabel.isHidden = (dateText == nil)
        resultLabel.text = resultText
        scoreLabel.text = scoreText
        scoreLabel.isHidden = scoreText.isEmpty

        if dateLabel.isHidden {
            dateWidth?.constant = 0
            resultLeadingToDate?.isActive = false
            resultLeadingToEdge?.isActive = true
        } else {
            dateWidth?.constant = 72
            resultLeadingToEdge?.isActive = false
            resultLeadingToDate?.isActive = true
        }

        // When the score is hidden (empty state), let the message use the full row width.
        resultTrailingToScore?.isActive = !scoreLabel.isHidden
        resultTrailingToEdge?.isActive = scoreLabel.isHidden
    }
}
