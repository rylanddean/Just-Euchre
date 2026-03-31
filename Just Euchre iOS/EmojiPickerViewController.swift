//
//  EmojiPickerViewController.swift
//  Just Euchre iOS
//
//  Curated emoji grid presented as a medium sheet from Settings.
//  Player picks their avatar emoji; selection is persisted to UserDefaults
//  and reflected on the "You" badge next time a game starts.
//

import UIKit

final class EmojiPickerViewController: UIViewController {

    // MARK: - Public API

    /// The emoji that should appear selected when the picker opens.
    var currentEmoji: String = PlayerEmojiStore.emoji

    /// Called immediately when the player taps a cell, before the sheet dismisses.
    var onSelect: ((String) -> Void)?

    // MARK: - Data

    /// Curated set shown to the player in the settings picker.
    static let playerEmojis: [String] = [
        "🙂", "😎", "🤓", "🥸", "😏", "🧐",
        "🤔", "🫡", "😤", "🤯", "🥶", "🤠",
        "🎭", "🕵️", "🎩", "🧢", "👑", "🥳",
        "🦊", "🐺", "🦁", "🐻", "🐯", "🦝",
        "🦅", "🐸", "🤖", "👾", "🧙", "🃏",
    ]

    /// Pool used to randomly assign emojis to the West and East bot seats each game.
    /// Kept distinct from the full player list so bots don't look like the user.
    static let botEmojiPool: [String] = [
        "🧢", "🕵️", "🤠", "🥸", "🎩", "😏",
        "🧐", "🫡", "😤", "👑", "🐯", "🦝",
        "🐸", "🦅", "🐧", "👾", "🎭", "🤓",
    ]

    // MARK: - Colours

    private let background = UIColor(red: 8/255,  green: 11/255, blue: 18/255,  alpha: 1)
    private let surface    = UIColor(red: 26/255, green: 33/255, blue: 44/255,  alpha: 1)
    private let mint       = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)
    private let border     = UIColor(white: 0.28, alpha: 1)

    // MARK: - Views

    private var collectionView: UICollectionView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()
    }

    // MARK: - Layout

    private func buildUI() {

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Your Avatar"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Shown in the game header"
        subtitleLabel.textColor = UIColor(white: 0.55, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // Collection
        let columns: CGFloat = 6
        let spacing: CGFloat = 10
        let sideInset: CGFloat = 18
        let totalSpacing = spacing * (columns - 1) + sideInset * 2
        let cellSide = floor((UIScreen.main.bounds.width - totalSpacing) / columns)

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: cellSide, height: cellSide)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 14, left: sideInset, bottom: 16, right: sideInset)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 22),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension EmojiPickerViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        EmojiPickerViewController.playerEmojis.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EmojiCell.reuseID, for: indexPath) as! EmojiCell
        let emoji = EmojiPickerViewController.playerEmojis[indexPath.item]
        cell.configure(emoji: emoji,
                       isSelected: emoji == currentEmoji,
                       mint: mint,
                       surface: surface,
                       border: border)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension EmojiPickerViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let emoji = EmojiPickerViewController.playerEmojis[indexPath.item]
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentEmoji = emoji
        collectionView.reloadData()
        onSelect?(emoji)
        dismiss(animated: true)
    }
}

// MARK: - EmojiCell

private final class EmojiCell: UICollectionViewCell {

    static let reuseID = "EmojiCell"

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = UIFont.systemFont(ofSize: 26)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.width / 2
    }

    func configure(emoji: String,
                   isSelected: Bool,
                   mint: UIColor,
                   surface: UIColor,
                   border: UIColor) {
        label.text = emoji
        contentView.backgroundColor = surface
        contentView.layer.borderWidth  = isSelected ? 2.5 : 1
        contentView.layer.borderColor  = isSelected ? mint.cgColor : border.cgColor
        contentView.clipsToBounds      = true
    }
}

// MARK: - PlayerEmojiStore

/// Centralises read/write of the player's chosen avatar emoji.
enum PlayerEmojiStore {
    static let didChangeNotification = Notification.Name("justeuchre.playerEmoji.didChange")

    private static let key     = "justeuchre.playerEmoji"
    private static let default_ = "🙂"

    static var emoji: String {
        get { UserDefaults.standard.string(forKey: key) ?? default_ }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }
}

// MARK: - BotEmojiStore

/// Persists the randomly-assigned West/East seat emojis for the current game
/// so they survive an app relaunch mid-hand.
enum BotEmojiStore {
    private static let key = "justeuchre.botEmojis"

    static func save(west: String, east: String) {
        UserDefaults.standard.set([west, east], forKey: key)
    }

    static func load() -> (west: String, east: String)? {
        guard let arr = UserDefaults.standard.array(forKey: key) as? [String],
              arr.count >= 2 else { return nil }
        return (arr[0], arr[1])
    }
}
