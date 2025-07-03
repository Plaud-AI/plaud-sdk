import UIKit

class ProgressAlertController: UIViewController {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0 // Allow title line wrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        progress.trackTintColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0 // Allow progress text line wrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("progress.alert.cancel", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("progress.alert.upload", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cancelButton, uploadButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0 // Initially hidden
        return button
    }()

    var onCancel: (() -> Void)?
    var onUpload: (() -> Void)?

    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        titleLabel.text = title
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(progressLabel)
        containerView.addSubview(buttonStackView)
        containerView.addSubview(closeButton)

        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 280), // Minimum width
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40), // Maximum width
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            progressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            buttonStackView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
        ])
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }

    @objc private func uploadButtonTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onUpload?()
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    func updateProgress(_ progress: Float, text: String? = nil) {
        progressView.progress = progress
        if let text = text {
            progressLabel.text = String(format: NSLocalizedString("progress.alert.progress_format", comment: ""), text, Int(progress * 100))
        } else {
            progressLabel.text = String(format: NSLocalizedString("progress.alert.progress_only", comment: ""), Int(progress * 100))
        }

        if Int(progress * 100) == 100 {
            setCancelButtonTitle(NSLocalizedString("progress.alert.view", comment: ""))
            cancelButton.isHidden = false
            uploadButton.isHidden = false
            buttonStackView.layoutIfNeeded()
            UIView.animate(withDuration: 0.25) {
                self.closeButton.alpha = 1.0
            }
        } else {
            setCancelButtonTitle(NSLocalizedString("progress.alert.cancel", comment: ""))
            cancelButton.isHidden = false
            uploadButton.isHidden = true
            buttonStackView.layoutIfNeeded()
        }
    }

    func setCancelButtonTitle(_ title: String) {
        cancelButton.setTitle(title, for: .normal)
    }
}
