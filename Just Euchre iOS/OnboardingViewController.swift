//
//  OnboardingViewController.swift
//  Just Euchre iOS
//

import UIKit

final class OnboardingViewController: UIViewController {

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
        pc.numberOfPages = onboardingSections.count
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

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
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

        for section in onboardingSections {
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
                                              multiplier: CGFloat(onboardingSections.count)),
        ])
    }

    private func makePage(_ section: OnboardingSection) -> UIView {
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
        let isLast = currentPage == onboardingSections.count - 1
        let title = isLast ? "Let's Play" : "Next"
        actionButton.setTitle(title, for: .normal)
        pageControl.currentPage = currentPage
    }

    @objc private func didTapAction() {
        if currentPage < onboardingSections.count - 1 {
            currentPage += 1
            let offset = CGPoint(x: scrollView.bounds.width * CGFloat(currentPage), y: 0)
            scrollView.setContentOffset(offset, animated: true)
        } else {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            guard let window = view.window else { return }

            let blackout = UIView(frame: window.bounds)
            blackout.backgroundColor = .black
            blackout.alpha = 0
            window.addSubview(blackout)

            UIView.animate(withDuration: 0.4, animations: {
                blackout.alpha = 1
            }, completion: { _ in
                window.rootViewController = RootTabBarController()
                UIView.animate(withDuration: 0.4) {
                    blackout.alpha = 0
                } completion: { _ in
                    blackout.removeFromSuperview()
                }
            })
        }
    }
}

// MARK: - UIScrollViewDelegate

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentPage = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
    }
}

// MARK: - Content

private struct OnboardingSection {
    let emoji: String
    let heading: String
    let body: String
}

private let onboardingSections: [OnboardingSection] = [
    OnboardingSection(
        emoji: "🃏",
        heading: "Just Euchre",
        body: "One game a day. No frills.\nJust the best card game ever made."
    ),
    OnboardingSection(
        emoji: "📅",
        heading: "One Game a Day",
        body: "You get one game every day. Come back tomorrow for a fresh deal. Build your streak — and your reputation."
    ),
    OnboardingSection(
        emoji: "🎯",
        heading: "The Goal",
        body: "Win at least 3 out of 5 tricks per round. You and your partner play against two bots. First team to 10 points wins."
    ),
    OnboardingSection(
        emoji: "👑",
        heading: "Trump Rules Everything",
        body: "Each round, one suit is trump. The Jack of that suit — the Right Bower — is the most powerful card in the game."
    ),
    OnboardingSection(
        emoji: "🙋",
        heading: "You Call the Shots",
        body: "After the deal, you can name the trump suit or pass. Name it, and you're on the hook to win at least 3 tricks."
    ),
    OnboardingSection(
        emoji: "🦅",
        heading: "Go Alone",
        body: "Feeling bold? Drop your partner and go solo. Win all 5 tricks alone and score 4 points. Big risk, big flex."
    ),
    OnboardingSection(
        emoji: "💡",
        heading: "Need a Refresher?",
        body: "Tap Settings anytime for the full rules. You can also set your name and emoji avatar from there."
    ),
]
