import AVFoundation
import UIKit

class AudioPlayerViewController: UIViewController, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    private let filePath: String
    private var isPlaying = false
    private var updateTimer: Timer?

    // UI
    private let cardView = UIView()
    private let fileNameLabel = UILabel()
    private let statusLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let timeLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    init(filePath: String) {
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        title = NSLocalizedString("audio.player.title", comment: "")
        setupUI()
        setupAudioPlayer()
    }

    private func setupUI() {
        // Card style
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor(white: 0, alpha: 0.1).cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowRadius = 4
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        // File name
        fileNameLabel.text = (filePath as NSString).lastPathComponent
        fileNameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        fileNameLabel.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        fileNameLabel.textAlignment = .center
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(fileNameLabel)

        // Status
        statusLabel.text = NSLocalizedString("audio.player.status.ready", comment: "")
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(statusLabel)

        // Progress bar
        progressView.progressTintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        progressView.trackTintColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(progressView)

        // Time
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        timeLabel.textAlignment = .center
        timeLabel.text = "00:00 / 00:00"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(timeLabel)

        // Playback control area
        let controlsStack = UIStackView(arrangedSubviews: [prevButton, playPauseButton, nextButton])
        controlsStack.axis = .horizontal
        controlsStack.spacing = 32
        controlsStack.alignment = .center
        controlsStack.distribution = .equalCentering
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(controlsStack)

        // Play/pause button
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        playPauseButton.backgroundColor = UIColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0)
        playPauseButton.layer.cornerRadius = 32
        playPauseButton.clipsToBounds = true
        playPauseButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        // Previous/next track (disabled, gray)
        prevButton.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        prevButton.tintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        prevButton.isEnabled = false
        prevButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        prevButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        nextButton.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        nextButton.tintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        nextButton.isEnabled = false
        nextButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        nextButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Stop button
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.tintColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        stopButton.backgroundColor = UIColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0)
        stopButton.layer.cornerRadius = 20
        stopButton.clipsToBounds = true
        stopButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        stopButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        cardView.addSubview(stopButton)

        // Layout
        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cardView.heightAnchor.constraint(equalToConstant: 340),

            fileNameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            fileNameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            fileNameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            progressView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            timeLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            timeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            controlsStack.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 24),
            controlsStack.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            stopButton.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 24),
            stopButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
        ])
    }

    private func setupAudioPlayer() {
        let url = URL(fileURLWithPath: filePath)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            updateTimeAndProgress()
        } catch {
            statusLabel.text = String(format: NSLocalizedString("audio.player.status.load_error", comment: ""), error.localizedDescription)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTapped()
        try? AVAudioSession.sharedInstance().setActive(false)
        updateTimer?.invalidate()
        updateTimer = nil
    }

    // MARK: - Timer Methods

    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimeAndProgress()
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateTimeAndProgress() {
        guard let player = audioPlayer else { return }
        let currentTime = formatTime(player.currentTime)
        let duration = formatTime(player.duration)
        timeLabel.text = "\(currentTime) / \(duration)"
        progressView.progress = player.duration > 0 ? Float(player.currentTime / player.duration) : 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Button Actions

    @objc private func playPauseTapped() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            statusLabel.text = NSLocalizedString("audio.player.status.paused", comment: "")
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            stopUpdateTimer()
        } else {
            player.play()
            isPlaying = true
            statusLabel.text = NSLocalizedString("audio.player.status.playing", comment: "")
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            startUpdateTimer()
        }
    }

    @objc private func stopTapped() {
        guard let player = audioPlayer else { return }
        player.stop()
        player.currentTime = 0
        isPlaying = false
        statusLabel.text = NSLocalizedString("audio.player.status.stopped", comment: "")
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        stopUpdateTimer()
        updateTimeAndProgress()
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        statusLabel.text = flag ? NSLocalizedString("audio.player.status.completed", comment: "") : NSLocalizedString("audio.player.status.error", comment: "")
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        stopUpdateTimer()
        updateTimeAndProgress()
    }

    func audioPlayerDecodeErrorDidOccur(_: AVAudioPlayer, error: Error?) {
        isPlaying = false
        let errorMessage = error?.localizedDescription ?? NSLocalizedString("audio.player.status.decode_unknown_error", comment: "")
        statusLabel.text = String(format: NSLocalizedString("audio.player.status.decode_error", comment: ""), errorMessage)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        stopUpdateTimer()
    }

    func audioPlayerBeginInterruption(_: AVAudioPlayer) {
        playPauseTapped()
    }

    func audioPlayerEndInterruption(_: AVAudioPlayer, withOptions _: Int) {
        if isPlaying {
            playPauseTapped()
        }
    }
}
