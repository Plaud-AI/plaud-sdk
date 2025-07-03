import PlaudDeviceBasicSDK
import UIKit

// import FirebaseAnalytics

@objc class DeviceInfoViewController: UIViewController {
    // MARK: - Properties

    private let device: BleDevice
    private let deviceAgent = PlaudDeviceAgent.shared
    private var recordList = [BleFile]()
    private var downlodingFileInfo: BleFile? = nil
    private var downloadedFiles: [String: String] = [:]

    // Toast View
    private var toastView: UIView?
    private var toastLabel: UILabel?
    private var progressAlert: ProgressAlertController?

    private var manualGet: Bool = false

    // Basic information area
    private let infoContainerView: UIView = {
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

    // USB disk access switch
    private let udiskAccessLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("device.info.udisk_access", comment: "")
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        return label
    }()

    private let udiskAccessSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        return switchControl
    }()

    // New: USB disk access horizontal stack
    private lazy var udiskAccessStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [udiskAccessLabel, udiskAccessSwitch])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // USB disk mode warning label
    private let udiskModeWarningLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("device.warning.udisk_mode_active", comment: "")
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let deviceNameLabel = InfoItemView(title: NSLocalizedString("device.info.name", comment: ""))
    private let snLabel = InfoItemView(title: NSLocalizedString("device.info.sn", comment: ""))
    // Firmware version
    private let firmwareLabel = InfoItemView(title: NSLocalizedString("device.info.firmware", comment: ""))
    private let storageLabel = InfoItemView(title: NSLocalizedString("device.info.storage", comment: ""))
    private let batteryLabel = InfoItemView(title: NSLocalizedString("device.info.battery", comment: ""))

    // Action panel area
    private let actionContainerView: UIView = {
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

    private let actionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let horizontalStackView1: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let horizontalStackView2: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let horizontalStackView3: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let horizontalStackView4: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Action Buttons

    private lazy var startRecordButton = createActionButton(title: NSLocalizedString("device.action.start_record", comment: ""), bgColor: UIColor(red: 39 / 255, green: 174 / 255, blue: 96 / 255, alpha: 1), textColor: .white)
    private lazy var pauseRecordButton = createActionButton(title: NSLocalizedString("device.action.pause_record", comment: ""), bgColor: UIColor(red: 243 / 255, green: 156 / 255, blue: 18 / 255, alpha: 1), textColor: .white)
    private lazy var resumeRecordButton = createActionButton(title: NSLocalizedString("device.action.resume_record", comment: ""), bgColor: UIColor(red: 41 / 255, green: 128 / 255, blue: 239 / 255, alpha: 1), textColor: .white)
    private lazy var stopRecordButton = createActionButton(title: NSLocalizedString("device.action.stop_record", comment: ""), bgColor: UIColor(red: 231 / 255, green: 76 / 255, blue: 60 / 255, alpha: 1), textColor: .white)
    private lazy var getFileListButton = createActionButton(title: NSLocalizedString("device.action.get_file_list", comment: ""))
    private lazy var syncFileButton = createActionButton(title: NSLocalizedString("device.action.sync_file", comment: ""))
    private lazy var deleteFileButton = createActionButton(title: NSLocalizedString("device.action.delete_file", comment: ""))
    private lazy var deleteAllFilesButton = createActionButton(title: NSLocalizedString("device.action.delete_all_files", comment: ""), bgColor: UIColor(red: 231 / 255, green: 76 / 255, blue: 60 / 255, alpha: 1), textColor: .white)
    private lazy var downloadTranscodedButton = createActionButton(title: NSLocalizedString("device.action.download_transcoded", comment: ""))

    // New area buttons
    private lazy var associateUserButton = createActionButton(title: NSLocalizedString("device.action.associate_user", comment: ""))
    private lazy var wifiSettingButton = createActionButton(title: NSLocalizedString("device.action.wifi_setting", comment: ""))

    // New audio player button
    private lazy var audioPlayerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("device.action.audio_player", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        button.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(audioPlayerButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    @objc init(device: BleDevice) {
        self.device = device
        super.init(nibName: nil, bundle: nil)

        // Initialize switch state
        udiskAccessSwitch.isOn = device.privacy == 0
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        deviceAgent.delegate = self
        setupUI()
        updateDeviceInfo()
        setupToastView()
        setupNavigationBarButtons()

        // deviceAgent.getChargingState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.deviceAgent.getChargingState()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // If there's currently a Toast being displayed, let it complete its display
        if let toastView = toastView, toastView.alpha > 0 {
            // Cancel previous auto-hide operations
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideToast), object: nil)
            // Set new auto-hide time to ensure complete display
            perform(#selector(hideToast), with: nil, afterDelay: 2.5)
        } else {
            // If no Toast is displaying, clean up normally
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideToast), object: nil)
            hideToast()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let navController = navigationController {
            let allViewControllers = navController.viewControllers
            if let topVC = navController.topViewController {
                let hasScanVC = topVC is ScanDeviceViewController
                if hasScanVC == true {
                    deviceAgent.disconnect()
                }
            }
        } else {
            deviceAgent.disconnect()
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        title = NSLocalizedString("device.info.title", comment: "")

        setupInfoSection()
        setupActionSection()
        setupConstraints()
    }

    private func setupInfoSection() {
        view.addSubview(infoContainerView)

        let stackView = UIStackView(arrangedSubviews: [
            deviceNameLabel,
            snLabel,
            firmwareLabel,
            storageLabel,
            batteryLabel,
            udiskAccessStackView,
            udiskModeWarningLabel,
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        infoContainerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: -16),
        ])

        // Add switch event handling
        udiskAccessSwitch.addTarget(self, action: #selector(udiskAccessSwitchChanged(_:)), for: .valueChanged)
    }

    private func setupActionSection() {
        view.addSubview(actionContainerView)
        actionContainerView.addSubview(actionStackView)

        // New horizontal stack view
        let horizontalStackView5: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.spacing = 12
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()

        horizontalStackView5.addArrangedSubview(associateUserButton)
        horizontalStackView5.addArrangedSubview(wifiSettingButton)

        horizontalStackView1.addArrangedSubview(startRecordButton)
        horizontalStackView1.addArrangedSubview(pauseRecordButton)

        horizontalStackView2.addArrangedSubview(stopRecordButton)
        horizontalStackView2.addArrangedSubview(resumeRecordButton)

        horizontalStackView3.addArrangedSubview(getFileListButton)
        horizontalStackView3.addArrangedSubview(deleteFileButton)

        horizontalStackView4.addArrangedSubview(downloadTranscodedButton)
        horizontalStackView4.addArrangedSubview(syncFileButton)

        // Add stack view for transcoding button
        let horizontalStackView6: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.spacing = 12
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()

        horizontalStackView6.addArrangedSubview(deleteAllFilesButton)

        // Add all views to main stack
        actionStackView.addArrangedSubview(horizontalStackView5)
        actionStackView.addArrangedSubview(horizontalStackView1)
        actionStackView.addArrangedSubview(horizontalStackView2)
        actionStackView.addArrangedSubview(horizontalStackView3)
        actionStackView.addArrangedSubview(horizontalStackView4)
        actionStackView.addArrangedSubview(horizontalStackView6)

        NSLayoutConstraint.activate([
            actionStackView.topAnchor.constraint(equalTo: actionContainerView.topAnchor, constant: 16),
            actionStackView.leadingAnchor.constraint(equalTo: actionContainerView.leadingAnchor, constant: 16),
            actionStackView.trailingAnchor.constraint(equalTo: actionContainerView.trailingAnchor, constant: -16),
            actionStackView.bottomAnchor.constraint(equalTo: actionContainerView.bottomAnchor, constant: -16),
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            infoContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            infoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            actionContainerView.topAnchor.constraint(equalTo: infoContainerView.bottomAnchor, constant: 12),
            actionContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionContainerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Helper Methods

    private func createActionButton(title: String, bgColor: UIColor, textColor: UIColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        button.backgroundColor = bgColor
        button.setTitleColor(textColor, for: .normal)
        if bgColor == .white {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        }

        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    private func createActionButton(title: String, textColor: UIColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)) -> UIButton {
        return createActionButton(title: title, bgColor: .white, textColor: textColor)
    }

    private func updateDeviceInfo() {
        deviceNameLabel.setValue(device.name)
        snLabel.setValue(device.serialNumber)
        firmwareLabel.setValue(device.wholeVersion())
        storageLabel.setValue("-- GB / -- GB")
        batteryLabel.setValue("--")
    }

    // MARK: - Actions

    @objc private func actionButtonTapped(_ sender: UIButton) {
        switch sender {
        case startRecordButton:
            deviceAgent.startRecord()
        case pauseRecordButton:
            deviceAgent.pauseRecord()
        case resumeRecordButton:
            deviceAgent.resumeRecord()
        case stopRecordButton:
            deviceAgent.stopRecord()
        case getFileListButton:
            getFileList(button: sender)
        case syncFileButton:
            cloudSync(button: sender)
        case deleteFileButton:
            deleteFile(button: sender)
        case deleteAllFilesButton:
            deviceAgent.clearAllFiles()
        case associateUserButton:
            showAssociateUserDialog()
        case wifiSettingButton:
            goWifiSettingPage(button: sender)
        case downloadTranscodedButton:
            downloadTranscoded(button: sender)
        case audioPlayerButton:
            audioPlayerButtonTapped()
        default:
            break
        }
    }

    @objc private func cloudSync(button _: UIButton) {
        let vc = CloudSyncViewController(device: device)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func getFileList(button _: UIButton) {
        guard !deviceAgent.checkIsRecording() else {
            showToastWithMessage(NSLocalizedString("device.error.recording_in_progress", comment: ""))
            return
        }

        manualGet = true
        deviceAgent.getFileList(startSessionId: 0)
    }

    @objc private func goWifiSettingPage(button _: UIButton) {
        let vc = PlaudWifiSettingPage()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func downloadTranscoded(button _: UIButton) {
        guard !deviceAgent.checkIsRecording() else {
            showToastWithMessage(NSLocalizedString("device.error.recording_download_only", comment: ""))
            return
        }

        guard recordList.count > 0 else {
            showToastWithMessage(NSLocalizedString("device.error.get_file_list_first", comment: ""))
            return
        }

        let title = NSLocalizedString("device.dialog.file_count", comment: "").replacingOccurrences(of: "{count}", with: "\(recordList.count)")
        showRecordSelectDialog(title: title) { [weak self] bleFile in
            guard let `self` = self, let bleFile = bleFile else {
                return
            }

            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let fileName = "\(bleFile.sessionId)_download"

            let targetPath = (documentsPath as NSString).appendingPathComponent(fileName)

            // Show progress bar popup
            self.progressAlert = ProgressAlertController(title: NSLocalizedString("device.progress.downloading_transcoded", comment: ""))
            self.progressAlert?.onCancel = { [weak self] in
                self?.deviceAgent.stopDownloadFile()
            }
            self.progressAlert?.onUpload = { [weak self] in
                let filePath = "\(targetPath).mp3"
                if FileManager.default.fileExists(atPath: filePath) {
                    // First close current download progress popup
                    self?.progressAlert?.dismiss(animated: true) {
                        // Show upload progress popup after download popup is closed
                        PlaudFileUploader.shared.device = self?.device

                        // Show upload progress popup
                        let uploadProgressAlert = UploadProgressAlertController(title: NSLocalizedString("upload.progress.title", comment: ""))
                        uploadProgressAlert.onCancel = {
                            // TODO: Need to call PlaudFileUploader's cancel upload method here
                            uploadProgressAlert.dismiss(animated: true)
                        }
                        self?.present(uploadProgressAlert, animated: true)

                        PlaudFileUploader.shared.uploadRecording(
                            sn: bleFile.sn,
                            sessionId: bleFile.sessionId,
                            onProgress: { progress in
                                // Update upload progress
                                DispatchQueue.main.async {
                                    uploadProgressAlert.updateProgress(Float(progress))
                                }
                            },
                            completion: { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success:
                                        // Upload successful
                                        uploadProgressAlert.updateProgress(1.0, text: NSLocalizedString("upload.progress.success", comment: ""))
                                        uploadProgressAlert.setActionButtonAsConfirm()
                                        uploadProgressAlert.onConfirm = {
                                            uploadProgressAlert.dismiss(animated: true)
                                        }
                                    case .failure:
                                        uploadProgressAlert.updateProgress(0.0, text: NSLocalizedString("upload.progress.failed", comment: ""))
                                        uploadProgressAlert.setActionButtonAsConfirm()
                                        uploadProgressAlert.onConfirm = {
                                            uploadProgressAlert.dismiss(animated: true)
                                        }
                                    }
                                }
                            }
                        )
                    }
                } else {
                    self?.showToastWithMessage(NSLocalizedString("device.error.audio_file_not_found", comment: ""))
                }
            }
            self.present(self.progressAlert!, animated: true)

            self.deviceAgent.downloadFile(sessionId: bleFile.sessionId, outputPath: targetPath)
        }
    }

    @objc private func covertAudioMp3(button _: UIButton) {
        // PLBleFileManager.shared.convertAllFilesToMp3()
    }

    @objc private func deleteFile(button _: UIButton) {
        guard !deviceAgent.checkIsRecording() else {
            showToastWithMessage(NSLocalizedString("device.error.cannot_delete_while_recording", comment: ""))
            return
        }

        let title = NSLocalizedString("device.dialog.file_count", comment: "").replacingOccurrences(of: "{count}", with: "\(recordList.count)")
        showRecordSelectDialog(title: title) { [weak self] bleFile in
            guard let `self` = self, let bleFile = bleFile else {
                return
            }
            self.deviceAgent.deleteFile(sessionId: bleFile.sessionId)
        }
    }

    private func syncFile() {
        guard !deviceAgent.checkIsRecording() else {
            showToastWithMessage(NSLocalizedString("device.error.recording_sync_only", comment: ""))
            return
        }

        guard recordList.count > 0 else {
            showToastWithMessage(NSLocalizedString("device.error.get_file_list_first", comment: ""))
            return
        }

        let title = NSLocalizedString("device.dialog.file_count", comment: "").replacingOccurrences(of: "{count}", with: "\(recordList.count)")
        showRecordSelectDialog(title: title) { [weak self] bleFile in
            guard let `self` = self, let bleFile = bleFile else {
                return
            }

            self.progressAlert = ProgressAlertController(title: NSLocalizedString("device.progress.downloading_stream", comment: ""))
            self.progressAlert?.onCancel = { [weak self] in
                self?.deviceAgent.stopSyncFile()
            }
            self.present(self.progressAlert!, animated: true)

            var size = self.getCurrentFileSize(sessionId: bleFile.sessionId)
            self.deviceAgent.syncFile(sessionId: bleFile.sessionId, start: 0, end: 0)
        }
    }

    private func showRecordSelectDialog(title: String, callback: @escaping (BleFile?) -> Void) {
        let optionController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        var idx = 0
        for bleFile in recordList {
            let title = NSLocalizedString("device.dialog.file_item", comment: "")
                .replacingOccurrences(of: "{index}", with: "\(idx)")
                .replacingOccurrences(of: "{fileId}", with: "\(bleFile.sessionId)")
                .replacingOccurrences(of: "{size}", with: formatFileSize(bleFile.size))
            idx += 1

            let action = UIAlertAction(title: title, style: .default) { _ in
                callback(bleFile)
            }
            optionController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel) { _ in
            callback(nil)
        }
        optionController.addAction(cancelAction)

        present(optionController, animated: true, completion: nil)
    }

    private func showDownloadedSelectDialog(title: String, callback: @escaping (String, String) -> Void) {
        let optionController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        var idx = 0
        for (id, path) in downloadedFiles {
            let title = NSLocalizedString("device.dialog.downloaded_file_item", comment: "")
                .replacingOccurrences(of: "{index}", with: "\(idx)")
                .replacingOccurrences(of: "{fileId}", with: id)
                .replacingOccurrences(of: "{path}", with: path)
            idx += 1
            let action = UIAlertAction(title: title, style: .default) { _ in
                callback(id, path)
            }
            optionController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel) { _ in
            callback("", "")
        }
        optionController.addAction(cancelAction)

        present(optionController, animated: true, completion: nil)
    }

    // MARK: - Toast Methods

    private func setupToastView() {
        if let toastView = toastView {
            toastView.removeFromSuperview()
            self.toastView = nil
        }

        toastView = UIView()
        toastView?.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastView?.layer.cornerRadius = 10
        toastView?.clipsToBounds = true
        toastView?.translatesAutoresizingMaskIntoConstraints = false
        toastView?.alpha = 0

        if let window = UIApplication.shared.keyWindow {
            window.addSubview(toastView!)
        }

        toastLabel = UILabel()
        toastLabel?.textColor = .white
        toastLabel?.font = .systemFont(ofSize: 15)
        toastLabel?.textAlignment = .center
        toastLabel?.numberOfLines = 0
        toastLabel?.translatesAutoresizingMaskIntoConstraints = false
        toastView?.addSubview(toastLabel!)

        NSLayoutConstraint.activate([
            toastView!.centerXAnchor.constraint(equalTo: UIApplication.shared.keyWindow!.centerXAnchor),
            toastView!.centerYAnchor.constraint(equalTo: UIApplication.shared.keyWindow!.centerYAnchor),
            toastView!.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
            toastView!.leadingAnchor.constraint(greaterThanOrEqualTo: UIApplication.shared.keyWindow!.leadingAnchor, constant: 40),
            toastView!.trailingAnchor.constraint(lessThanOrEqualTo: UIApplication.shared.keyWindow!.trailingAnchor, constant: -40),

            toastLabel!.topAnchor.constraint(equalTo: toastView!.topAnchor, constant: 12),
            toastLabel!.leadingAnchor.constraint(equalTo: toastView!.leadingAnchor, constant: 16),
            toastLabel!.trailingAnchor.constraint(equalTo: toastView!.trailingAnchor, constant: -16),
            toastLabel!.bottomAnchor.constraint(equalTo: toastView!.bottomAnchor, constant: -12),
        ])
    }

    func showToastWithMessage(_ message: String) {
        guard !message.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Cancel previous show and hide operations
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hideToast), object: nil)

            // Ensure toastView is initialized
            if self.toastView == nil {
                self.setupToastView()
            }

            // If currently showing animation, complete current animation first
            if self.toastView?.alpha ?? 0 > 0 {
                UIView.animate(withDuration: 0.15, animations: {
                    self.toastView?.alpha = 0.0
                }) { _ in
                    self.showNewToast(message)
                }
            } else {
                self.showNewToast(message)
            }
        }
    }

    private func showNewToast(_ message: String) {
        toastLabel?.text = message
        toastLabel?.sizeToFit()

        // Show animation
        UIView.animate(withDuration: 0.25, animations: {
            self.toastView?.alpha = 1.0
        }) { _ in
            // Auto hide after 2 seconds
            self.perform(#selector(self.hideToast), with: nil, afterDelay: 2.0)
        }
    }

    @objc private func hideToast() {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25, animations: {
                self?.toastView?.alpha = 0.0
            })
        }
    }

    // MARK: - Navigation Bar Setup

    private func setupNavigationBarButtons() {
        // Set title
        let titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("device.info.title", comment: "")
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleLabel)

        // Use auto layout constraints to ensure title is centered
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: titleContainer.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: titleContainer.trailingAnchor),
            titleContainer.widthAnchor.constraint(equalToConstant: 200),
            titleContainer.heightAnchor.constraint(equalToConstant: 44),
        ])

        navigationItem.titleView = titleContainer

        // Create vertical stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .trailing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Create disconnect button
        let disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle(NSLocalizedString("device.action.disconnect", comment: ""), for: .normal)
        disconnectButton.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 14)
        disconnectButton.addTarget(self, action: #selector(disconnectDeviceTapped), for: .touchUpInside)
        disconnectButton.contentHorizontalAlignment = .right

        // Create unbind button
        let unbindButton = UIButton(type: .system)
        unbindButton.setTitle(NSLocalizedString("device.action.unbind", comment: ""), for: .normal)
        unbindButton.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
        unbindButton.titleLabel?.font = .systemFont(ofSize: 14)
        unbindButton.addTarget(self, action: #selector(unbindDeviceTapped), for: .touchUpInside)
        unbindButton.contentHorizontalAlignment = .right

        // Add buttons to stack view
        stackView.addArrangedSubview(disconnectButton)
        stackView.addArrangedSubview(unbindButton)

        // Set button size constraints
        NSLayoutConstraint.activate([
            disconnectButton.heightAnchor.constraint(equalToConstant: 30),
            unbindButton.heightAnchor.constraint(equalToConstant: 30),
        ])

        // Create custom UIBarButtonItem
        let rightBarButton = UIBarButtonItem(customView: stackView)
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = -8 // Adjust right margin to make button closer to edge
        navigationItem.rightBarButtonItems = [spacer, rightBarButton]
    }

    // MARK: - Navigation Bar Actions

    @objc private func disconnectDeviceTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("device.dialog.disconnect.title", comment: ""),
            message: NSLocalizedString("device.dialog.disconnect.message", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.confirm", comment: ""), style: .destructive) { [weak self] _ in
            self?.deviceAgent.disconnect()
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }

    @objc private func unbindDeviceTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("device.dialog.unbind.title", comment: ""),
            message: NSLocalizedString("device.dialog.unbind.message", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.confirm", comment: ""), style: .destructive) { [weak self] _ in
            self?.deviceAgent.depair()
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }

    @objc private func audioPlayerButtonTapped() {
        // Get documents directory path
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

        // Show file selection dialog
        let title = NSLocalizedString("device.dialog.file_count", comment: "").replacingOccurrences(of: "{count}", with: "\(recordList.count)")
        showDownloadedSelectDialog(title: title) { [weak self] _, path in
            let filePath = "\(path).mp3"

            // Check if file exists
            if FileManager.default.fileExists(atPath: filePath) {
                let vc = PlaudAudioPlayerViewController(filePath: filePath)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                self?.showToastWithMessage(NSLocalizedString("device.error.audio_file_not_found", comment: ""))
            }
        }
    }

    // Add file size formatting method
    private func formatFileSize(_ bytes: Int) -> String {
        let kb = 1024.0
        let mb = kb * 1024.0
        let gb = mb * 1024.0

        let bytesDouble = Double(bytes)

        if bytesDouble >= gb {
            return String(format: "%.2f GB", bytesDouble / gb)
        } else if bytesDouble >= mb {
            return String(format: "%.2f MB", bytesDouble / mb)
        } else if bytesDouble >= kb {
            return String(format: "%.2f KB", bytesDouble / kb)
        } else {
            return "\(bytes) B"
        }
    }

    @objc private func udiskAccessSwitchChanged(_ sender: UISwitch) {
        // TODO: Handle USB disk access switch state change
        let isEnabled = sender.isOn

        deviceAgent.setUDiskMode(onOff: isEnabled)

        showToastWithMessage(NSLocalizedString("device.status.udisk_access_changed", comment: "").replacingOccurrences(of: "{status}", with: isEnabled ? NSLocalizedString("device.status.enabled", comment: "") : NSLocalizedString("device.status.disabled", comment: "")))
    }

    // New: Associate user popup
    private func showAssociateUserDialog() {
        let alert = UIAlertController(title: NSLocalizedString("device.dialog.associate_user.title", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = NSLocalizedString("device.dialog.associate_user.placeholder", comment: "")
            textField.text = "plaud_sdk_ios"
        }

        let associateAction = UIAlertAction(title: NSLocalizedString("device.dialog.associate_user.associate", comment: ""), style: .default) { [weak alert, weak self] _ in
            let userId = alert?.textFields?.first?.text ?? ""

            PlaudFileUploader.shared.bindDevice(ownerId: userId, sn: self?.device.serialNumber ?? "") { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(str):
                        self?.showToastWithMessage(NSLocalizedString("device.dialog.associate_user.associate_success", comment: ""))
                    case let .failure(error):
                        self?.showToastWithMessage(NSLocalizedString("device.dialog.associate_user.associate_fail", comment: "") + " " + ((error as? NSError)?.userInfo.description ?? ""))
                    }
                }
            }
        }

        let dissociateAction = UIAlertAction(title: NSLocalizedString("device.dialog.associate_user.dissociate", comment: ""), style: .destructive) { [weak alert, weak self] _ in
            let userId = alert?.textFields?.first?.text ?? ""

            PlaudFileUploader.shared.unbindDevice(ownerId: userId, sn: self?.device.serialNumber ?? "") { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.showToastWithMessage(NSLocalizedString("device.dialog.associate_user.dissociate_success", comment: ""))
                    case let .failure(error):
                        self?.showToastWithMessage(NSLocalizedString("device.dialog.associate_user.dissociate_fail", comment: "") + " " + ((error as? NSError)?.userInfo.description ?? ""))
                    }
                }
            }
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel)
        alert.addAction(associateAction)
        alert.addAction(dissociateAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

// MARK: - InfoItemView

class InfoItemView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

extension DeviceInfoViewController: PlaudDeviceAgentProtocol {
    func bleMicGain(_: Int) {}

    func bleDepair(_ status: Int) {
        // Parameter status: 0 success; 1 working; 2 upgrading
        if status == 0 {
            showToastWithMessage(NSLocalizedString("device.status.unbind_success", comment: ""))
        }

        if status == 2 {
            showToastWithMessage(NSLocalizedString("device.error.unbind_failed_working", comment: ""))
        }

        if status == 2 {
            showToastWithMessage(NSLocalizedString("device.error.unbind_failed_upgrading", comment: ""))
        }
    }

    func bleDownloadFileStop() {}

    func bleDownloadFile(sessionId: Int, outputPath: String, status: Int, progress: Int, tips: String) {
        debugPrint("DeviceInfoViewController - bleDownloadFile sessionId=\(sessionId) outputPath=\(outputPath) status=\(status) progress=\(progress) tips=\(tips)")

        if progress == 100 {
            downloadedFiles["\(sessionId)"] = outputPath
        }

        // Update progress bar
        DispatchQueue.main.async { [weak self] in
            self?.progressAlert?.updateProgress(Float(progress) / 100.0, text: tips)
            if progress == 100 {
                self?.progressAlert?.setCancelButtonTitle(NSLocalizedString("device.action.view", comment: ""))
                self?.progressAlert?.onCancel = { [weak self] in
                    let filePath = "\(outputPath).mp3"
                    if FileManager.default.fileExists(atPath: filePath) {
                        let vc = PlaudAudioPlayerViewController(filePath: filePath)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        self?.showToastWithMessage(NSLocalizedString("device.error.audio_file_not_found", comment: ""))
                    }
                }
            }
        }
    }

    func bleSyncFileHead(sessionId: Int, status: Int) {
        debugPrint("DeviceInfoViewController - bleSyncFileHead  sessionId=\(sessionId) status=\(status)")
    }

    func bleSyncFileTail(sessionId: Int, crc: Int) {
        debugPrint("DeviceInfoViewController - bleSyncFileTail: sessionId=\(sessionId), crc=\(crc)")

        downlodingFileInfo = nil

        // Get documents directory path
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileName = "\(sessionId).dat"

        // Use BleFileManager to save data
        PLBleFileManager.shared.closeFile(filePath: documentsPath, fileName: fileName)
    }

    private func getCurrentFileSize(sessionId: Int) -> Int {
        if let downlodingFileInfo = downlodingFileInfo {
            return downlodingFileInfo.size
        }

        for file in recordList {
            if file.sessionId == sessionId {
                downlodingFileInfo = file
                return file.size
            }
        }

        return -1
    }

    func bleData(sessionId: Int, start: Int, data: Data) {
        debugPrint("DeviceInfoViewController - bleData: sessionId=\(sessionId), start=\(start), dataSize=\(data.count)")

        if let downloading = downlodingFileInfo {
            // Update progress bar
            let size = getCurrentFileSize(sessionId: sessionId)
            let ratio = Float(start + data.count) * 100.0 / Float(size)
            DispatchQueue.main.async { [weak self] in
                var tip = NSLocalizedString("device.status.downloading", comment: "")
                if Int(ratio) == 100 {
                    tip = NSLocalizedString("device.status.download_complete", comment: "")
                }
                self?.progressAlert?.updateProgress(ratio / 100.0, text: tip)
                self?.updatePopBtnClk(progress: Int(ratio))
            }
        }

        // Get documents directory path
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileName = "\(sessionId).dat"

        // Use BleFileManager to save data
        PLBleFileManager.shared.saveBleFile(
            filePath: documentsPath,
            fileName: fileName,
            start: start,
            data: data
        )
    }

    func updatePopBtnClk(progress: Int) {
        if progress == 100 {
            progressAlert?.setCancelButtonTitle(NSLocalizedString("device.action.transcode", comment: ""))
            progressAlert?.onCancel = { [weak self] in
            }
        }
    }

    func blePcmData(sessionId: Int, millsec: Int, pcmData: Data, isMusic: Bool) {
        debugPrint("DeviceInfoViewController - blePcmData: sessionId=\(sessionId), millsec=\(millsec), dataSize=\(pcmData.count), isMusic=\(isMusic)")
    }

    func bleDecodeFail(start: Int) {
        debugPrint("DeviceInfoViewController - bleDecodeFail: start=\(start)")
    }

    func bleSyncFileStop() {
        downlodingFileInfo = nil
        debugPrint("DeviceInfoViewController - bleSyncFileStop")
    }

    func bleRecordStop(sessionId: Int, reason: Int, fileExist: Bool, fileSize: Int) {
        debugPrint("DeviceInfoViewController - bleRecordStop: sessionId=\(sessionId), reason=\(reason), fileExist=\(fileExist), fileSize=\(fileSize)")
        ///      1.MMI_REC_STOP_FROM_DEV    /// Device-side stop recording
        ///      2.MMI_REC_STOP_FROM_APP    /// App-side stop recording
        ///      3.MMI_REC_STOP_BY_SPLIT        /// Auto-time slice stop recording
        ///      4.MMI_REC_STOP_BY_SWITCH   ///  Switch toggle stop recording
        let reasonStr = NSLocalizedString("device.status.record_stop_reason.\(reason)", comment: "")
        showToastWithMessage(NSLocalizedString("device.status.record_stopped", comment: "").replacingOccurrences(of: "{reason}", with: reasonStr))
    }

    func bleRecordPause(sessionId: Int, reason: Int, fileExist: Bool, fileSize: Int) {
        debugPrint("DeviceInfoViewController - bleRecordPause: sessionId=\(sessionId), reason=\(reason), fileExist=\(fileExist), fileSize=\(fileSize)")
        showToastWithMessage(NSLocalizedString("device.status.record_paused", comment: ""))
    }

    func bleRecordResume(sessionId: Int, start: Int, status: Int, scene: Int, startTime: Int) {
        debugPrint("DeviceInfoViewController - bleRecordResume: sessionId=\(sessionId), start=\(start), status=\(status), scene=\(scene), startTime=\(startTime)")
        showToastWithMessage(NSLocalizedString("device.status.record_resumed", comment: ""))
    }

    func bleStopRecord(status: Int) {
        debugPrint("DeviceInfoViewController - bleStopRecord: status=\(status)")
    }

    func blePenState(state: Int, privacy: Int, keyState: Int, uDisk: Int, findMyToken: Int, hasSndpKey: Int, deviceAccessToken: Int) {
        debugPrint("DeviceInfoViewController - blePenState: state=\(state), privacy=\(privacy), keyState=\(keyState), uDisk=\(uDisk), findMyToken=\(findMyToken), hasSndpKey=\(hasSndpKey), deviceAccessToken=\(deviceAccessToken)")

        // Update switch state
        udiskAccessSwitch.isOn = privacy == 0

        // Control USB disk mode warning display
        udiskModeWarningLabel.isHidden = uDisk != 1
    }

    func bleRecordStart(sessionId: Int, start: Int, status: Int, scene: Int, startTime: Int) {
        debugPrint("DeviceInfoViewController - bleRecordStart: sessionId=\(sessionId), start=\(start), status=\(status), scene=\(scene), startTime=\(startTime)")
        showToastWithMessage(NSLocalizedString("device.status.record_started", comment: "").replacingOccurrences(of: "{id}", with: "\(sessionId)"))
    }

    func onCommonMsgChannel(type _: Int, value _: Int, tips: String) {
        showToastWithMessage(tips)
    }

    func bleAppKeyState(result: Int) {
        debugPrint("DeviceInfoViewController - bleAppKeyState: result=\(result)")
    }

    func bleScanResult(bleDevices: [PenBleSDK.BleDevice]) {
        debugPrint("DeviceInfoViewController - bleScanResult: devices=\(bleDevices)")
    }

    func bleScanOverTime() {
        debugPrint("DeviceInfoViewController - bleScanOverTime")
    }

    func bleConnectState(state: Int) {
        debugPrint("DeviceInfoViewController - bleConnectState: state=\(state)")

        // For unbound devices, bleConnectState returns 1 first, then 0, popup first
        if state == 0 {
            if let topViewController = navigationController?.topViewController, topViewController is DeviceInfoViewController {
                showToastWithMessage(NSLocalizedString("device.error.connection_failed", comment: ""))
                navigationController?.popViewController(animated: true)
            }
        }
    }

    func bleBind(sn: String?, status: Int, protVersion: Int, timezone: Int) {
        debugPrint("DeviceInfoViewController - bleBind: sn=\(sn ?? "nil"), status=\(status), protVersion=\(protVersion), timezone=\(timezone)")

        if status == 0 {
            showToastWithMessage(NSLocalizedString("device.status.connection_success", comment: ""))
        } else {
            showToastWithMessage(NSLocalizedString("device.error.connection_failed", comment: ""))
        }
    }

    func bleStorage(total: Int, free: Int, duration: Int) {
        debugPrint("DeviceInfoViewController - bleStorage: total=\(total), free=\(free), duration=\(duration)")

        //        let totalMB = Double(total) / (1024 * 1024 * 1024)
        //        let freeMB = Double(free) /  (1024 * 1024 * 1024)
        let totalMB = Double(total) / (1000 * 1000 * 1000)
        let freeMB = Double(free) / (1000 * 1000 * 1000)
        storageLabel.setValue(String(format: "%.2f GB / %.2f GB", freeMB, totalMB))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.deviceAgent.getFileList(startSessionId: 0)
        }
    }

    func blePowerChange(power: Int, oldPower: Int) {
        debugPrint("DeviceInfoViewController - blePowerChange: power=\(power), oldPower=\(oldPower)")
        // showToastWithMessage("blePowerChange")
    }

    func bleChargingState(isCharging: Bool, level: Int) {
        debugPrint("DeviceInfoViewController - bleChargingState: isCharging=\(isCharging), level=\(level)")

        let charging = isCharging ?
            NSLocalizedString("device.status.charging", comment: "") :
            NSLocalizedString("device.status.not_charging", comment: "")

        batteryLabel.setValue("\(level)% - \(charging)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.deviceAgent.getStorage()
        }
    }

    func bleFileList(bleFiles: [BleFile]) {
        debugPrint("DeviceInfoViewController - bleFileList: count=\(bleFiles.count)")
        recordList.removeAll()
        recordList.append(contentsOf: bleFiles)

        if manualGet {
            showToastWithMessage(NSLocalizedString("device.status.file_list_success", comment: "").replacingOccurrences(of: "{count}", with: "\(bleFiles.count)"))
            manualGet = false
        }
    }

    func bleDataComplete() {
        debugPrint("DeviceInfoViewController - bleDataComplete")
        downlodingFileInfo = nil

        PLBleFileManager.shared.closeAllFiles()
        PLBleFileManager.shared.convertAllFilesToPcm()

        //        // Get documents directory path
        //        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        //        let fileName = "\(sessionId).dat"
        //
        //        // Use BleFileManager to save data
        //        BleFileManager.shared.saveBleFile(
        //            filePath: documentsPath,
        //            fileName: fileName,
        //            start: start,
        //            data: data
        //        )
    }

    func bleSyncFileHead(sessionId: Int, size: Int, start: Int, end: Int) {
        debugPrint("DeviceInfoViewController - bleSyncFileHead: sessionId=\(sessionId), size=\(size), start=\(start), end=\(end)")
    }

    func bleSyncFileData(sessionId: Int, data: Data, offset: Int) {
        debugPrint("DeviceInfoViewController - bleSyncFileData: sessionId=\(sessionId), dataSize=\(data.count), offset=\(offset)")
    }

    //    func bleSyncFileComplete(sessionId: Int, status: Int) {
    //        debugPrint("DeviceInfoViewController - bleSyncFileComplete: sessionId=\(sessionId), status=\(status)")
    //    }
    //
    //    func bleSyncFileError(sessionId: Int, error: Int) {
    //        debugPrint("DeviceInfoViewController - bleSyncFileError: sessionId=\(sessionId), error=\(error)")
    //    }

    func bleDeleteFile(sessionId: Int, status: Int) {
        debugPrint("DeviceInfoViewController - bleDeleteFile: sessionId=\(sessionId), status=\(status)")

        ///   - sessionId: Protocol version 7 support
        ///   - status: Status, 0: Delete success; 1: Recording in progress, deletion not allowed; 2: Favorited, deletion not allowed; 3: Playing, deletion not allowed
        ///
        ///
        var reasonStr = ""
        if status == 0 {
            reasonStr = NSLocalizedString("device.delete.success", comment: "")
        } else if status == 1 {
            reasonStr = NSLocalizedString("device.delete.error.recording", comment: "")
        } else if status == 2 {
            reasonStr = NSLocalizedString("device.delete.error.favorite", comment: "")
        } else if status == 3 {
            reasonStr = NSLocalizedString("device.delete.error.playing", comment: "")
        }
        showToastWithMessage(reasonStr)
    }

    func bleClearAllFiles(status: Int) {
        debugPrint("DeviceInfoViewController - bleClearAllFiles: status=\(status)")
    }

    func bleStartRecord(status: Int) {
        debugPrint("DeviceInfoViewController - bleStartRecord: status=\(status)")
    }

    func blePauseRecord(status: Int) {
        debugPrint("DeviceInfoViewController - blePauseRecord: status=\(status)")
    }

    func bleResumeRecord(status: Int) {
        debugPrint("DeviceInfoViewController - bleResumeRecord: status=\(status)")
    }
}
