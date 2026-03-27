//
//  NotificationTimePickerViewController.swift
//  Just Euchre iOS
//
//  A minimal sheet that lets the user pick what time to receive their
//  daily euchre reminder.
//

import UIKit

final class NotificationTimePickerViewController: UIViewController {

    var onTimeSaved: ((Int, Int) -> Void)?

    private let background = UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1)
    private let surface    = UIColor(red: 26/255, green: 33/255, blue: 44/255, alpha: 1)
    private let accent     = UIColor(red: 82/255, green: 246/255, blue: 170/255, alpha: 1)

    private let titleLabel  = UILabel()
    private let picker      = UIDatePicker()
    private let saveButton  = UIButton(type: .system)

    init(hour: Int, minute: Int) {
        super.init(nibName: nil, bundle: nil)

        var components = DateComponents()
        components.hour   = hour
        components.minute = minute
        if let date = Calendar.current.date(from: components) {
            picker.date = date
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        buildUI()
    }

    private func buildUI() {
        titleLabel.text = "Reminder Time"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.overrideUserInterfaceStyle = .dark
        picker.translatesAutoresizingMaskIntoConstraints = false

        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        saveButton.setTitleColor(UIColor(red: 8/255, green: 11/255, blue: 18/255, alpha: 1), for: .normal)
        saveButton.backgroundColor = accent
        saveButton.layer.cornerRadius = 14
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        view.addSubview(titleLabel)
        view.addSubview(picker)
        view.addSubview(saveButton)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),

            picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            picker.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: safe.trailingAnchor),

            saveButton.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            saveButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    @objc private func didTapSave() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: picker.date)
        let hour   = components.hour ?? 8
        let minute = components.minute ?? 0
        onTimeSaved?(hour, minute)
        dismiss(animated: true)
    }
}
