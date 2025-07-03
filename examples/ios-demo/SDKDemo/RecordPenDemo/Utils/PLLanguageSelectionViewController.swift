import UIKit

@objc protocol PLLanguageSelectionDelegate: AnyObject {
    func languageDidChange()
}

@objc class PLLanguageSelectionViewController: UIViewController {
    @objc weak var delegate: PLLanguageSelectionDelegate?

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("language.select", comment: "")
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let englishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("English", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.tag = PLLanguageType.english.rawValue
        return button
    }()

    private let chineseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Simplified Chinese", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.tag = PLLanguageType.simplifiedChinese.rawValue
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("common.cancel", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateButtonStyles()
        updateButtonTexts()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(englishButton)
        containerView.addSubview(chineseButton)
        containerView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            containerView.heightAnchor.constraint(equalToConstant: 200),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),

            englishButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            englishButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            englishButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            englishButton.heightAnchor.constraint(equalToConstant: 44),

            chineseButton.topAnchor.constraint(equalTo: englishButton.bottomAnchor, constant: 8),
            chineseButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            chineseButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            chineseButton.heightAnchor.constraint(equalToConstant: 44),

            cancelButton.topAnchor.constraint(equalTo: chineseButton.bottomAnchor, constant: 4),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func setupActions() {
        englishButton.addTarget(self, action: #selector(languageButtonTapped(_:)), for: .touchUpInside)
        chineseButton.addTarget(self, action: #selector(languageButtonTapped(_:)), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }

    private func updateButtonStyles() {
        let currentLanguage = PLLanguageManager.shared().currentLanguage

        englishButton.backgroundColor = currentLanguage == .english ? .systemBlue : .clear
        englishButton.setTitleColor(currentLanguage == .english ? .white : .systemBlue, for: .normal)
        englishButton.layer.borderWidth = currentLanguage == .english ? 0 : 1

        chineseButton.backgroundColor = currentLanguage == .simplifiedChinese ? .systemBlue : .clear
        chineseButton.setTitleColor(currentLanguage == .simplifiedChinese ? .white : .systemBlue, for: .normal)
        chineseButton.layer.borderWidth = currentLanguage == .simplifiedChinese ? 0 : 1
    }

    private func updateButtonTexts() {
        titleLabel.text = NSLocalizedString("language.select", comment: "")
        cancelButton.setTitle(NSLocalizedString("common.cancel", comment: ""), for: .normal)
    }

    @objc private func languageButtonTapped(_ sender: UIButton) {
        let language = PLLanguageType(rawValue: sender.tag) ?? .english
        PLLanguageManager.shared().switch(language) { [weak self] in
            self?.updateButtonStyles()
            self?.dismiss(animated: true)
        }
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
}
