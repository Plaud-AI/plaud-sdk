import PlaudDeviceBasicSDK
import UIKit

@objc class ScanDeviceViewController: UIViewController {
    // MARK: - Properties

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var devices: [BleDevice] = []
    private let deviceAgent = PlaudDeviceAgent.shared

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }

    func onScanResult(bleDevices: [BleDevice]) {
        devices.removeAll()
        devices.append(contentsOf: bleDevices)
        tableView.reloadData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        title = NSLocalizedString("ble.scan.title", comment: "")

        // Set navigation bar style
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
        ]

        // Add refresh button
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshButtonTapped)
        )
        navigationItem.rightBarButtonItem = refreshButton
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DeviceCell.self, forCellReuseIdentifier: "DeviceCell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Actions

    private func startScanning() {
        deviceAgent.startScan()
    }

    @objc private func refreshButtonTapped() {
        devices.removeAll()
        tableView.reloadData()
        startScanning()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ScanDeviceViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
        let device = devices[indexPath.row]
        cell.configure(with: device)
        cell.connectButtonTapped = { [weak self] in
            self?.connectToDevice(device)
        }
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - DeviceCell

class DeviceCell: UITableViewCell {
    static let identifier = "DeviceCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("common.connect", comment: ""), for: .normal)
        button.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var connectButtonTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(infoLabel)
        containerView.addSubview(connectButton)

        connectButton.addTarget(self, action: #selector(connectButtonAction), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: connectButton.leadingAnchor, constant: -16),

            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            infoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: connectButton.leadingAnchor, constant: -16),
            infoLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),

            connectButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            connectButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            connectButton.widthAnchor.constraint(equalToConstant: 80),
            connectButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    func configure(with device: BleDevice) {
        nameLabel.text = device.name
        infoLabel.text = String(format: NSLocalizedString("ble.device.signal_strength", comment: ""), device.rssi)
    }

    @objc private func connectButtonAction() {
        connectButtonTapped?()
    }
}

// MARK: - Device Connection

extension ScanDeviceViewController {
    private func connectToDevice(_: BleDevice) {
//        deviceAgent.connect(to: device) { [weak self] success in
//            if success {
//                self?.navigationController?.popViewController(animated: true)
//            } else {
//                // Show connection failed message
//                let alert = UIAlertController(
//                    title: NSLocalizedString("device.connection.failed.title", comment: ""),
//                    message: NSLocalizedString("device.connection.failed.message", comment: ""),
//                    preferredStyle: .alert
//                )
//                alert.addAction(UIAlertAction(title: NSLocalizedString("common.confirm", comment: ""), style: .default))
//                self?.present(alert, animated: true)
//            }
//        }
    }
}
