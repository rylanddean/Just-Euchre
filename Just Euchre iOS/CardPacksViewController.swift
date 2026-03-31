//
//  CardPacksViewController.swift
//  Just Euchre iOS
//

import UIKit

private extension UIColor {
    var perceivedLuminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}

final class CardPacksViewController: UIViewController {

    var onPackSelected: ((CardPack) -> Void)?

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
    private let mint = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)

    private var selectedPackID = CardPackStore.selectedPackID
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()
    }

    private func buildUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Card packs"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .estimated(190)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(190)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 12, bottom: 32, trailing: 12)
            return section
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(CardPackCell.self, forCellWithReuseIdentifier: CardPackCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
        ])
    }
}

extension CardPacksViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        CardPack.all.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardPackCell.reuseID, for: indexPath) as! CardPackCell
        let pack = CardPack.all[indexPath.item]
        cell.configure(pack: pack, isSelected: pack.id == selectedPackID)
        return cell
    }
}

extension CardPacksViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let pack = CardPack.all[indexPath.item]
        guard pack.id != selectedPackID else { return }
        selectedPackID = pack.id
        CardPackStore.selectedPackID = pack.id
        collectionView.reloadData()
        onPackSelected?(pack)
    }
}

// MARK: - CardPackCell

private final class CardPackCell: UICollectionViewCell {
    static let reuseID = "CardPackCell"

    private let mint = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)
    private let containerView = UIView()
    private let blackCard = MiniCardPreviewView()
    private let redCard = MiniCardPreviewView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let checkView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        containerView.layer.cornerRadius = 14
        containerView.layer.borderWidth = 0
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        let cardStack = UIStackView(arrangedSubviews: [blackCard, redCard])
        cardStack.axis = .horizontal
        cardStack.spacing = 10
        cardStack.alignment = .center
        cardStack.distribution = .fillEqually
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textAlignment = .center

        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textAlignment = .center

        checkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkView.tintColor = mint
        checkView.contentMode = .scaleAspectFit
        checkView.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.alignment = .center

        let outerStack = UIStackView(arrangedSubviews: [cardStack, textStack])
        outerStack.axis = .vertical
        outerStack.spacing = 14
        outerStack.alignment = .center
        outerStack.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(outerStack)
        containerView.addSubview(checkView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            outerStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            outerStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            outerStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            outerStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),

            blackCard.heightAnchor.constraint(equalToConstant: 76),
            redCard.heightAnchor.constraint(equalToConstant: 76),

            checkView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            checkView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            checkView.widthAnchor.constraint(equalToConstant: 20),
            checkView.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    func configure(pack: CardPack, isSelected: Bool) {
        blackCard.configure(pack: pack, suitText: "♠", isRed: false)
        redCard.configure(pack: pack, suitText: "♥", isRed: true)
        containerView.backgroundColor = pack.cardBackground

        let isLight = pack.cardBackground.perceivedLuminance > 0.5
        nameLabel.text = pack.name
        nameLabel.textColor = isLight ? UIColor(white: 0.10, alpha: 1) : .white
        subtitleLabel.text = pack.subtitle
        subtitleLabel.textColor = isLight ? UIColor(white: 0.35, alpha: 1) : UIColor(white: 0.55, alpha: 1)
        checkView.isHidden = !isSelected
        containerView.layer.borderColor = mint.cgColor
        containerView.layer.borderWidth = isSelected ? 2.5 : 0
    }
}

// MARK: - MiniCardPreviewView

private final class MiniCardPreviewView: UIView {
    private let symbolLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.20
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 3)

        symbolLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        symbolLabel.textAlignment = .center
        symbolLabel.isUserInteractionEnabled = false
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolLabel)

        NSLayoutConstraint.activate([
            symbolLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(pack: CardPack, suitText: String, isRed: Bool) {
        backgroundColor = pack.cardBackground
        symbolLabel.text = suitText
        symbolLabel.textColor = isRed ? pack.redSuitColor : pack.blackSuitColor
    }
}
