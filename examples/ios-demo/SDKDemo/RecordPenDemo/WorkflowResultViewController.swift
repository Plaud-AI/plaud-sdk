import UIKit

// A struct to represent a transcript segment for easier handling.
// This should be adapted if the actual model from the SDK is different.
struct TranscriptSegment {
    let speaker: String
    let startTime: TimeInterval
    let text: String

    // A helper to format the timestamp
    var formattedTimestamp: String {
        let hours = Int(startTime) / 3600
        let minutes = (Int(startTime) % 3600) / 60
        let seconds = Int(startTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

private enum ResultTabType {
    case transcription
    case aiAnalysis
    case aiSummary
}

class WorkflowResultViewController: UIViewController {
    // MARK: - UI Components

    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let progressContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 4
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.startAnimating()
            return indicator
        }
        // Fallback on earlier versions
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        return indicator
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        label.text = NSLocalizedString("workflow.progress.transcribing", comment: "Transcribing status")
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = NSLocalizedString("workflow.progress.description", comment: "Transcribing description")
        return label
    }()

    private let resultsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        return tableView
    }()

    private let aiResultsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isHidden = true
        scrollView.backgroundColor = .clear
        return scrollView
    }()

    private let aiResultsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        return stackView
    }()

    private lazy var emptyTranscriptLabel: UILabel = createEmptyStateLabel(with: NSLocalizedString("workflow.result.empty.transcription", comment: "Empty transcription message"))
    private lazy var emptyAILabel: UILabel = createEmptyStateLabel(with: NSLocalizedString("workflow.result.empty.ai_analysis", comment: "Empty AI analysis message"))

    private var transcriptSegments: [TranscriptSegment] = []
    private var segmentMap: [Int: ResultTabType] = [:]
    private var currentResponse: WorkflowResultResponse?
    private var titleLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Unified background color in CloudSyncViewController style
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        setupUI()
        setupNavigationBar()
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
    }

    private func setupNavigationBar() {
        // SaaS style large bold title
        titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("workflow.result.title", comment: "Result page title")
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
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
        let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeTapped))
        closeButton.tintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        navigationItem.rightBarButtonItem = closeButton
    }

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func updateNavigationTitle(response: WorkflowResultResponse) {
        var titleComponents: [String] = []

        // Check various task types and add corresponding title components
        if response.tasks.contains(where: { $0.taskType == "audio_transcribe" && $0.status == "SUCCESS" }) {
            titleComponents.append(NSLocalizedString("workflow.result.tab.transcription", comment: "Transcription"))
        }

        if response.tasks.contains(where: { $0.taskType == "ai_summarize" && $0.status == "SUCCESS" }) {
            titleComponents.append(NSLocalizedString("workflow.result.tab.ai_summary", comment: "Summary"))
        }

        if response.tasks.contains(where: { $0.taskType == "ai_etl" && $0.status == "SUCCESS" }) {
            titleComponents.append(NSLocalizedString("workflow.result.tab.ai_analysis", comment: "Analysis"))
        }

        // Set appropriate title based on task count
        if titleComponents.isEmpty {
            titleLabel.text = NSLocalizedString("workflow.result.title", comment: "Result page title")
        } else if titleComponents.count == 1 {
            titleLabel.text = titleComponents.first
        } else {
            // For multiple tasks, use generic "Transcription Results" title
            titleLabel.text = NSLocalizedString("workflow.result.title", comment: "Result page title")
        }
    }

    private func setupUI() {
        // SaaS style background color
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        segmentedControl.isHidden = true
        // Progress view card style
        progressContainerView.backgroundColor = .white
        progressContainerView.layer.cornerRadius = 16
        progressContainerView.layer.shadowColor = UIColor(white: 0, alpha: 0.08).cgColor
        progressContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        progressContainerView.layer.shadowOpacity = 1
        progressContainerView.layer.shadowRadius = 8

        // Progress View Setup
        view.addSubview(progressContainerView)
        progressContainerView.addSubview(activityIndicator)
        progressContainerView.addSubview(statusLabel)
        progressContainerView.addSubview(descriptionLabel)

        // Segmented Control Setup
        view.addSubview(segmentedControl)
        segmentedControl.backgroundColor = .white
        segmentedControl.layer.cornerRadius = 8
        segmentedControl.layer.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1).cgColor
        segmentedControl.layer.shadowOffset = CGSize(width: 0, height: 1)
        segmentedControl.layer.shadowOpacity = 1
        segmentedControl.layer.shadowRadius = 2

        // Set segmentedControl text color and font
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            segmentedControl.setTitleTextAttributes([
                .foregroundColor: UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            ], for: .normal)
            segmentedControl.setTitleTextAttributes([
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            ], for: .selected)
        } else {
            // Settings for iOS 12 and below
            segmentedControl.tintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            segmentedControl.setTitleTextAttributes([
                .foregroundColor: UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            ], for: .normal)
            segmentedControl.setTitleTextAttributes([
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            ], for: .selected)
        }

        // Results View Setup
        view.addSubview(resultsTableView)
        resultsTableView.dataSource = self
        resultsTableView.register(TranscriptSegmentCell.self, forCellReuseIdentifier: "TranscriptSegmentCell")
        resultsTableView.rowHeight = UITableView.automaticDimension
        resultsTableView.estimatedRowHeight = 100
        resultsTableView.backgroundView = emptyTranscriptLabel

        view.addSubview(aiResultsScrollView)
        aiResultsScrollView.addSubview(aiResultsStackView)
        aiResultsScrollView.addSubview(emptyAILabel)

        resultsTableView.backgroundColor = .clear // Keep consistent with CloudSyncViewController
        aiResultsScrollView.backgroundColor = .clear

        // Results table card-style cell
        resultsTableView.separatorStyle = .none
        resultsTableView.backgroundColor = .clear
        resultsTableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        // AI results scroll area section card-style
        aiResultsStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        aiResultsStackView.isLayoutMarginsRelativeArrangement = true

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Segmented Control Constraints
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),

            progressContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            activityIndicator.topAnchor.constraint(equalTo: progressContainerView.topAnchor, constant: 16),
            activityIndicator.centerXAnchor.constraint(equalTo: progressContainerView.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: progressContainerView.bottomAnchor, constant: -16),

            resultsTableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            resultsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            aiResultsScrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            aiResultsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            aiResultsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            aiResultsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            aiResultsStackView.topAnchor.constraint(equalTo: aiResultsScrollView.topAnchor, constant: 20),
            aiResultsStackView.bottomAnchor.constraint(equalTo: aiResultsScrollView.bottomAnchor, constant: -20),
            aiResultsStackView.leadingAnchor.constraint(equalTo: aiResultsScrollView.leadingAnchor, constant: 16),
            aiResultsStackView.trailingAnchor.constraint(equalTo: aiResultsScrollView.trailingAnchor, constant: -16),
            aiResultsStackView.widthAnchor.constraint(equalTo: aiResultsScrollView.widthAnchor, constant: -32),

            emptyAILabel.centerXAnchor.constraint(equalTo: aiResultsScrollView.centerXAnchor),
            emptyAILabel.centerYAnchor.constraint(equalTo: aiResultsScrollView.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func segmentedControlChanged() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        guard let tabType = segmentMap[selectedIndex],
              let response = currentResponse
        else {
            print("DEBUG: segmentedControlChanged failed - selectedIndex: \(selectedIndex), tabType: \(segmentMap[selectedIndex] as Any), response: \(currentResponse != nil)")
            return
        }

        print("DEBUG: segmentedControlChanged - tabType: \(tabType)")

        // First hide all views
        resultsTableView.isHidden = true
        aiResultsScrollView.isHidden = true

        switch tabType {
        case .transcription:
            resultsTableView.isHidden = false
            view.bringSubviewToFront(resultsTableView)
            print("DEBUG: Showing transcription view")
        case .aiAnalysis:
            aiResultsScrollView.isHidden = false
            view.bringSubviewToFront(aiResultsScrollView)
            setupAIEtlView(with: response)
            print("DEBUG: Showing AI analysis view")
        case .aiSummary:
            aiResultsScrollView.isHidden = false
            view.bringSubviewToFront(aiResultsScrollView)
            setupAISummaryView(with: response)
            print("DEBUG: Showing AI summary view")
        }
    }

    // MARK: - Public Methods

    public func updateProgress(status: String, message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = status
            self.descriptionLabel.text = message
        }
    }

    public func displayResults(response: WorkflowResultResponse?) {
        DispatchQueue.main.async {
            self.progressContainerView.isHidden = true

            guard let response = response else {
                // Handle complete failure case
                self.statusLabel.text = NSLocalizedString("workflow.progress.failed", comment: "Transcribing failed status")
                let errorMessage = NSLocalizedString("workflow.progress.failed_description", comment: "Transcribing failed description")
                self.descriptionLabel.text = errorMessage
                self.activityIndicator.stopAnimating()
                return
            }

            // Dynamically check actual task results
            let hasTranscriptTask = response.tasks.contains { $0.taskType == "audio_transcribe" && $0.status == "SUCCESS" }
            let hasAIEtlTask = response.tasks.contains { $0.taskType == "ai_etl" && $0.status == "SUCCESS" }
            let hasAISummaryTask = response.tasks.contains { $0.taskType == "ai_summarize" && $0.status == "SUCCESS" }

            print("DEBUG: displayResults - hasTranscriptTask: \(hasTranscriptTask), hasAIEtlTask: \(hasAIEtlTask), hasAISummaryTask: \(hasAISummaryTask)")
            print("DEBUG: response.tasks count: \(response.tasks.count)")

            if !hasTranscriptTask && !hasAIEtlTask && !hasAISummaryTask {
                // No successful tasks, show failure information
                self.statusLabel.text = NSLocalizedString("workflow.progress.failed", comment: "Transcribing failed status")
                let errorMessage = NSLocalizedString("workflow.progress.failed_description", comment: "Transcribing failed description")
                self.descriptionLabel.text = errorMessage
                self.activityIndicator.stopAnimating()
                return
            }

                            // Has successful tasks, show results
            self.segmentedControl.isHidden = false
            self.segmentedControl.removeAllSegments() // Rebuild dynamically
            self.segmentMap.removeAll()

            if hasTranscriptTask {
                let index = self.segmentedControl.numberOfSegments
                self.segmentedControl.insertSegment(withTitle: NSLocalizedString("workflow.result.tab.transcription", comment: "Transcription tab"), at: index, animated: false)
                self.segmentMap[index] = .transcription
                self.parseAndSetSegments(response.firstTranscriptResult?.segments ?? [])
                self.resultsTableView.reloadData()
                self.emptyTranscriptLabel.isHidden = !self.transcriptSegments.isEmpty
                if self.transcriptSegments.isEmpty {
                    self.emptyTranscriptLabel.text = NSLocalizedString("workflow.result.empty.transcription", comment: "No transcription content available")
                    self.emptyTranscriptLabel.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
                    self.emptyTranscriptLabel.font = .systemFont(ofSize: 16)
                    self.emptyTranscriptLabel.textAlignment = .center
                }
            }

            if hasAIEtlTask {
                let index = self.segmentedControl.numberOfSegments
                self.segmentedControl.insertSegment(withTitle: NSLocalizedString("workflow.result.tab.ai_analysis", comment: "AI Analysis tab"), at: index, animated: false)
                self.segmentMap[index] = .aiAnalysis
            }

            if hasAISummaryTask {
                let index = self.segmentedControl.numberOfSegments
                self.segmentedControl.insertSegment(withTitle: NSLocalizedString("workflow.result.tab.ai_summary", comment: "AI Summary tab"), at: index, animated: false)
                self.segmentMap[index] = .aiSummary
            }

            if self.segmentedControl.numberOfSegments > 0 {
                self.segmentedControl.selectedSegmentIndex = 0
                // Manually trigger switch event to ensure view displays correctly
                DispatchQueue.main.async {
                    self.segmentedControlChanged()
                }
            } else {
                // This case should ideally show a general "no content" message.
                self.descriptionLabel.text = NSLocalizedString("workflow.result.empty.general", comment: "Generic empty result message")
                self.progressContainerView.isHidden = false
                self.activityIndicator.stopAnimating()
            }

            // Store response for later use
            self.currentResponse = response

            // Update title
            self.updateNavigationTitle(response: response)

            // Ensure segmentedControl displays at the front
            self.view.bringSubviewToFront(self.segmentedControl)
        }
    }

    private func setupAIEtlView(with response: WorkflowResultResponse) {
        // Clear previous results
        aiResultsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Get AI ETL task results
        guard let aiEtlTask = response.tasks.first(where: { $0.taskType == "ai_etl" && $0.status == "SUCCESS" }),
              let aiEtlResult = aiEtlTask.aiEtlResult
        else {
            emptyAILabel.isHidden = false
            emptyAILabel.text = NSLocalizedString("workflow.result.empty.ai_analysis", comment: "No AI analysis content available")
            return
        }

        emptyAILabel.isHidden = true

        // Add clinical report
        if let clinicalReport = aiEtlResult.clinicalReport, !clinicalReport.isEmpty {
            addAISection(title: NSLocalizedString("workflow.result.ai.clinical_report", comment: "Clinical Report"), content: clinicalReport)
        }

        // Add summary
        if let summary = aiEtlResult.summary, !summary.isEmpty {
            addAISection(title: NSLocalizedString("workflow.result.ai.summary", comment: "Summary"), content: summary)
        }

        // Add content
        if let content = aiEtlResult.content, !content.isEmpty {
            addAISection(title: NSLocalizedString("workflow.result.ai.content", comment: "Content"), content: content)
        }

        // Add deal analysis information
        if let dealAnalysis = aiEtlResult.dealAnalysis {
            var dealContent = ""
            if let status = dealAnalysis.status {
                dealContent += "\(NSLocalizedString("workflow.result.ai.deal_status", comment: "Deal Status")): \(status)\n"
            }
            if let intention = dealAnalysis.intention?.description {
                dealContent += "\(NSLocalizedString("workflow.result.ai.deal_intention", comment: "Deal Intention")): \(intention)\n"
            }
            if let rating = dealAnalysis.intention?.rating {
                dealContent += "\(NSLocalizedString("workflow.result.ai.deal_rating", comment: "Deal Rating")): \(rating)\n"
            }
            if !dealContent.isEmpty {
                addAISection(title: NSLocalizedString("workflow.result.ai.deal_analysis", comment: "Deal Analysis"), content: dealContent.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        // Add communication feedback information
        if let commFeedback = aiEtlResult.communicationFeedback {
            var feedbackContent = ""
            if let highlight = commFeedback.highlight {
                feedbackContent += "\(NSLocalizedString("workflow.result.ai.comm_highlight", comment: "Communication Highlight")): \(highlight)\n"
            }
            if let suggestion = commFeedback.suggestion {
                feedbackContent += "\(NSLocalizedString("workflow.result.ai.comm_suggestion", comment: "Communication Suggestion")): \(suggestion)\n"
            }
            if !feedbackContent.isEmpty {
                addAISection(title: NSLocalizedString("workflow.result.ai.comm_feedback", comment: "Communication Feedback"), content: feedbackContent.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        // Add customer appellation
        if let appellation = aiEtlResult.appellation, !appellation.isEmpty {
            addAISection(title: NSLocalizedString("workflow.result.ai.customer_appellation", comment: "Customer Appellation"), content: appellation)
        }

        // Add transcription information (if AI ETL task contains transcription data)
        if let transcription = aiEtlResult.transcription, !transcription.segments.isEmpty {
            let transcriptText = transcription.segments.map { $0.text }.joined(separator: " ")
            addAISection(title: NSLocalizedString("workflow.result.ai.transcription", comment: "Transcription"), content: transcriptText)
        }
    }

    private func setupAISummaryView(with response: WorkflowResultResponse) {
        // Clear previous results
        aiResultsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        print("DEBUG: setupAISummaryView called")

        // Get AI summary task results
        guard let aiSummaryTask = response.tasks.first(where: { $0.taskType == "ai_summarize" && $0.status == "SUCCESS" }) else {
            print("DEBUG: No ai_summarize task found with SUCCESS status")
            emptyAILabel.isHidden = false
            emptyAILabel.text = NSLocalizedString("workflow.result.empty.ai_summary", comment: "No AI summary content available")
            return
        }

        print("DEBUG: Found ai_summarize task: \(aiSummaryTask)")
        print("DEBUG: Task result: \(aiSummaryTask.result as Any)")

        // Add debug printing
        aiSummaryTask.debugPrintTaskResult()

        // Try to use convenient method to get AI summary results
        var aiSummaryResult = aiSummaryTask.aiSummaryResult

        // If results obtained through the fixed method, use directly
        if let aiSummaryResult = aiSummaryResult {
            print("DEBUG: ✅ AI summary result parsed successfully, starting to display content")
            displayParsedAISummaryResult(aiSummaryResult)
            return
        }

        // If parsing still fails after the fix, try manual extraction
                        print("DEBUG: AI summary result parsing failed, attempting manual extraction")

        // Extract data directly from AI summary task result
        if let result = aiSummaryTask.result,
           let resultDict = result.value as? [String: Any]
        {
            print("DEBUG: Found task result dict with keys: \(Array(resultDict.keys))")

            // Try to extract nested result.result structure
            if let innerResult = resultDict["result"] as? [String: Any] {
                print("DEBUG: Found inner result with keys: \(Array(innerResult.keys))")

                var extractedSections = 0

                // Extract summary
                if let summary = innerResult["summary"] as? String, !summary.isEmpty {
                    print("DEBUG: Extracted summary: \(summary.prefix(100))...")
                    addAISection(title: "AI Summary", content: summary)
                    extractedSections += 1
                }

                // Extract AI suggestion
                if let aiSuggestion = innerResult["ai_suggestion"] as? String, !aiSuggestion.isEmpty {
                    print("DEBUG: Extracted AI suggestion: \(aiSuggestion.prefix(100))...")
                    addAISection(title: "AI Suggestion", content: aiSuggestion)
                    extractedSections += 1
                }

                // Extract Markdown content
                if let markdown = innerResult["markdown"] as? String, !markdown.isEmpty {
                    print("DEBUG: Extracted markdown content length: \(markdown.count)")
                    addAISection(title: "Detailed Content", content: markdown)
                    extractedSections += 1
                }

                // Extract topic content
                if let contents = innerResult["contents"] as? [[String: Any]],
                   let firstContent = contents.first,
                   let topics = firstContent["topics"] as? [[String: Any]]
                {
                    print("DEBUG: Extracted \(topics.count) topics")

                    var topicsText = ""
                    for topic in topics {
                        if let topicName = topic["topic"] as? String {
                            topicsText += "• \(topicName)\n"
                            if let description = topic["description"] as? String, !description.isEmpty {
                                topicsText += "  \(description)\n"
                            }
                        }
                    }

                    if !topicsText.isEmpty {
                        addAISection(title: "Meeting Topics", content: topicsText.trimmingCharacters(in: .whitespacesAndNewlines))
                        extractedSections += 1
                    }
                }

                // Extract header information
                if let header = innerResult["header"] as? [String: Any] {
                    var headerInfo = ""
                    if let headline = header["headline"] as? String {
                        headerInfo += "Title: \(headline)\n"
                    }
                    if let category = header["category"] as? String {
                        headerInfo += "Category: \(category)\n"
                    }
                    if let keywords = header["keywords"] as? [String], !keywords.isEmpty {
                        headerInfo += "Keywords: \(keywords.joined(separator: ", "))\n"
                    }

                    if !headerInfo.isEmpty {
                        addAISection(title: "Meeting Information", content: headerInfo.trimmingCharacters(in: .whitespacesAndNewlines))
                        extractedSections += 1
                    }
                }

                if extractedSections > 0 {
                    print("DEBUG: Successfully extracted \(extractedSections) sections from task result")
                    emptyAILabel.isHidden = true
                    return
                } else {
                    print("DEBUG: No sections could be extracted from task result")
                }
            } else {
                print("DEBUG: Could not find result.result structure in task result")
                print("DEBUG: Available keys in result: \(Array(resultDict.keys))")

                // Try to extract content directly from result dictionary
                var extractedSections = 0

                // Try to extract summary directly
                if let summary = resultDict["summary"] as? String, !summary.isEmpty {
                    print("DEBUG: Extracted summary directly: \(summary.prefix(100))...")
                    addAISection(title: "AI Summary", content: summary)
                    extractedSections += 1
                }

                // Try to extract AI suggestion directly
                if let aiSuggestion = resultDict["ai_suggestion"] as? String, !aiSuggestion.isEmpty {
                    print("DEBUG: Extracted AI suggestion directly: \(aiSuggestion.prefix(100))...")
                    addAISection(title: "AI Suggestion", content: aiSuggestion)
                    extractedSections += 1
                }

                if extractedSections > 0 {
                    print("DEBUG: Successfully extracted \(extractedSections) sections directly from result dict")
                    emptyAILabel.isHidden = true
                    return
                }
            }
        } else {
            print("DEBUG: Task result is nil or not a dictionary")
            print("DEBUG: Task result type: \(type(of: aiSummaryTask.result))")
            print("DEBUG: Task result value: \(aiSummaryTask.result as Any)")
        }

        // If still unable to extract, try to extract directly from original text field
        if let result = aiSummaryTask.result,
           let resultDict = result.value as? [String: Any],
           let text = resultDict["text"] as? String, !text.isEmpty
        {
                            print("DEBUG: Found original text field, content length: \(text.count)")
            // Show original transcription text as backup content for AI summary
            addAISection(title: "AI Summary", content: "AI Summary based on the following content:\n\n\(text)")
            emptyAILabel.isHidden = true
            return
        }

        // Last fallback option, show basic task information
        var rawInfo = "AI Summary task completed\n\n"
        rawInfo += "Task ID: \(aiSummaryTask.taskId)\n"
        rawInfo += "Status: \(aiSummaryTask.status)\n"
        if let startTime = aiSummaryTask.startTime, let endTime = aiSummaryTask.endTime {
            let duration = Double(endTime - startTime) / 1000.0
            rawInfo += "Processing time: \(String(format: "%.2f", duration)) seconds\n"
        }
        rawInfo += "\nPlease check data format or contact technical support."

        print("DEBUG: Showing fallback info")
        addAISection(title: "AI Summary", content: rawInfo)
        emptyAILabel.isHidden = true
    }

    private func displayParsedAISummaryResult(_ aiSummaryResult: AISummaryResult) {
        print("DEBUG: Starting to display parsed AI summary results")
        print("DEBUG: aiSummaryResult.result?.result?.markdown = \(aiSummaryResult.result?.result?.markdown ?? "nil")")
        print("DEBUG: aiSummaryResult.result?.result?.aiSuggestion = \(aiSummaryResult.result?.result?.aiSuggestion ?? "nil")")
        print("DEBUG: aiSummaryResult.result?.result?.summary = \(aiSummaryResult.result?.result?.summary ?? "nil")")
        print("DEBUG: aiSummaryResult.extractedMarkdown = \(aiSummaryResult.extractedMarkdown ?? "nil")")
        print("DEBUG: aiSummaryResult.extractedSummary = \(aiSummaryResult.extractedSummary ?? "nil")")

        emptyAILabel.isHidden = true

        var addedSections = 0

        // First try to add Markdown format content (this is the most complete content)
        if let markdown = aiSummaryResult.extractedMarkdown, !markdown.isEmpty {
            print("DEBUG: Adding Markdown content (length: \(markdown.count))")
            addAISection(title: "AI Summary", content: markdown)
            addedSections += 1
        }

        // Add AI suggestion
        if let aiSuggestion = aiSummaryResult.result?.result?.aiSuggestion, !aiSuggestion.isEmpty {
            print("DEBUG: Adding AI suggestion: \(aiSuggestion.prefix(100))...")
            addAISection(title: "AI Suggestion", content: aiSuggestion)
            addedSections += 1
        }

        // Add summary content (if there's a separate summary field)
        if let summary = aiSummaryResult.extractedSummary, !summary.isEmpty {
            print("DEBUG: Adding summary content: \(summary.prefix(100))...")
            addAISection(title: "Summary", content: summary)
            addedSections += 1
        }

        // Add key points
        if let keyPoints = aiSummaryResult.extractedKeyPoints, !keyPoints.isEmpty {
            print("DEBUG: Adding key points: \(keyPoints)")
            let keyPointsContent = keyPoints.joined(separator: "\n• ")
            addAISection(title: "Key Points", content: "• " + keyPointsContent)
            addedSections += 1
        }

        // Add action items
        if let actionItems = aiSummaryResult.extractedActionItems, !actionItems.isEmpty {
            print("DEBUG: Adding action items: \(actionItems)")
            let actionItemsContent = actionItems.joined(separator: "\n• ")
            addAISection(title: "Action Items", content: "• " + actionItemsContent)
            addedSections += 1
        }

        // Add participants
        if let participants = aiSummaryResult.extractedParticipants, !participants.isEmpty {
            print("DEBUG: Adding participants: \(participants)")
            let participantsContent = participants.joined(separator: ", ")
            addAISection(title: "Participants", content: participantsContent)
            addedSections += 1
        }

        // Add header information (title, keywords, etc.)
        if let header = aiSummaryResult.result?.result?.header {
            var headerContent = ""
            if let headline = header.headline, !headline.isEmpty {
                headerContent += "Title: \(headline)\n"
            }
            if let keywords = header.keywords, !keywords.isEmpty {
                headerContent += "Keywords: \(keywords.joined(separator: ", "))\n"
            }
            if let category = header.category, !category.isEmpty {
                headerContent += "Category: \(category)\n"
            }
            if !headerContent.isEmpty {
                print("DEBUG: Adding header information")
                addAISection(title: "Meeting Information", content: headerContent.trimmingCharacters(in: .whitespacesAndNewlines))
                addedSections += 1
            }
        }

        // Add model information
        var modelInfo = ""

        // Build model info with explicit statements
        do {
            if let model = aiSummaryResult.extractedModel {
                modelInfo += "Model: \(model)\n"
            }
        }

        do {
            if let language = aiSummaryResult.extractedLanguage {
                modelInfo += "Language: \(language)\n"
            }
        }

        do {
            if let template = aiSummaryResult.template {
                modelInfo += "Template: \(template)\n"
            }
        }

        do {
            if let duration = aiSummaryResult.duration {
                modelInfo += "Duration: \(duration)"
            }
        }

        if !modelInfo.isEmpty {
            print("DEBUG: Adding model information: \(modelInfo)")
            addAISection(title: "Model Information", content: modelInfo.trimmingCharacters(in: .whitespacesAndNewlines))
            addedSections += 1
        }

        print("DEBUG: Total of \(addedSections) sections added")

        // If no content was added, try to show raw data or detailed error information
        if addedSections == 0 {
            print("DEBUG: No displayable content, attempting to show raw data")

            // Try to extract any available information from raw data
            if let text = aiSummaryResult.text, !text.isEmpty {
                print("DEBUG: Using raw text content")
                addAISection(title: "AI Summary", content: "Raw content:\n\n\(text)")
                addedSections += 1
            } else if let content = aiSummaryResult.content, !content.isEmpty {
                print("DEBUG: Using content")
                addAISection(title: "AI Summary", content: content)
                addedSections += 1
            } else if let summary = aiSummaryResult.summary, !summary.isEmpty {
                print("DEBUG: Using summary content")
                addAISection(title: "AI Summary", content: summary)
                addedSections += 1
            }

            // If still no content, show debug information
            if addedSections == 0 {
                var debugInfo = "AI Summary task completed\n\nDebug information:\n"
                debugInfo += "• Status: \(aiSummaryResult.status ?? "Unknown")\n"
                debugInfo += "• Model: \(aiSummaryResult.model ?? "Unknown")\n"
                debugInfo += "• Template: \(aiSummaryResult.template ?? "Unknown")\n"
                debugInfo += "• Duration: \(aiSummaryResult.duration ?? "Unknown")\n"
                debugInfo += "\nData structure may not match, please contact technical support."

                print("DEBUG: Showing debug information")
                addAISection(title: "AI Summary", content: debugInfo)
            }
        }
    }

    private func addAISection(title: String, content: String?) {
        guard let content = content, !content.isEmpty else { return }
        let sectionView = UIView()
        sectionView.backgroundColor = .white
        sectionView.layer.cornerRadius = 12
        sectionView.layer.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1).cgColor
        sectionView.layer.shadowOffset = CGSize(width: 0, height: 2)
        sectionView.layer.shadowOpacity = 1
        sectionView.layer.shadowRadius = 4
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = .systemFont(ofSize: 17)
        contentLabel.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addSubview(titleLabel)
        sectionView.addSubview(contentLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor, constant: -16),
        ])
        aiResultsStackView.addArrangedSubview(sectionView)
    }

    private func parseAndSetSegments(_ segments: [PlaudDeviceBasicSDK.TranscriptSegment]) {
        // Directly use SDK's TranscriptSegment array, convert to internal TranscriptSegment structure
        var parsedSegments: [TranscriptSegment] = []
        for segment in segments {
            let internalSegment = TranscriptSegment(
                speaker: segment.speaker,
                startTime: segment.start,
                text: segment.text
            )
            parsedSegments.append(internalSegment)
        }
        transcriptSegments = parsedSegments
    }

    private func createEmptyStateLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }
}

// MARK: - UITableViewDataSource

extension WorkflowResultViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return transcriptSegments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TranscriptSegmentCell", for: indexPath) as? TranscriptSegmentCell else {
            return UITableViewCell()
        }
        let segment = transcriptSegments[indexPath.row]
        cell.configure(with: segment)
        return cell
    }
}

// MARK: - TranscriptSegmentCell

class TranscriptSegmentCell: UITableViewCell {
    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let speakerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        return label
    }()

    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        } else {
            label.font = .systemFont(ofSize: 14)
        }
        label.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        return label
    }()

    private let transcriptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(container)
        let stackView = UIStackView(arrangedSubviews: [speakerLabel, timestampLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        container.addSubview(stackView)
        container.addSubview(transcriptLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        transcriptLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            transcriptLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
            transcriptLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            transcriptLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            transcriptLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with segment: TranscriptSegment) {
        speakerLabel.text = String(format: NSLocalizedString("workflow.result.speaker", comment: "Speaker label format"), segment.speaker)
        timestampLabel.text = segment.formattedTimestamp
        transcriptLabel.text = segment.text
    }
}
