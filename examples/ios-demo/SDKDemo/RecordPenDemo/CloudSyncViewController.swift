import PlaudDeviceBasicSDK
import UIKit

private let transcriptType = "linkedcare_aesthetics" // Linkedcare aesthetics
private let etlType = "linkedcare_aesthetics" // Linkedcare aesthetics

class CloudSyncViewController: UIViewController {
    private let tableView = UITableView()
    private var files: [URL] = []
    private let fileManager = FileManager.default
    private let device: BleDevice
    private var refreshControl: UIRefreshControl?
    private var uploadedFiles: Set<String> = []
    private var fileIDMapping: [String: String] = [:] // Store filename to file_id mapping

    init(device: BleDevice) {
        self.device = device
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFiles()
    }

    private func setupUI() {
        // Set background color
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)

        // Set custom back button (with icon)
        let backImage: UIImage?
        if #available(iOS 13.0, *) {
            backImage = UIImage(systemName: "chevron.backward")
        } else {
            backImage = UIImage(named: "back") // Lower versions can provide their own back.png
        }
        let backButton = UIButton(type: .system)
        backButton.setImage(backImage, for: .normal)
        backButton.setTitle(NSLocalizedString("common.back", comment: ""), for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        backButton.tintColor = .systemBlue
        backButton.sizeToFit()
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        backButton.contentHorizontalAlignment = .left
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        backButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -8)
        let barButton = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = barButton

        // Set navigation bar title style
        let titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("device.action.sync_file", comment: "")
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: titleContainer.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: titleContainer.trailingAnchor),
            titleContainer.widthAnchor.constraint(equalToConstant: 200),
            titleContainer.heightAnchor.constraint(equalToConstant: 44),
        ])

        navigationItem.titleView = titleContainer

        // Add refresh button
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshButtonTapped)
        )
        navigationItem.rightBarButtonItem = refreshButton

        // Setup TableView
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FileCell.self, forCellReuseIdentifier: "FileCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Add pull-to-refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        tableView.refreshControl = refreshControl
        self.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func refreshButtonTapped() {
        // Show refresh animation
        refreshControl?.beginRefreshing()
        // Scroll to top to show refresh control
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top - (refreshControl?.frame.height ?? 0)), animated: true)
        loadFiles()
        // End refresh animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl?.endRefreshing()
        }
    }

    @objc private func refreshAction() {
        loadFiles()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl?.endRefreshing()
        }
    }

    @objc private func handleBackButton() {
        if !uploadedFiles.isEmpty {
            let alert = UIAlertController(
                title: NSLocalizedString("cloudsync.delete_synced.title", comment: ""),
                message: NSLocalizedString("cloudsync.delete_synced.message", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("common.confirm", comment: ""), style: .destructive, handler: { [weak self] _ in
                self?.deleteUploadedFiles()
                self?.navigationController?.popViewController(animated: true)
            }))
            present(alert, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func getCurrentLanguage() -> String {
        let currentLanguage = Locale.current.languageCode ?? "en"
        return currentLanguage.hasPrefix("zh") ? "zh" : "en"
    }

    private func loadFiles() {
        // Get documents directory
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURLs = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
            files = fileURLs.filter { $0.pathExtension == "dat" }
            tableView.reloadData()
        } catch {
            print("Error loading files: \(error)")
        }
    }

    private func uploadFile(at url: URL) {
        // Show upload progress alert
        let uploadProgressAlert = UploadProgressAlertController(title: NSLocalizedString("upload.progress.title", comment: ""))
        uploadProgressAlert.onCancel = {
            // TODO: Cancel upload
            uploadProgressAlert.dismiss(animated: true)
        }
        present(uploadProgressAlert, animated: true)

        // Get file name without extension
        let fileName = url.deletingPathExtension().lastPathComponent

        // Upload file using PlaudFileUploader
        PlaudFileUploader.shared.device = device
        PlaudFileUploader.shared.uploadRecording(
            sn: device.serialNumber,
            sessionId: Int(fileName) ?? 0,
            onProgress: { progress in
                DispatchQueue.main.async {
                    uploadProgressAlert.updateProgress(Float(progress))
                }
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(response):
                        self?.uploadedFiles.insert(fileName)
                        uploadProgressAlert.updateProgress(1.0, text: NSLocalizedString("upload.progress.success", comment: ""))
                        uploadProgressAlert.setActionButtonAsConfirm()
                        uploadProgressAlert.onConfirm = {
                            uploadProgressAlert.dismiss(animated: true)
                        }
                        self?.tableView.reloadData()
                        self?.processUpdateSuccessResult(response: result, fileName: fileName)
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

    private func processUpdateSuccessResult(response: Result<[String: Any], Error>, fileName: String) {
        switch response {
        case let .success(jsonDic):
            if let owner_id = jsonDic["owner_id"] as? String {
                print("owner_id: \(owner_id)")
            }

            if let device_id = jsonDic["device_id"] as? String {
                print("device_id: \(device_id)")
            }

            if let file_id = jsonDic["id"] as? String {
                print("file_id: \(file_id)")
                fileIDMapping[fileName] = file_id
            }
        case let .failure(error):
                            print("Failed to process upload result: \(error.localizedDescription)")
        }
    }

    private func deleteUploadedFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        for fileName in uploadedFiles {
            let fileURL = tempDir.appendingPathComponent(fileName + ".dat")
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
        loadFiles()
    }

    private func showAIProcessingOptions(for fileURL: URL) {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileID = fileIDMapping[fileName]

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let transcribeAction = UIAlertAction(title: NSLocalizedString("menu.option.transcribe", comment: ""), style: .default) { _ in
            if let fileID = fileID {
                self.triggleAudioTranscribeWorkflow(fileId: fileID)
            } else {
                self.showToast(message: NSLocalizedString("ai.toast.transcribe_wip", comment: ""))
            }
        }
        let etlAction = UIAlertAction(title: NSLocalizedString("menu.option.ai_etl", comment: ""), style: .default) { _ in
            if let fileID = fileID {
                self.doAIETLWorkflow(fileId: fileID)
            } else {
                self.showToast(message: NSLocalizedString("ai.toast.ai_etl_wip", comment: ""))
            }
        }
        let summaryAction = UIAlertAction(title: NSLocalizedString("menu.option.transcribe_summary", comment: "Transcribe Summary option"), style: .default) { _ in
            if let fileID = fileID {
                self.doAISummaryWorkflow(fileId: fileID)
            } else {
                self.showToast(message: NSLocalizedString("ai.toast.transcribe_summary_wip", comment: "Transcribe summary WIP"))
            }
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel)

        alert.addAction(transcribeAction)
        alert.addAction(etlAction)
        alert.addAction(summaryAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    func triggleAudioTranscribeWorkflow(fileId: String) {
                    print("\n=== Test Audio Transcription Workflow ===")
            print("File ID: \(fileId)")

        let resultVC = WorkflowResultViewController()
        let navController = UINavigationController(rootViewController: resultVC)
        navController.modalPresentationStyle = .overFullScreen // Full screen popup, remove top gray area
        present(navController, animated: true, completion: nil)

        PlaudWorkflowManager.shared.doAudioTranscribeWorkflow(
            fileId: fileId,
            language: getCurrentLanguage(),
            diarization: true,
            transcriptType: transcriptType,
            timeout: 3600.0,
            progressHandler: { [weak resultVC] statusResponse in
                DispatchQueue.main.async {
                    let completed = statusResponse.completedTasks ?? 0
                    let total = statusResponse.totalTasks ?? 0
                    let progressText = NSLocalizedString("workflow.progress.progress", comment: "Progress")
                    let progressMessage = "\(progressText): \(completed)/\(total)"
                    let status = NSLocalizedString("workflow.progress.transcribing", comment: "Transcribing status")

                    resultVC?.updateProgress(status: status, message: progressMessage)
                }
            }
        ) { [weak self, weak resultVC] result in
            switch result {
            case let .success(response):
                print("✅ Audio transcription workflow completed")
                print("Final status: \(response.status)")

                // Print transcription results
                print("Transcription status: \(response.status)")
                print("Number of transcription tasks: \(response.tasks.count)")
                print("Task types: \(response.taskTypes)")

                if let transcriptTask = response.transcriptTask {
                    print("Transcription task ID: \(transcriptTask.taskId)")
                    print("Transcription task type: \(transcriptTask.taskType)")
                    print("Transcription task status: \(transcriptTask.status)")
                    print("Transcription task processing time: \(response.transcriptDurationSeconds ?? 0) seconds")
                }

                // Print transcription content
                if let transcriptResult = response.firstTranscriptResult {
                    print("Number of transcription segments: \(transcriptResult.segments.count)")
                    print("Speaker list: \(response.speakers)")

                    print("Complete transcription text:")
                    print(response.allTranscriptText)

                    print("Transcription grouped by speaker:")
                    for (speaker, text) in response.transcriptBySpeaker {
                        print("[\(speaker)]: \(text)")
                    }
                }

                DispatchQueue.main.async {
                    resultVC?.displayResults(response: response)
                }

            case let .failure(error):
                print("❌ Audio transcription workflow failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    resultVC?.displayResults(response: nil)
                }
            }
        }
    }

    private func showMenuOptions(for fileURL: URL) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let renameAction = UIAlertAction(title: NSLocalizedString("menu.option.rename", comment: ""), style: .default) { _ in
            self.renameFile(fileURL)
        }

        let deleteAction = UIAlertAction(title: NSLocalizedString("menu.option.delete", comment: ""), style: .destructive) { _ in
            self.deleteFile(fileURL)
        }

        let shareAction = UIAlertAction(title: NSLocalizedString("menu.option.share", comment: ""), style: .default) { _ in
            self.shareFile(fileURL)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel)

        alert.addAction(renameAction)
        alert.addAction(deleteAction)
        alert.addAction(shareAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    private func startAIProcess(type _: String, for _: URL) {
        // Show AI processing progress
        let progressAlert = UploadProgressAlertController(title: "AI Processing...")
        progressAlert.onCancel = {
            // TODO: Cancel AI processing
            progressAlert.dismiss(animated: true)
        }
        present(progressAlert, animated: true)

        // Simulate AI processing progress
        var progress: Float = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.01
            DispatchQueue.main.async {
                progressAlert.updateProgress(progress)
                if progress >= 1.0 {
                    timer.invalidate()
                    progressAlert.updateProgress(1.0, text: "AI Processing Complete")
                    progressAlert.setActionButtonAsConfirm()
                    progressAlert.onConfirm = {
                        progressAlert.dismiss(animated: true)
                    }
                }
            }
        }

        // Should call actual AI processing API here
        // TODO: Implement actual AI processing logic
    }

    private func renameFile(_ fileURL: URL) {
        let alert = UIAlertController(title: "Rename File", message: "Please enter the new file name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = fileURL.deletingPathExtension().lastPathComponent
        }

        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                let newURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension("dat")
                do {
                    try self.fileManager.moveItem(at: fileURL, to: newURL)
                    self.loadFiles()
                } catch {
                    print("Error renaming file: \(error)")
                }
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func deleteFile(_ fileURL: URL) {
        let alert = UIAlertController(title: "Delete File", message: "Are you sure you want to delete this file?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            do {
                try self.fileManager.removeItem(at: fileURL)
                self.loadFiles()
            } catch {
                print("Error deleting file: \(error)")
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func shareFile(_ fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        // Need to set popoverPresentationController on iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(activityViewController, animated: true)
    }

    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        present(alert, animated: true)
    }

    // MARK: - Other Workflow Example Methods

    private func doAIETLWorkflow(fileId: String) {
        print("\n=== Test AI ETL Workflow ===")
        print("File ID: \(fileId)")

        let resultVC = WorkflowResultViewController()
        let navController = UINavigationController(rootViewController: resultVC)
        navController.modalPresentationStyle = .overFullScreen // Full screen popup, remove top gray area
        present(navController, animated: true, completion: nil)

        PlaudWorkflowManager.shared.doTranscribeAndAnalysisWorkflow(
            fileId: fileId,
            language: getCurrentLanguage(),
            etlType: etlType,
            timeout: 3600.0,
            progressHandler: { [weak resultVC] statusResponse in
                DispatchQueue.main.async {
                    let completed = statusResponse.completedTasks ?? 0
                    let total = statusResponse.totalTasks ?? 0
                    let progressText = NSLocalizedString("workflow.progress.progress", comment: "Progress")
                    let progressMessage = "\(progressText): \(completed)/\(total)"
                    let status = NSLocalizedString("workflow.progress.processing_ai", comment: "AI processing status")

                    resultVC?.updateProgress(status: status, message: progressMessage)
                }
            }
        ) { [weak self, weak resultVC] result in
            switch result {
            case let .success(response):
                print("✅ AI ETL workflow completed")
                print("Final status: \(response.status)")

                // AI ETL workflow specific processing logic
                print("=== AI ETL workflow detailed result processing ===")

                if let structuredData = response.legacyResults?["structured_data"] {
                    print("Structured data: \(structuredData)")
                }

                if let entities = response.legacyResults?["entities"] {
                    print("Entity recognition results: \(entities)")
                }

                if let classifications = response.legacyResults?["classifications"] {
                    print("Classification results: \(classifications)")
                }

                // Print AI ETL results
                if response.hasAIEtlTask {
                    print("\n=== AI ETL Results ===")
                    if let aiEtlTask = response.aiEtlTask {
                        print("AI ETL task ID: \(aiEtlTask.taskId)")
                        print("AI ETL task status: \(aiEtlTask.status)")
                        print("AI ETL task processing time: \(response.aiEtlDurationSeconds ?? 0) seconds")
                    }

                    if let aiEtlResult = response.firstAIEtlResult {
                        print("Customer appellation: \(aiEtlResult.appellation ?? "Unknown")")
                        print("AI ETL summary: \(aiEtlResult.summary ?? "None")")

                        if let dealAnalysis = aiEtlResult.dealAnalysis {
                            print("Deal status: \(dealAnalysis.status ?? "Unknown")")
                            print("Deal intention rating: \(dealAnalysis.intention?.rating ?? "Unknown")")
                            print("Deal intention description: \(dealAnalysis.intention?.description ?? "None")")

                            if let noDealReason = dealAnalysis.noDealReason {
                                print("No deal reason: \(noDealReason.description ?? "None")")
                                print("No deal suggestion: \(noDealReason.suggestion ?? "None")")
                                if let reasons = noDealReason.reason {
                                    print("No deal reason list: \(reasons)")
                                }
                            }
                        }

                        if let communicationFeedback = aiEtlResult.communicationFeedback {
                            print("Communication highlights: \(communicationFeedback.highlight ?? "None")")
                            print("Communication suggestions: \(communicationFeedback.suggestion ?? "None")")
                        }

                        print("Clinical report:")
                        print(aiEtlResult.clinicalReport ?? "None")
                    }
                }

                DispatchQueue.main.async {
                    resultVC?.displayResults(response: response)
                }

            case let .failure(error):
                print("❌ AI ETL workflow failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    resultVC?.displayResults(response: nil)
                }
            }
        }
    }

    private func doAISummaryWorkflow(fileId: String) {
        print("\n=== Test Transcription + AI Summary Workflow ===")
        print("File ID: \(fileId)")

        let resultVC = WorkflowResultViewController()
        let navController = UINavigationController(rootViewController: resultVC)
        navController.modalPresentationStyle = .overFullScreen // Full screen popup, remove top gray area
        present(navController, animated: true, completion: nil)

        PlaudWorkflowManager.shared.doTranscribeAndAISummaryWorkflow(
            fileId: fileId,
            language: getCurrentLanguage(),
            diarization: true,
            templateId: "MEETING",
            model: "openai",
            startTime: 0,
            timeout: 3600.0,
            progressHandler: { [weak resultVC] statusResponse in
                DispatchQueue.main.async {
                    let completed = statusResponse.completedTasks ?? 0
                    let total = statusResponse.totalTasks ?? 0
                    let progressText = NSLocalizedString("workflow.progress.progress", comment: "Progress")
                    let progressMessage = "\(progressText): \(completed)/\(total)"
                    let status = NSLocalizedString("workflow.progress.processing_summary", comment: "AI Summary processing status")

                    resultVC?.updateProgress(status: status, message: progressMessage)
                }
            }
        ) { [weak self, weak resultVC] result in
            switch result {
            case let .success(response):
                print("✅ Transcription + AI Summary workflow completed")
                print("Final status: \(response.status)")

                // Transcription + AI Summary workflow specific processing logic
                print("=== Transcription + AI Summary workflow detailed result processing ===")

                // Process transcription results
                //                if let transcriptText = response.allTranscriptText {
                //                    print("Transcription text: \(transcriptText)")
                //                }

                // Process AI summary results
                if let summaryText = response.aiSummaryText {
                    print("AI Summary: \(summaryText)")
                }

                if let keyPoints = response.aiSummaryKeyPoints {
                    print("Key points: \(keyPoints)")
                }

                if let actionItems = response.aiSummaryActionItems {
                    print("Action items: \(actionItems)")
                }

                if let participants = response.aiSummaryParticipants {
                    print("Participants: \(participants)")
                }

                // Print AI summary results
                if response.hasAISummaryTask {
                    print("\n=== AI Summary Results ===")
                    if let aiSummaryTask = response.aiSummaryTask {
                        print("AI Summary task ID: \(aiSummaryTask.taskId)")
                        print("AI Summary task status: \(aiSummaryTask.status)")
                        print("AI Summary task processing time: \(response.aiSummaryDurationSeconds ?? 0) seconds")
                    }

                    if let aiSummaryResult = response.firstAISummaryResult {
                        print("AI Summary template: \(aiSummaryResult.template ?? "Unknown")")
                        print("AI Summary model: \(aiSummaryResult.model ?? "Unknown")")
                        print("AI Summary duration: \(aiSummaryResult.duration ?? "Unknown")")

                        print("AI Summary:")
                        print(aiSummaryResult.summary ?? "None")

                        if let keyPoints = aiSummaryResult.keyPoints {
                            print("Key points:")
                            for (index, point) in keyPoints.enumerated() {
                                print("  \(index + 1). \(point)")
                            }
                        }

                        if let actionItems = aiSummaryResult.actionItems {
                            print("Action items:")
                            for (index, item) in actionItems.enumerated() {
                                print("  \(index + 1). \(item)")
                            }
                        }

                        if let participants = aiSummaryResult.participants {
                            print("Participants: \(participants.joined(separator: ", "))")
                        }
                    }
                }

                DispatchQueue.main.async {
                    resultVC?.displayResults(response: response)
                }

            case let .failure(error):
                print("❌ Transcription + AI Summary workflow failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    resultVC?.displayResults(response: nil)
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension CloudSyncViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return files.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FileCell
        let fileURL = files[indexPath.row]

        // Get file attributes
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int ?? 0
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            let fileName = fileURL.deletingPathExtension().lastPathComponent

            cell.configure(
                fileName: fileURL.lastPathComponent,
                fileSize: fileSize,
                creationDate: creationDate,
                uploaded: uploadedFiles.contains(fileName),
                cloudFileID: fileIDMapping[fileName]
            )
        } catch {
            print("Error getting file attributes: \(error)")
        }

        cell.onUploadTapped = { [weak self] in
            self?.uploadFile(at: fileURL)
        }

        cell.onAIProcessTapped = { [weak self] in
            self?.showAIProcessingOptions(for: fileURL)
        }

        cell.onMenuTapped = { [weak self] in
            self?.showMenuOptions(for: fileURL)
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 100
    }

            // Custom section header
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white

        let label = UILabel()
        label.text = NSLocalizedString("cloudsync.section.downloaded_recordings", comment: "")
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(red: 0.53, green: 0.53, blue: 0.53, alpha: 1.0) // #888888
        label.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -2),
        ])
        return headerView
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 28
    }
}

// MARK: - FileCell

class FileCell: UITableViewCell {
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

    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private let uploadStatusIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private let uploadStatusLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("file.cell.uploaded", comment: "")
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("progress.alert.upload", comment: ""), for: .normal)
        button.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let aiProcessButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("file.cell.ai_process", comment: ""), for: .normal)
        button.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0).cgColor
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.isHidden = true
        return button
    }()

    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    var cloudFileID: String?
    var onUploadTapped: (() -> Void)?
    var onAIProcessTapped: (() -> Void)?
    var onMenuTapped: (() -> Void)?

    private var isUploaded: Bool = false {
        didSet {
            if isUploaded {
                uploadStatusIcon.image = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0), renderingMode: .alwaysOriginal)
                uploadStatusIcon.isHidden = false
                uploadStatusLabel.isHidden = false
                uploadButton.isHidden = true
                aiProcessButton.isHidden = false
                aiProcessButton.isEnabled = true
                aiProcessButton.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
                aiProcessButton.layer.borderColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor
            } else {
                uploadStatusIcon.isHidden = true
                uploadStatusLabel.isHidden = true
                uploadButton.isHidden = false
                aiProcessButton.isHidden = true
                aiProcessButton.isEnabled = false
                aiProcessButton.setTitleColor(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), for: .normal)
                aiProcessButton.layer.borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0).cgColor
            }
        }
    }

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
        containerView.addSubview(fileNameLabel)
        containerView.addSubview(uploadStatusIcon)
        containerView.addSubview(uploadStatusLabel)
        containerView.addSubview(fileSizeLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(uploadButton)
        containerView.addSubview(aiProcessButton)
        containerView.addSubview(menuButton)

        uploadButton.addTarget(self, action: #selector(handleUploadButtonTap), for: .touchUpInside)
        aiProcessButton.addTarget(self, action: #selector(handleAIProcessButtonTap), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(handleMenuButtonTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            menuButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            menuButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            menuButton.widthAnchor.constraint(equalToConstant: 24),
            menuButton.heightAnchor.constraint(equalToConstant: 24),

            aiProcessButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            aiProcessButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            aiProcessButton.widthAnchor.constraint(equalToConstant: 80),
            aiProcessButton.heightAnchor.constraint(equalToConstant: 36),

            uploadButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            uploadButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            uploadButton.widthAnchor.constraint(equalToConstant: 80),
            uploadButton.heightAnchor.constraint(equalToConstant: 36),

            uploadStatusIcon.centerYAnchor.constraint(equalTo: fileNameLabel.centerYAnchor),
            uploadStatusIcon.leadingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor, constant: 8),
            uploadStatusIcon.widthAnchor.constraint(equalToConstant: 16),
            uploadStatusIcon.heightAnchor.constraint(equalToConstant: 16),

            uploadStatusLabel.centerYAnchor.constraint(equalTo: fileNameLabel.centerYAnchor),
            uploadStatusLabel.leadingAnchor.constraint(equalTo: uploadStatusIcon.trailingAnchor, constant: 4),
            uploadStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: uploadButton.leadingAnchor, constant: -8),

            fileNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            fileNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            fileNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: uploadStatusIcon.leadingAnchor, constant: -8),

            fileSizeLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 8),
            fileSizeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),

            dateLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: fileSizeLabel.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: uploadStatusLabel.leadingAnchor, constant: -8),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),
        ])
    }

    func configure(fileName: String, fileSize: Int, creationDate: Date, uploaded: Bool = false, cloudFileID: String?) {
        fileNameLabel.text = fileName

        // Format file size
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        fileSizeLabel.text = formatter.string(fromByteCount: Int64(fileSize))

        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateLabel.text = dateFormatter.string(from: creationDate)

        isUploaded = uploaded
        self.cloudFileID = cloudFileID
    }

    @objc private func handleUploadButtonTap() {
        onUploadTapped?()
    }

    @objc private func handleAIProcessButtonTap() {
        onAIProcessTapped?()
    }

    @objc private func handleMenuButtonTap() {
        onMenuTapped?()
    }
}
