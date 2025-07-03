import PenBleSDK
import UIKit

// import PlaudFoundationSDKV2

class ActionsViewController: BaseViewController {
    private lazy var startRecordButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Start Recording", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = UIColor.lightGray
        return button
    }()

    private lazy var stopRecordButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Stop Recording", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = UIColor.lightGray
        return button
    }()

    private lazy var getFileListeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Sync File List", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = UIColor.lightGray
        return button
    }()

    private lazy var unbindButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Unbind", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = UIColor.lightGray
        return button
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        return tableView
    }()

    private var fileList: [BleFile] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Actions"

        view.addSubview(startRecordButton)
        view.addSubview(stopRecordButton)
        view.addSubview(getFileListeButton)
        view.addSubview(unbindButton)

        startRecordButton.translatesAutoresizingMaskIntoConstraints = false
        startRecordButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        startRecordButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        startRecordButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        stopRecordButton.heightAnchor.constraint(equalToConstant: 42).isActive = true

        stopRecordButton.translatesAutoresizingMaskIntoConstraints = false
        stopRecordButton.topAnchor.constraint(equalTo: startRecordButton.topAnchor).isActive = true
        stopRecordButton.leftAnchor.constraint(equalTo: startRecordButton.rightAnchor, constant: 20).isActive = true
        stopRecordButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        stopRecordButton.heightAnchor.constraint(equalToConstant: 42).isActive = true

        getFileListeButton.translatesAutoresizingMaskIntoConstraints = false
        getFileListeButton.topAnchor.constraint(equalTo: startRecordButton.bottomAnchor, constant: 20).isActive = true
        getFileListeButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        getFileListeButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        getFileListeButton.heightAnchor.constraint(equalToConstant: 42).isActive = true

        unbindButton.translatesAutoresizingMaskIntoConstraints = false
        unbindButton.topAnchor.constraint(equalTo: getFileListeButton.topAnchor).isActive = true
        unbindButton.leftAnchor.constraint(equalTo: stopRecordButton.leftAnchor).isActive = true
        unbindButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        unbindButton.heightAnchor.constraint(equalToConstant: 42).isActive = true

        startRecordButton.addTarget(self, action: #selector(startRecord(button:)), for: .touchUpInside)
        stopRecordButton.addTarget(self, action: #selector(stopRecord(button:)), for: .touchUpInside)
        getFileListeButton.addTarget(self, action: #selector(getFileList(button:)), for: .touchUpInside)
        unbindButton.addTarget(self, action: #selector(unbindPen(button:)), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard bleAgent.bleDevice != nil else {
            return
        }
    }

    @objc func startRecord(button _: UIButton) {
        bleAgent.startRecord()
    }

    @objc func stopRecord(button _: UIButton) {
        bleAgent.stopRecord()
    }

    @objc func getFileList(button _: UIButton) {
        let uid = Date().stamp
        if fileList.count > 0 {
            bleAgent.getFileList(uid: uid, sessionId: fileList.last!.sessionId)
        } else {
            bleAgent.getFileList(uid: uid, sessionId: 0)
        }
    }

    @objc func unbindPen(button _: UIButton) {
        bleAgent.depair(clear: false)
    }

    override func onDepair(_: Int) {
        UserDefaults.standard.removeObject(forKey: "bindedSN")
        UserDefaults.standard.synchronize()
        navigationController?.popViewController(animated: true)
    }

    override func onRecordStart(sessionId _: Int, start _: Int, status _: Int) {
        debugPrint("Recording started")
    }

    override func onRecordStop(sessionId _: Int, reason _: Int, fileExist _: Bool, fileSize _: Int) {
        debugPrint("Recording ended")
    }

    override func onFileList(bleFiles: [BleFile]) {
        // The last one will be duplicated, need to filter it out
        fileList.append(contentsOf: bleFiles)
        tableView.reloadData()
    }

    override func onSyncFileHead(sessionId _: Int, status _: Int) {
        debugPrint("Starting file download")
    }

    override func onSyncFileTail(sessionId _: Int, crc _: Int) {
        debugPrint("File download completed")
    }

    override func onData(sessionId _: Int, start _: Int, data _: Data) {
        // Raw data, used for saving recording files
    }

    override func onPcmData(sessionId _: Int, millsec _: Int, pcmData _: Data) {
        // Decoded PCM data, used for real-time transcription, waveform extraction, etc.
    }
}

extension ActionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "sessionId: \(fileList[indexPath.row].sessionId)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Click to download file
        let bleFile = fileList[indexPath.row]
        bleAgent.syncFile(sessionId: bleFile.sessionId, start: 0, end: 0, decode: false)
    }
}

extension Date {
            // Timestamp
    var stamp: Int {
        let timeInterval: TimeInterval = timeIntervalSince1970
        return Int(timeInterval)
    }
}
