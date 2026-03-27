//
//  HowToPlayViewController.swift
//  Just Euchre iOS
//

import UIKit

final class HowToPlayViewController: UIViewController {

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)

    private var currentPage = 0 {
        didSet { updatePage(animated: true) }
    }

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.delegate = self
        sv.bounces = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = sections.count
        pc.currentPage = 0
        pc.currentPageIndicatorTintColor = .white
        pc.pageIndicatorTintColor = UIColor(white: 1, alpha: 0.25)
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    private lazy var actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
        return btn
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        btn.tintColor = UIColor(white: 0.45, alpha: 1)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()
        updatePage(animated: false)
    }

    private func buildUI() {
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(actionButton)
        view.addSubview(closeButton)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -18),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            actionButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -32),
            actionButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 54),

            pageControl.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -8),
        ])

        buildPages()
    }

    private func buildPages() {
        let pagesStack = UIStackView()
        pagesStack.axis = .horizontal
        pagesStack.alignment = .fill
        pagesStack.distribution = .fillEqually
        pagesStack.translatesAutoresizingMaskIntoConstraints = false

        for section in sections {
            pagesStack.addArrangedSubview(makePage(section))
        }

        scrollView.addSubview(pagesStack)
        NSLayoutConstraint.activate([
            pagesStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            pagesStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            pagesStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                              multiplier: CGFloat(sections.count)),
        ])
    }

    private func makePage(_ section: Section) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let emojiLabel = UILabel()
        emojiLabel.text = section.emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 72)
        emojiLabel.textAlignment = .center

        let headingLabel = UILabel()
        headingLabel.text = section.heading
        headingLabel.textColor = .white
        headingLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        headingLabel.textAlignment = .center
        headingLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = section.body
        bodyLabel.textColor = UIColor(white: 0.72, alpha: 1)
        bodyLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping

        let stack = UIStackView(arrangedSubviews: [emojiLabel, headingLabel, bodyLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 36),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -36),
        ])

        return container
    }

    private func updatePage(animated: Bool) {
        let isLast = currentPage == sections.count - 1
        actionButton.setTitle(isLast ? "Done" : "Next", for: .normal)
        pageControl.currentPage = currentPage
    }

    @objc private func didTapAction() {
        if currentPage < sections.count - 1 {
            currentPage += 1
            let offset = CGPoint(x: scrollView.bounds.width * CGFloat(currentPage), y: 0)
            scrollView.setContentOffset(offset, animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension HowToPlayViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentPage = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
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
        body: "Starting left of the dealer, each player can \"order it up\" to accept that card's suit as trump — or pass. If ordered up, the dealer pockets it and discards a card.\n\nIf everyone passes, go around again. Now anyone can name any other suit as trump."
    ),
    Section(
        emoji: "🦅",
        heading: "Going Alone",
        body: "Feeling brave? You can ditch your partner and go solo. Win all 5 tricks by yourself and you score 4 points. It's a big swing, but it's a big flex."
    ),
    Section(
        emoji: "🔄",
        heading: "Playing Tricks",
        body: "The player to the left of the dealer leads the first trick. You must follow suit if you can. If you can't, play anything — trump or otherwise.\n\nHighest card of the led suit wins, unless someone played trump. Highest trump wins over everything."
    ),
    Section(
        emoji: "📊",
        heading: "Scoring",
        body: "Make your bid (3–4 tricks): 1 point\nWin all 5 tricks: 2 points\nGo alone and win 3–4: 1 point\nGo alone and sweep all 5: 4 points\nGet euchred: opponents get 2 points. Rough."
    ),
    Section(
        emoji: "🏆",
        heading: "Winning",
        body: "First team to 10 points wins. Some folks play to 5 or 7 if they're in a hurry, or to 15 if they have absolutely nowhere to be."
    ),
]
