//
//  HowToPlayViewController.swift
//  Just Euchre iOS
//

import UIKit

final class HowToPlayViewController: UIViewController {

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
    private let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()
    }

    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "How to Play"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor(white: 0.45, alpha: 1)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -8),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            scrollView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36),
        ])

        for section in sections {
            contentStack.addArrangedSubview(makeCard(section))
        }
    }

    private func makeCard(_ section: Section) -> UIView {
        let card = UIView()
        card.backgroundColor = surface
        card.layer.cornerRadius = 14
        card.translatesAutoresizingMaskIntoConstraints = false

        let emojiLabel = UILabel()
        emojiLabel.text = section.emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 26)

        let headingLabel = UILabel()
        headingLabel.text = section.heading
        headingLabel.textColor = .white
        headingLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)

        let headerStack = UIStackView(arrangedSubviews: [emojiLabel, headingLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 10

        let bodyLabel = UILabel()
        bodyLabel.text = section.body
        bodyLabel.textColor = UIColor(white: 0.78, alpha: 1)
        bodyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping

        let stack = UIStackView(arrangedSubviews: [headerStack, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        return card
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }
}

// MARK: - Content

private struct Section {
    let emoji: String
    let heading: String
    let body: String
}

private let sections: [Section] = [
    Section(
        emoji: "🎯",
        heading: "The Goal",
        body: "Win at least 3 out of 5 tricks per round. Do that and your team scores. Fall short and you've been \"euchred\" — which sounds made up, but the shame is very real."
    ),
    Section(
        emoji: "👥",
        heading: "The Crew",
        body: "4 players, 2 teams. You and your partner sit across the table from each other, silently judging your opponents' every choice."
    ),
    Section(
        emoji: "🃏",
        heading: "The Deck",
        body: "Only 24 cards are in play — 9s through Aces. That's it. We threw out the riff-raff. This isn't your grandma's 52-card game... well, actually it might be exactly that."
    ),
    Section(
        emoji: "👑",
        heading: "Card Ranks",
        body: "Trump suit reigns supreme. The Jack of trump — called the Right Bower — is the highest card in the game. The Jack of the same color suit (Left Bower) is its loyal sidekick. After that it's A, K, Q, J, 10, 9 for all other suits."
    ),
    Section(
        emoji: "🤝",
        heading: "Dealing",
        body: "Deal 5 cards to each player, in batches of 2 and 3 (order doesn't matter, dealer's call). Flip the top card of the remaining pile — that's your proposed trump suit."
    ),
    Section(
        emoji: "🙋",
        heading: "Calling Trump",
        body: "Starting left of the dealer, each player can \"order it up\" to accept that card's suit as trump — or pass. If ordered up, the dealer pockets it and discards a card.\n\nIf everyone passes, go around again. Now anyone can name any other suit as trump. If everyone passes a second time... let's just say that's a bad vibe and move on."
    ),
    Section(
        emoji: "🦅",
        heading: "Going Alone",
        body: "Feeling brave? You can ditch your partner and go solo. Win all 5 tricks by yourself and you score 4 points. It's a big swing, but it's a big flex."
    ),
    Section(
        emoji: "🔄",
        heading: "Playing Tricks",
        body: "The player to the left of the dealer leads the first trick. You must follow suit if you can. If you can't, play anything — trump or otherwise.\n\nHighest card of the led suit wins the trick, unless someone played trump. Highest trump wins over everything."
    ),
    Section(
        emoji: "📊",
        heading: "Scoring",
        body: "• Make your bid (3–4 tricks): 1 point\n• Win all 5 tricks: 2 points\n• Go alone and win 3–4: 1 point\n• Go alone and sweep all 5: 4 points\n• Get euchred (fail to make your bid): Opponents get 2 points. Rough."
    ),
    Section(
        emoji: "🏆",
        heading: "Winning",
        body: "First team to 10 points wins. Some folks play to 5 or 7 if they're in a hurry, or to 15 if they have absolutely nowhere to be."
    ),
]
