//
//  ProfileViewController.swift
//  Just Euchre iOS
//

import UIKit

final class ProfileViewController: UIViewController, UITextFieldDelegate {

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
    private let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
    private let border = UIColor(white: 0.28, alpha: 1)

    private let titleLabel = UILabel()
    private let avatarLabel = UILabel()
    private let nameField = UITextField()
    private let streakBadge = UILabel()
    private let emojiGrid = UIStackView()
    private let comingSoonStack = UIStackView()

    private var selectedEmoji: String = ProfileStore.emoji
    private let emojiOptions: [String] = ["🙂", "😎", "🤠", "🦊", "🐼", "🐸", "👽", "🤖", "👻", "🐙"]
    private var emojiButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()
        applyCurrentProfile()
        installKeyboardDone()

        NotificationCenter.default.addObserver(self, selector: #selector(dailyDidChange), name: DailyGameStore.didChangeNotification, object: nil)
    }

    private func buildUI() {
        titleLabel.text = "Profile"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        avatarLabel.textAlignment = .center
        avatarLabel.font = UIFont.systemFont(ofSize: 74, weight: .regular)
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false

        streakBadge.textAlignment = .center
        streakBadge.textColor = UIColor(white: 0.90, alpha: 1)
        streakBadge.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        streakBadge.backgroundColor = .clear
        streakBadge.numberOfLines = 1
        streakBadge.translatesAutoresizingMaskIntoConstraints = false

        nameField.textAlignment = .center
        nameField.textColor = .white
        nameField.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        nameField.returnKeyType = .done
        nameField.autocapitalizationType = .words
        nameField.autocorrectionType = .no
        nameField.delegate = self
        nameField.backgroundColor = surface
        nameField.layer.cornerRadius = 14
        nameField.translatesAutoresizingMaskIntoConstraints = false

        emojiGrid.axis = .vertical
        emojiGrid.alignment = .fill
        emojiGrid.distribution = .fillEqually
        emojiGrid.spacing = 10
        emojiGrid.translatesAutoresizingMaskIntoConstraints = false

        buildEmojiButtons()

        comingSoonStack.axis = .vertical
        comingSoonStack.alignment = .fill
        comingSoonStack.distribution = .fill
        comingSoonStack.spacing = 10
        comingSoonStack.translatesAutoresizingMaskIntoConstraints = false

        comingSoonStack.addArrangedSubview(ComingSoonRow(title: "Card style", subtitle: "Coming soon", surface: surface, border: border))
        comingSoonStack.addArrangedSubview(ComingSoonRow(title: "Player icon pack", subtitle: "Coming soon", surface: surface, border: border))

        view.addSubview(titleLabel)
        view.addSubview(avatarLabel)
        view.addSubview(streakBadge)
        view.addSubview(nameField)
        view.addSubview(emojiGrid)
        view.addSubview(comingSoonStack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            avatarLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 26),
            avatarLabel.centerXAnchor.constraint(equalTo: safe.centerXAnchor),

            streakBadge.topAnchor.constraint(equalTo: avatarLabel.bottomAnchor, constant: 10),
            streakBadge.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            streakBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            streakBadge.leadingAnchor.constraint(greaterThanOrEqualTo: safe.leadingAnchor, constant: 18),
            streakBadge.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -18),

            nameField.topAnchor.constraint(equalTo: streakBadge.bottomAnchor, constant: 12),
            nameField.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            nameField.widthAnchor.constraint(equalToConstant: 220),
            nameField.heightAnchor.constraint(equalToConstant: 44),

            emojiGrid.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 20),
            emojiGrid.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            emojiGrid.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),

            comingSoonStack.topAnchor.constraint(equalTo: emojiGrid.bottomAnchor, constant: 22),
            comingSoonStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            comingSoonStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),
        ])
    }

    private func buildEmojiButtons() {
        emojiButtons = []
        emojiGrid.arrangedSubviews.forEach { emojiGrid.removeArrangedSubview($0); $0.removeFromSuperview() }

        let row1 = makeEmojiRow(emojis: Array(emojiOptions.prefix(5)))
        let row2 = makeEmojiRow(emojis: Array(emojiOptions.suffix(from: 5)))
        emojiGrid.addArrangedSubview(row1)
        emojiGrid.addArrangedSubview(row2)
    }

    private func makeEmojiRow(emojis: [String]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 10

        emojis.forEach { emoji in
            let button = UIButton(type: .system)
            button.setTitle(emoji, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .regular)
            button.backgroundColor = surface
            button.layer.cornerRadius = 14
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: #selector(didTapEmoji(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 52).isActive = true
            row.addArrangedSubview(button)
            emojiButtons.append(button)
        }

        return row
    }

    private func applyCurrentProfile() {
        selectedEmoji = ProfileStore.emoji
        avatarLabel.text = selectedEmoji
        nameField.text = ProfileStore.name
        updateEmojiSelectionUI()
        updateStreakBadge()
    }

    @objc private func dailyDidChange() {
        updateStreakBadge()
    }

    private func updateStreakBadge() {
        let longest = DailyGameStore.longestStreak
        let date = DailyGameStore.longestStreakDate

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        if longest <= 0 {
            streakBadge.text = "🏅 Longest streak: 0 days"
            return
        }

        let dateText = date.map { formatter.string(from: $0) } ?? "—"
        streakBadge.text = "🏅 Longest streak: \(longest) day\(longest == 1 ? "" : "s") • \(dateText)"
    }

    private func updateEmojiSelectionUI() {
        emojiButtons.forEach { button in
            let isSelected = (button.title(for: .normal) == selectedEmoji)
            button.backgroundColor = isSelected ? UIColor(white: 0.38, alpha: 1) : surface
        }
    }

    private func persistProfile() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        ProfileStore.save(name: name.isEmpty ? "You" : name, emoji: selectedEmoji)
    }

    @objc private func didTapEmoji(_ sender: UIButton) {
        guard let emoji = sender.title(for: .normal) else { return }
        selectedEmoji = emoji
        avatarLabel.text = emoji
        updateEmojiSelectionUI()
        persistProfile()
    }

    private func installKeyboardDone() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didTapDone)),
        ]
        nameField.inputAccessoryView = toolbar
    }

    @objc private func didTapDone() {
        view.endEditing(true)
        persistProfile()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        persistProfile()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        persistProfile()
    }
}

private final class ComingSoonRow: UIView {
    init(title: String, subtitle: String, surface: UIColor, border: UIColor) {
        super.init(frame: .zero)

        backgroundColor = surface
        layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = UIColor(white: 0.72, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(white: 0.45, alpha: 1)
        chevron.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        [textStack, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),

            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -12),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16),
        ])

        isUserInteractionEnabled = false
        alpha = 0.85
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
