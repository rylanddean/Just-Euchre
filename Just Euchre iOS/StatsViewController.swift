//
//  StatsViewController.swift
//  Just Euchre iOS
//

import UIKit

final class StatsViewController: UIViewController {

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
    private let surface    = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
    private let border     = UIColor(white: 0.28, alpha: 1)
    private let mint       = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)
    private let fire       = UIColor(red: 1.0, green: 0.45, blue: 0.15, alpha: 1)

    private let titleLabel   = UILabel()
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()

    private var displayedMonth: Date = {
        let comps = Calendar.current.dateComponents([.year, .month], from: Date())
        return Calendar.current.date(from: comps)!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()

        NotificationCenter.default.addObserver(self, selector: #selector(dataDidChange), name: GameHistoryStore.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidChange), name: DailyGameStore.didChangeNotification, object: nil)
    }

    private func buildUI() {
        titleLabel.text = "Stats"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            scrollView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -18),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36),
        ])

        buildSections()
    }

    private func buildSections() {
        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }

        // Calendar
        contentStack.addArrangedSubview(sectionTitle("Games Played"))

        let (played, won) = playedAndWonDatesInMonth(displayedMonth)
        let cal = CalendarCardView(
            month: displayedMonth,
            playedDates: played,
            wonDates: won,
            surface: surface,
            border: border,
            mint: mint,
            fire: fire
        )
        cal.onPrevMonth = { [weak self] in self?.navigateMonth(-1) }
        cal.onNextMonth = { [weak self] in self?.navigateMonth(1) }
        contentStack.addArrangedSubview(cal)

        // Streaks
        contentStack.addArrangedSubview(sectionSpacer())
        contentStack.addArrangedSubview(sectionTitle("Streaks"))

        let winRow = StatRowView(surface: surface, border: border)
        let longestWin = DailyGameStore.longestStreak
        winRow.configure(
            title: "Longest winning streak",
            subtitle: longestWin > 0 ? "\(longestWin) day\(longestWin == 1 ? "" : "s")" : "No streak yet",
            icon: "flame.fill"
        )
        contentStack.addArrangedSubview(winRow)

        let completedRow = StatRowView(surface: surface, border: border)
        let longestCompleted = DailyGameStore.longestCompletedStreak
        completedRow.configure(
            title: "Longest completed streak",
            subtitle: longestCompleted > 0 ? "\(longestCompleted) day\(longestCompleted == 1 ? "" : "s")" : "No streak yet",
            icon: "checkmark.square.fill"
        )
        contentStack.addArrangedSubview(completedRow)
    }

    private func navigateMonth(_ delta: Int) {
        let cal = Calendar.current
        guard let candidate = cal.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        let nowComps = cal.dateComponents([.year, .month], from: Date())
        let nowFirst = cal.date(from: nowComps)!
        guard candidate <= nowFirst else { return }
        displayedMonth = candidate
        buildSections()
    }

    private func playedAndWonDatesInMonth(_ monthStart: Date) -> (played: Set<Date>, won: Set<Date>) {
        let cal = Calendar.current
        let monthComps = cal.dateComponents([.year, .month], from: monthStart)
        var played = Set<Date>()
        var won = Set<Date>()
        for entry in GameHistoryStore.entries() {
            let entryComps = cal.dateComponents([.year, .month], from: entry.date)
            guard entryComps.year == monthComps.year && entryComps.month == monthComps.month else { continue }
            let day = cal.startOfDay(for: entry.date)
            played.insert(day)
            if entry.didWin { won.insert(day) }
        }
        return (played, won)
    }

    @objc private func dataDidChange() { buildSections() }

    private func sectionSpacer() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 10).isActive = true
        return v
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.textColor = UIColor(white: 0.55, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        return label
    }
}

// MARK: - Stat Row

private final class StatRowView: UIView {
    private let iconView    = UIImageView()
    private let titleLabel  = UILabel()
    private let subtitleLabel = UILabel()

    init(surface: UIColor, border: UIColor) {
        super.init(frame: .zero)
        backgroundColor = surface
        layer.cornerRadius = 12

        iconView.tintColor   = UIColor(white: 1, alpha: 0.65)
        iconView.contentMode = .scaleAspectFit

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        subtitleLabel.textColor = UIColor(white: 0.72, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        [iconView, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -18),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, subtitle: String, icon: String) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}

// MARK: - Calendar Card

private final class CalendarCardView: UIView {
    var onPrevMonth: (() -> Void)?
    var onNextMonth: (() -> Void)?

    init(month: Date, playedDates: Set<Date>, wonDates: Set<Date>, surface: UIColor, border: UIColor, mint: UIColor, fire: UIColor) {
        super.init(frame: .zero)
        backgroundColor = surface
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = border.cgColor
        build(month: month, playedDates: playedDates, wonDates: wonDates, mint: mint, fire: fire)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func build(month: Date, playedDates: Set<Date>, wonDates: Set<Date>, mint: UIColor, fire: UIColor) {
        let cal = Calendar.current

        // Header: prev  Month YYYY  next
        let prevBtn = UIButton(type: .system)
        prevBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevBtn.tintColor = UIColor(white: 0.55, alpha: 1)
        prevBtn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)

        let nextBtn = UIButton(type: .system)
        nextBtn.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextBtn.tintColor = UIColor(white: 0.55, alpha: 1)
        nextBtn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        let nowComps = cal.dateComponents([.year, .month], from: Date())
        let monthComps = cal.dateComponents([.year, .month], from: month)
        let isCurrentMonth = monthComps.year == nowComps.year && monthComps.month == nowComps.month
        nextBtn.isEnabled = !isCurrentMonth
        nextBtn.alpha = isCurrentMonth ? 0.3 : 1

        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        let monthLabel = UILabel()
        monthLabel.text = fmt.string(from: month)
        monthLabel.textColor = .white
        monthLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        monthLabel.textAlignment = .center

        let headerStack = UIStackView(arrangedSubviews: [prevBtn, monthLabel, nextBtn])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing

        // Day-of-week labels
        let dowStack = UIStackView()
        dowStack.axis = .horizontal
        dowStack.distribution = .fillEqually
        for sym in ["S", "M", "T", "W", "T", "F", "S"] {
            let label = UILabel()
            label.text = sym
            label.textColor = UIColor(white: 0.4, alpha: 1)
            label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            label.textAlignment = .center
            dowStack.addArrangedSubview(label)
        }

        // Day grid
        let firstDay = month
        let weekdayOffset = cal.component(.weekday, from: firstDay) - 1 // 0=Sun
        let daysInMonth = cal.range(of: .day, in: .month, for: firstDay)!.count
        let rows = Int(ceil(Double(weekdayOffset + daysInMonth) / 7.0))

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 4

        for row in 0..<rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.heightAnchor.constraint(equalToConstant: 40).isActive = true

            for col in 0..<7 {
                let dayNumber = row * 7 + col - weekdayOffset + 1
                let cell = DayCell()
                if dayNumber >= 1 && dayNumber <= daysInMonth {
                    var comps = cal.dateComponents([.year, .month], from: firstDay)
                    comps.day = dayNumber
                    let date = cal.date(from: comps)!
                    let day = cal.startOfDay(for: date)
                    let played = playedDates.contains(day)
                    let won = wonDates.contains(day)
                    let isToday = cal.isDateInToday(date)
                    cell.configure(day: dayNumber, played: played, won: won, isToday: isToday, mint: mint, fire: fire)
                } else {
                    cell.configureEmpty()
                }
                rowStack.addArrangedSubview(cell)
            }
            gridStack.addArrangedSubview(rowStack)
        }

        let outer = UIStackView(arrangedSubviews: [headerStack, dowStack, gridStack])
        outer.axis = .vertical
        outer.spacing = 12
        outer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outer)

        NSLayoutConstraint.activate([
            headerStack.heightAnchor.constraint(equalToConstant: 32),
            outer.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            outer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            outer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            outer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    @objc private func prevTapped() { onPrevMonth?() }
    @objc private func nextTapped() { onNextMonth?() }
}

// MARK: - Day Cell

private final class DayCell: UIView {
    private let circle = UIView()
    private let label  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        circle.layer.cornerRadius = 16
        circle.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circle)
        circle.addSubview(label)
        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: 32),
            circle.heightAnchor.constraint(equalToConstant: 32),
            label.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(day: Int, played: Bool, won: Bool, isToday: Bool, mint: UIColor, fire: UIColor) {
        label.text = "\(day)"
        circle.layer.borderWidth = 0
        if played {
            let accent = won ? fire : mint
            circle.backgroundColor = accent.withAlphaComponent(0.18)
            label.textColor = accent
            label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        } else if isToday {
            circle.backgroundColor = .clear
            circle.layer.borderWidth = 1
            circle.layer.borderColor = UIColor(white: 0.45, alpha: 1).cgColor
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        } else {
            circle.backgroundColor = .clear
            label.textColor = UIColor(white: 0.35, alpha: 1)
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        }
    }

    func configureEmpty() {
        label.text = ""
        circle.backgroundColor = .clear
        circle.layer.borderWidth = 0
    }
}
