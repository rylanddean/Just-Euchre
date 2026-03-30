//
//  PartnerIntroViewController.swift
//  Just Euchre iOS
//
//  Shown as a full-screen modal before the first hand of a new game.
//  Introduces the partner persona — name, personality, and opening quip.
//  Dismisses via "Let's Play" CTA which triggers the game start callback.
//

import UIKit

final class PartnerIntroViewController: UIViewController {

    /// Called when the user taps "Let's Play" — game should start after this.
    var onReady: (() -> Void)?

    private let persona: PartnerPersona

    // MARK: - Views

    private let backgroundView = UIView()
    private let cardView       = UIView()
    private let emojiLabel     = UILabel()
    private let taglineBadge   = UIView()
    private let taglineLabel   = UILabel()
    private let nameLabel      = UILabel()
    private let partnerLabel   = UILabel()
    private let quoteLabel     = UILabel()
    private let ctaButton      = UIButton(type: .system)

    // Colors matching the app theme
    private let bg      = UIColor(red: 8/255,  green: 11/255, blue: 18/255,  alpha: 1)
    private let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255,  alpha: 1)
    private let pill    = UIColor(red: 22/255, green: 28/255, blue: 38/255,  alpha: 1)
    private let mint    = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)
    private let border  = UIColor(white: 0.28, alpha: 1)
    private let muted   = UIColor(white: 0.72, alpha: 1)

    // MARK: - Init

    init(persona: PartnerPersona) {
        self.persona = persona
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - Build

    private func buildUI() {
        // Dimmed full-screen background
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Floating card
        cardView.backgroundColor = surface
        cardView.layer.cornerRadius = 20
        cardView.layer.borderWidth  = 1
        cardView.layer.borderColor  = border.cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            cardView.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),
        ])

        // "YOUR PARTNER" eyebrow
        partnerLabel.text = "YOUR PARTNER"
        partnerLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        partnerLabel.letterSpacing(1.8)
        partnerLabel.textColor = muted
        partnerLabel.textAlignment = .center
        partnerLabel.translatesAutoresizingMaskIntoConstraints = false

        // Emoji avatar
        emojiLabel.text = persona.emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 64)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false

        // Partner name
        nameLabel.text = persona.name
        nameLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Tagline badge (pill)
        taglineBadge.backgroundColor = pill
        taglineBadge.layer.cornerRadius = 12
        taglineBadge.layer.borderWidth  = 1
        taglineBadge.layer.borderColor  = border.cgColor
        taglineBadge.translatesAutoresizingMaskIntoConstraints = false

        taglineLabel.text = persona.tagline
        taglineLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        taglineLabel.textColor = muted
        taglineLabel.textAlignment = .center
        taglineLabel.numberOfLines = 2
        taglineLabel.adjustsFontSizeToFitWidth = true
        taglineLabel.minimumScaleFactor = 0.8
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false

        taglineBadge.addSubview(taglineLabel)
        NSLayoutConstraint.activate([
            taglineLabel.topAnchor.constraint(equalTo: taglineBadge.topAnchor, constant: 8),
            taglineLabel.bottomAnchor.constraint(equalTo: taglineBadge.bottomAnchor, constant: -8),
            taglineLabel.leadingAnchor.constraint(equalTo: taglineBadge.leadingAnchor, constant: 14),
            taglineLabel.trailingAnchor.constraint(equalTo: taglineBadge.trailingAnchor, constant: -14),
        ])

        // Opening quip
        quoteLabel.text = "\u{201C}\(persona.introLine)\u{201D}"
        quoteLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        quoteLabel.textColor = .white
        quoteLabel.textAlignment = .center
        quoteLabel.numberOfLines = 0
        quoteLabel.translatesAutoresizingMaskIntoConstraints = false

        // Divider
        let divider = UIView()
        divider.backgroundColor = border
        divider.translatesAutoresizingMaskIntoConstraints = false

        // CTA button
        ctaButton.setTitle("Let's Play", for: .normal)
        ctaButton.setTitleColor(.black, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        ctaButton.backgroundColor = mint
        ctaButton.layer.cornerRadius = 22
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 13, left: 32, bottom: 13, right: 32)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.addTarget(self, action: #selector(didTapReady), for: .touchUpInside)

        // Add to card
        cardView.addSubview(partnerLabel)
        cardView.addSubview(emojiLabel)
        cardView.addSubview(nameLabel)
        cardView.addSubview(taglineBadge)
        cardView.addSubview(quoteLabel)
        cardView.addSubview(divider)
        cardView.addSubview(ctaButton)

        let pad: CGFloat = 28
        NSLayoutConstraint.activate([
            partnerLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: pad),
            partnerLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            partnerLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: pad),
            partnerLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -pad),

            emojiLabel.topAnchor.constraint(equalTo: partnerLabel.bottomAnchor, constant: 20),
            emojiLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 10),
            nameLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: pad),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -pad),

            taglineBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            taglineBadge.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            taglineBadge.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: pad),
            taglineBadge.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -pad),

            divider.topAnchor.constraint(equalTo: taglineBadge.bottomAnchor, constant: 20),
            divider.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad),
            divider.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad),
            divider.heightAnchor.constraint(equalToConstant: 1),

            quoteLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 20),
            quoteLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad),
            quoteLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad),

            ctaButton.topAnchor.constraint(equalTo: quoteLabel.bottomAnchor, constant: 24),
            ctaButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            ctaButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -pad),
            ctaButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Start hidden for entrance animation
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88).translatedBy(x: 0, y: 24)
        backgroundView.alpha = 0
    }

    // MARK: - Animations

    private func animateIn() {
        UIView.animate(withDuration: 0.20, delay: 0, options: [.curveEaseOut]) {
            self.backgroundView.alpha = 1
        }
        UIView.animate(
            withDuration: 0.30,
            delay: 0.08,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.5,
            options: []
        ) {
            self.cardView.alpha = 1
            self.cardView.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn]) {
            self.backgroundView.alpha = 0
            self.cardView.alpha = 0
            self.cardView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92).translatedBy(x: 0, y: -12)
        } completion: { _ in
            completion()
        }
    }

    // MARK: - Actions

    @objc private func didTapReady() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        animateOut { [weak self] in
            self?.dismiss(animated: false) {
                self?.onReady?()
            }
        }
    }
}

// MARK: - UILabel helper

private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        if let text = text {
            let attributed = NSAttributedString(string: text, attributes: [
                .kern: spacing,
                .foregroundColor: textColor as Any,
                .font: font as Any,
            ])
            attributedText = attributed
        }
    }
}
