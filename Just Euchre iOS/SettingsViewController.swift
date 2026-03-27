//
//  SettingsViewController.swift
//  Just Euchre iOS
//

import StoreKit
import UIKit

final class SettingsViewController: UIViewController {

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
    private let surface = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
    private let border = UIColor(white: 0.28, alpha: 1)

    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()

        NotificationCenter.default.addObserver(self, selector: #selector(dailyDidChange), name: DailyGameStore.didChangeNotification, object: nil)
    }

    private func buildUI() {
        titleLabel.text = "Settings"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        contentStack.spacing = 14
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

        contentStack.addArrangedSubview(sectionTitle("Player"))
        let playerRow = SettingsRowView(surface: surface, border: border)
        playerRow.configure(title: "Profile", subtitle: "\(ProfileStore.emoji) \(ProfileStore.name)", icon: "person.circle", showsChevron: true)
        playerRow.onTap = { [weak self] in
            let vc = ProfileViewController()
            vc.modalPresentationStyle = .pageSheet
            self?.present(vc, animated: true)
        }
        contentStack.addArrangedSubview(playerRow)

        contentStack.addArrangedSubview(sectionTitle("Card Packs"))
        let packsRow = SettingsRowView(surface: surface, border: border)
        packsRow.configure(title: "Card packs", subtitle: "Coming soon", icon: "rectangle.stack.fill", showsChevron: false)
        packsRow.isUserInteractionEnabled = false
        packsRow.alpha = 0.85
        contentStack.addArrangedSubview(packsRow)

        contentStack.addArrangedSubview(sectionTitle("Support"))

        let coffeeRow = SettingsRowView(surface: surface, border: border)
        coffeeRow.configure(title: "Buy me a coffee", subtitle: "$2 in-app purchase", icon: "cup.and.saucer.fill", showsChevron: false)
        coffeeRow.onTap = { [weak self] in
            self?.purchaseCoffee()
        }
        contentStack.addArrangedSubview(coffeeRow)

        let feedbackRow = SettingsRowView(surface: surface, border: border)
        feedbackRow.configure(title: "Feedback", subtitle: "Send a note", icon: "envelope.fill", showsChevron: true)
        feedbackRow.onTap = { [weak self] in
            self?.openFeedbackEmail()
        }
        contentStack.addArrangedSubview(feedbackRow)

        contentStack.addArrangedSubview(sectionTitle("About"))

        let versionRow = SettingsRowView(surface: surface, border: border)
        versionRow.configure(title: "App version", subtitle: appVersionText(), icon: "app", showsChevron: false)
        versionRow.alpha = 0.95
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressVersionRow(_:)))
        longPress.minimumPressDuration = 0.9
        versionRow.addGestureRecognizer(longPress)
        contentStack.addArrangedSubview(versionRow)

        let devRow = SettingsRowView(surface: surface, border: border)
        devRow.configure(title: "Developer", subtitle: "Ryland Dean", icon: "hammer.fill", showsChevron: false)
        devRow.onTap = { [weak self] in
            self?.showDeveloperProfile()
        }
        contentStack.addArrangedSubview(devRow)

        let socialsRow = SettingsRowView(surface: surface, border: border)
        socialsRow.configure(title: "Socials", subtitle: "Open links", icon: "link", showsChevron: true)
        socialsRow.onTap = { [weak self] in
            self?.openSocials()
        }
        contentStack.addArrangedSubview(socialsRow)
    }

    private func sectionTitle(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title.uppercased()
        label.textColor = UIColor(white: 0.72, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        return label
    }

    private func appVersionText() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    @objc private func dailyDidChange() {
        // Keep Player subtitle (and future items) fresh.
        buildSections()
    }

    // MARK: - Actions

    private func openFeedbackEmail() {
        let subject = "Just Euchre feedback"
        let body = "Device: iOS\nApp: \(appVersionText())\n\nFeedback:\n"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body
        // No hardcoded recipient; let the user choose.
        let urlString = "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func showDeveloperProfile() {
        let alert = UIAlertController(
            title: "Developer",
            message: "Made by Ryland Dean.\n\nThanks for playing Just Euchre.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func openSocials() {
        // Add your links here when you’re ready.
        let links: [(String, URL)] = []

        guard !links.isEmpty else {
            let alert = UIAlertController(title: "Socials", message: "No socials configured yet.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let sheet = UIAlertController(title: "Socials", message: nil, preferredStyle: .actionSheet)
        links.forEach { title, url in
            sheet.addAction(UIAlertAction(title: title, style: .default) { _ in
                UIApplication.shared.open(url)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func purchaseCoffee() {
        Task { @MainActor in
            do {
                let result = try await CoffeePurchase.purchase()
                switch result {
                case .success:
                    showToast("Thanks for the coffee.")
                case .cancelled:
                    break
                case .notConfigured:
                    showToast("Coffee purchase isn’t configured yet.")
                }
            } catch {
                showToast("Purchase failed.")
            }
        }
    }

    private func showToast(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak alert] in
            alert?.dismiss(animated: true)
        }
    }

    @objc private func didLongPressVersionRow(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }

        let sheet = UIAlertController(
            title: "Developer Tools",
            message: "Reset local state for testing.",
            preferredStyle: .actionSheet
        )

        sheet.addAction(UIAlertAction(title: "Reset today’s game", style: .destructive) { [weak self] _ in
            GameStateStore.clear()
            DailyGameStore.debugResetToday()
            self?.showToast("Today’s game reset.")
        })

        sheet.addAction(UIAlertAction(title: "Reset all local data", style: .destructive) { [weak self] _ in
            GameStateStore.clear()
            GameHistoryStore.clear()
            DailyGameStore.debugResetAll()
            ProfileStore.clear()
            self?.showToast("Local data reset.")
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}

private enum CoffeePurchase {
    enum Result {
        case success
        case cancelled
        case notConfigured
    }

    // Set this to your App Store Connect product id when ready.
    private static let productId = "justeuchre.coffee_2"

    static func purchase() async throws -> Result {
        let products = try await Product.products(for: [productId])
        guard let product = products.first else { return .notConfigured }

        let result = try await product.purchase()
        switch result {
        case .success:
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }
}

private final class SettingsRowView: UIControl {
    private let surface: UIColor
    private let border: UIColor

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    var onTap: (() -> Void)?

    init(surface: UIColor, border: UIColor) {
        self.surface = surface
        self.border = border
        super.init(frame: .zero)

        backgroundColor = surface
        layer.cornerRadius = 22
        layer.borderWidth = 1
        layer.borderColor = border.cgColor

        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        subtitleLabel.textColor = UIColor(white: 0.72, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)

        chevron.tintColor = UIColor(white: 0.45, alpha: 1)
        chevron.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        [iconView, textStack, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 72),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -12),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16),
        ])

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String, icon: String, showsChevron: Bool) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        chevron.isHidden = !showsChevron
    }

    @objc private func didTap() {
        onTap?()
    }
}
