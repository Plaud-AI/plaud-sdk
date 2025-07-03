import UIKit

// import SnapKit
import PenBleSDK

// import PenWiFiSdk
// import PlaudFoundationSDKV2
import PlaudDeviceBasicSDK

// import SnapKit

class MainViewController: BaseViewController {
    private let logTextView = UITextView().apply { textView in
        textView.text = ""
        textView.isEditable = false
    }

    private let bleRateLabel = UILabel().apply { label in
        label.textColor = .blue
    }

    private let scrollView = UIScrollView().apply { scrollView in
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }

    private let scanButton = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("main.button.scan_device", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let depairButton = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.unbind", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let getStateButton = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.get_state", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let getStorageButton = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.get_storage", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let resetPwdButton = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.reset_password", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let getPowerButton = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.get_battery", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let getRecordListBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.get_session_list", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let brightDurationItems = [
        NSLocalizedString("device.backlight.duration.10s", comment: ""),
        NSLocalizedString("device.backlight.duration.20s", comment: ""),
        NSLocalizedString("device.backlight.duration.30s", comment: ""),
        NSLocalizedString("device.backlight.duration.always", comment: ""),
    ]
    private lazy var brightDurationSegment = UISegmentedControl(items: brightDurationItems).apply { segment in
        segment.selectedSegmentIndex = 0
        segment.isMultipleTouchEnabled = false
        segment.setTitleTextAttributes([.foregroundColor: UIColor.blue, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.gray, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
    }

    private let readBacklightDurationBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Read Backlight Duration", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setBacklightDurationBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.backlight_duration", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let lightBrightSegment = UISegmentedControl(items: ["1", "2", "3", "4", "5", "6"]).apply { segment in
        segment.selectedSegmentIndex = 0
        segment.isMultipleTouchEnabled = false
        segment.setTitleTextAttributes([.foregroundColor: UIColor.blue, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.gray, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
    }

    private let readBacklightBrightBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.read_brightness", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setBacklightBrightBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.set_brightness", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let langSengment = UISegmentedControl(items: [
        NSLocalizedString("language.simplified_chinese", comment: ""),
        NSLocalizedString("language.traditional_chinese", comment: ""),
        NSLocalizedString("language.english", comment: ""),
    ]).apply { segment in
        segment.selectedSegmentIndex = 0
        segment.isMultipleTouchEnabled = false
        segment.setTitleTextAttributes([.foregroundColor: UIColor.blue, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.gray, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
    }

    private let readLangBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.read_language", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setLangBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.set_language", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let leftField = UITextField().apply { field in
        field.placeholder = NSLocalizedString("device.degree.left", comment: "")
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .numberPad
        field.backgroundColor = .lightGray
    }

    private let rightField = UITextField().apply { field in
        field.placeholder = NSLocalizedString("device.degree.right", comment: "")
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .numberPad
        field.backgroundColor = .lightGray
    }

    private let setDegreeBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.set_degree", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let readDegreeBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.action.read_degree", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let openWiFiBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.wifi_enable", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let closeWiFiBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.wifi_disable", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let ssidField = UITextField().apply { field in
        field.placeholder = "SSID"
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .default
        field.backgroundColor = .lightGray
    }

    private let pwdField = UITextField().apply { field in
        field.placeholder = "PWD"
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .asciiCapable
        field.backgroundColor = .lightGray
    }

    private let getWiFiBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.wifi_config_get", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setWiFiBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.wifi_config_set", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let startRecordBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.record_start", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let pauseRecordBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.record_pause", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let resumeRecordBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.record_resume", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let stopRecordBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.record_stop", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let syncFileBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.file_sync", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let syncFileStopBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.file_sync_stop", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let deleteFileBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.file_delete", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let clearFilesBtn = UIButton(type: .custom).apply { button in
        button.setTitle(NSLocalizedString("device.operation.file_clear", comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let ledStatusLabel = UILabel().apply { label in
        label.text = NSLocalizedString("device.status.light", comment: "")
        label.textColor = .black
    }

    private let ledStatusSwitch = UISwitch()

    private let privacyLabel = UILabel().apply { label in
        label.text = NSLocalizedString("device.status.privacy", comment: "")
        label.textColor = .black
    }

    private let privacySwitch = UISwitch()

    private let urlField = UITextField().apply { field in
        field.placeholder = NSLocalizedString("device.test.get_url", comment: "")
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .default
        field.backgroundColor = .lightGray
    }

    private let serTokenField = UITextField().apply { field in
        field.placeholder = "Websocket serToken"
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .asciiCapable
        field.backgroundColor = .lightGray
    }

    private let devTokenField = UITextField().apply { field in
        field.placeholder = "Websocket devToken"
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .asciiCapable
        field.backgroundColor = .lightGray
    }

    private let getWebsocketUrlBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Get URL", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let getWebsocketSerTokenBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Get serToken", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let getWebsocketDevTokenBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Get devToken", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setWebsocketUrlBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Set URL", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setWebsocketSerTokenBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Set serToken", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setWebsocketDevTokenBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Set devToken", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let testWebsocketBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Test Server", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let testBleRate80Btn = UIButton(type: .custom).apply { button in
        button.setTitle("Bluetooth Speed Test 80", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let testBleRate160Btn = UIButton(type: .custom).apply { button in
        button.setTitle("Bluetooth Speed Test 160", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let stopBleRateBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Stop Bluetooth Speed Test", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let packSizeField = UITextField().apply { field in
        field.placeholder = "WiFi Speed Test Packet Size"
        field.font = UIFont.systemFont(ofSize: 15)
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.keyboardType = .numberPad
        field.backgroundColor = .lightGray
    }

    private let testWiFiRateBtn = UIButton(type: .custom).apply { button in
        button.setTitle("WiFi Speed Test", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let stopWiFiRateBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Stop WiFi Speed Test", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let wifiGetRecordListBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Get Session List", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let wifiSyncFileBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Sync Files", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let wifiCloseBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Disconnect WiFi", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let readVadSensitivityBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Read VAD Sensitivity", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setVadSensitivityBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Set VAD Sensitivity", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let vadSensitivitySegment = UISegmentedControl(items: ["1", "2", "3"]).apply { segment in
        segment.selectedSegmentIndex = 0
        segment.isMultipleTouchEnabled = false
        segment.setTitleTextAttributes([.foregroundColor: UIColor.blue, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.gray, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
    }

    private let readVpuSensitivityBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Read VPU Sensitivity", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setVpuSensitivityBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Set VPU Sensitivity", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let vpuSensitivitySegment = UISegmentedControl(items: ["1", "2", "3"]).apply { segment in
        segment.selectedSegmentIndex = 0
        segment.isMultipleTouchEnabled = false
        segment.setTitleTextAttributes([.foregroundColor: UIColor.blue, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.gray, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
    }

    private let readMicGainBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Read Microphone Gain", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let setMicGainBtn = UIButton(type: .custom).apply { button in
        button.setTitle("Set Microphone Gain", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .lightGray
    }

    private let micGainSegment = UISegmentedControl(items: ["5", "10", "15", "20", "25", "30"]).apply { segment in
        segment.selectedSegmentIndex = 0
        segment.isMultipleTouchEnabled = false
        segment.setTitleTextAttributes([.foregroundColor: UIColor.blue, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.gray, .underlineStyle: 0, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
    }

    private var fileOffset = 0
    private var recordList = [BleFile]()
    private var syncIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("main.title", comment: "")
        // Set the first parameter to the appKey corresponding to the package name
        //        bleAgent.setUserIdentifier("0b1ef6247326fc79b200163e0a0431dc", "zcc1642155254133", false)
        bleAgent.setUserIdentifier("0b1ef6247326fc79b200163e0a0431dc", "123456789", false)

        bleAgent.initBluetooth()

        view.addSubview(logTextView)
        view.addSubview(bleRateLabel)
        view.addSubview(scrollView)

        logTextView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.right.equalToSuperview().inset(10)
            maker.height.equalTo(240)
        }
        bleRateLabel.snp.makeConstraints { maker in
            maker.bottom.right.equalTo(logTextView).inset(20)
        }
        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(logTextView.snp.bottom)
            maker.left.right.bottom.equalToSuperview()
        }

        let scrollContainer = UIView().apply { view in
            view.addSubview(scanButton)
            view.addSubview(depairButton)
            view.addSubview(getStateButton)
            view.addSubview(getStorageButton)

            view.addSubview(resetPwdButton)
            view.addSubview(getPowerButton)
            view.addSubview(getRecordListBtn)

            view.addSubview(brightDurationSegment)
            view.addSubview(readBacklightDurationBtn)
            view.addSubview(setBacklightDurationBtn)

            view.addSubview(lightBrightSegment)
            view.addSubview(readBacklightBrightBtn)
            view.addSubview(setBacklightBrightBtn)

            view.addSubview(langSengment)
            view.addSubview(readLangBtn)
            view.addSubview(setLangBtn)

            view.addSubview(leftField)
            view.addSubview(rightField)
            view.addSubview(setDegreeBtn)
            view.addSubview(readDegreeBtn)

            view.addSubview(ssidField)
            view.addSubview(pwdField)
            view.addSubview(openWiFiBtn)
            view.addSubview(closeWiFiBtn)
            view.addSubview(setWiFiBtn)
            view.addSubview(getWiFiBtn)

            view.addSubview(startRecordBtn)
            view.addSubview(pauseRecordBtn)
            view.addSubview(resumeRecordBtn)
            view.addSubview(stopRecordBtn)

            view.addSubview(syncFileBtn)
            view.addSubview(syncFileStopBtn)
            view.addSubview(deleteFileBtn)
            view.addSubview(clearFilesBtn)

            view.addSubview(ledStatusLabel)
            view.addSubview(ledStatusSwitch)
            view.addSubview(privacyLabel)
            view.addSubview(privacySwitch)

            view.addSubview(urlField)
            view.addSubview(serTokenField)
            view.addSubview(devTokenField)
            view.addSubview(getWebsocketUrlBtn)
            view.addSubview(getWebsocketSerTokenBtn)
            view.addSubview(getWebsocketDevTokenBtn)
            view.addSubview(setWebsocketUrlBtn)
            view.addSubview(setWebsocketSerTokenBtn)
            view.addSubview(setWebsocketDevTokenBtn)
            view.addSubview(testWebsocketBtn)

            view.addSubview(testBleRate80Btn)
            view.addSubview(testBleRate160Btn)
            view.addSubview(stopBleRateBtn)

            view.addSubview(packSizeField)
            view.addSubview(testWiFiRateBtn)
            view.addSubview(stopWiFiRateBtn)

            view.addSubview(wifiGetRecordListBtn)
            view.addSubview(wifiSyncFileBtn)
            view.addSubview(wifiCloseBtn)

            view.addSubview(readVadSensitivityBtn)
            view.addSubview(setVadSensitivityBtn)
            view.addSubview(vadSensitivitySegment)

            view.addSubview(readVpuSensitivityBtn)
            view.addSubview(setVpuSensitivityBtn)
            view.addSubview(vpuSensitivitySegment)

            view.addSubview(readMicGainBtn)
            view.addSubview(setMicGainBtn)
            view.addSubview(micGainSegment)

            scanButton.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(10)
                maker.left.equalToSuperview().inset(10)
                maker.size.equalTo(CGSize(width: 90, height: 36))
            }
            depairButton.snp.makeConstraints { maker in
                maker.top.equalTo(scanButton)
                maker.left.equalTo(scanButton.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            getStateButton.snp.makeConstraints { maker in
                maker.top.equalTo(scanButton)
                maker.left.equalTo(depairButton.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            getStorageButton.snp.makeConstraints { maker in
                maker.top.equalTo(scanButton)
                maker.left.equalTo(getStateButton.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            resetPwdButton.snp.makeConstraints { maker in
                maker.top.equalTo(scanButton.snp.bottom).offset(5)
                maker.left.size.equalTo(scanButton)
            }
            getPowerButton.snp.makeConstraints { maker in
                maker.top.equalTo(resetPwdButton)
                maker.left.equalTo(resetPwdButton.snp.right).offset(10)
                maker.size.equalTo(resetPwdButton)
            }
            getRecordListBtn.snp.makeConstraints { maker in
                maker.left.equalTo(getPowerButton.snp.right).offset(10)
                maker.top.size.equalTo(resetPwdButton)
            }

            brightDurationSegment.snp.makeConstraints { maker in
                maker.top.equalTo(resetPwdButton.snp.bottom).offset(5)
                maker.left.equalTo(resetPwdButton)
                maker.size.equalTo(CGSize(width: 190, height: 40))
            }

            readBacklightDurationBtn.snp.makeConstraints { maker in
                maker.top.equalTo(brightDurationSegment)
                maker.left.equalTo(brightDurationSegment.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            setBacklightDurationBtn.snp.makeConstraints { maker in
                maker.top.equalTo(brightDurationSegment)
                maker.left.equalTo(readBacklightDurationBtn.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }

            lightBrightSegment.snp.makeConstraints { maker in
                maker.top.equalTo(brightDurationSegment.snp.bottom).offset(5)
                maker.left.size.equalTo(brightDurationSegment)
            }
            readBacklightBrightBtn.snp.makeConstraints { maker in
                maker.top.equalTo(lightBrightSegment)
                maker.left.equalTo(lightBrightSegment.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            setBacklightBrightBtn.snp.makeConstraints { maker in
                maker.top.equalTo(lightBrightSegment)
                maker.left.equalTo(readBacklightBrightBtn.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }

            langSengment.snp.makeConstraints { maker in
                maker.top.equalTo(lightBrightSegment.snp.bottom).offset(5)
                maker.left.size.equalTo(brightDurationSegment)
            }
            readLangBtn.snp.makeConstraints { maker in
                maker.top.equalTo(langSengment)
                maker.left.equalTo(langSengment.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            setLangBtn.snp.makeConstraints { maker in
                maker.top.equalTo(langSengment)
                maker.left.equalTo(readLangBtn.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }

            leftField.snp.makeConstraints { maker in
                maker.top.equalTo(langSengment.snp.bottom).offset(5)
                maker.left.equalTo(resetPwdButton)
            }
            rightField.snp.makeConstraints { maker in
                maker.top.size.equalTo(leftField)
                maker.left.equalTo(getPowerButton)
            }
            readDegreeBtn.snp.makeConstraints { maker in
                maker.top.equalTo(leftField)
                maker.left.size.equalTo(readLangBtn)
            }
            setDegreeBtn.snp.makeConstraints { maker in
                maker.top.equalTo(leftField)
                maker.left.size.equalTo(setDegreeBtn)
            }

            ssidField.snp.makeConstraints { maker in
                maker.top.equalTo(leftField.snp.bottom).offset(5)
                maker.left.size.equalTo(langSengment)
            }
            pwdField.snp.makeConstraints { maker in
                maker.top.equalTo(ssidField)
                maker.left.equalTo(ssidField.snp.right).offset(10)
                maker.size.equalTo(ssidField)
            }
            openWiFiBtn.snp.makeConstraints { maker in
                maker.top.equalTo(ssidField.snp.bottom).offset(5)
                maker.left.equalTo(ssidField)
                maker.size.equalTo(scanButton)
            }
            closeWiFiBtn.snp.makeConstraints { maker in
                maker.top.size.equalTo(openWiFiBtn)
                maker.left.equalTo(openWiFiBtn.snp.right).offset(10)
            }
            getWiFiBtn.snp.makeConstraints { maker in
                maker.top.equalTo(openWiFiBtn)
                maker.left.equalTo(closeWiFiBtn.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            setWiFiBtn.snp.makeConstraints { maker in
                maker.top.equalTo(openWiFiBtn)
                maker.left.equalTo(getWiFiBtn.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }

            startRecordBtn.snp.makeConstraints { maker in
                maker.top.equalTo(openWiFiBtn.snp.bottom).offset(5)
                maker.left.size.equalTo(scanButton)
            }
            pauseRecordBtn.snp.makeConstraints { maker in
                maker.left.equalTo(startRecordBtn.snp.right).offset(10)
                maker.top.size.equalTo(startRecordBtn)
            }
            resumeRecordBtn.snp.makeConstraints { maker in
                maker.left.equalTo(pauseRecordBtn.snp.right).offset(10)
                maker.top.size.equalTo(startRecordBtn)
            }
            stopRecordBtn.snp.makeConstraints { maker in
                maker.left.equalTo(resumeRecordBtn.snp.right).offset(10)
                maker.top.size.equalTo(startRecordBtn)
            }

            syncFileBtn.snp.makeConstraints { maker in
                maker.top.equalTo(startRecordBtn.snp.bottom).offset(5)
                maker.left.size.equalTo(startRecordBtn)
            }
            syncFileStopBtn.snp.makeConstraints { maker in
                maker.left.equalTo(syncFileBtn.snp.right).offset(10)
                maker.top.size.equalTo(syncFileBtn)
            }
            deleteFileBtn.snp.makeConstraints { maker in
                maker.left.equalTo(syncFileStopBtn.snp.right).offset(10)
                maker.top.size.equalTo(syncFileBtn)
            }
            clearFilesBtn.snp.makeConstraints { maker in
                maker.left.equalTo(deleteFileBtn.snp.right).offset(10)
                maker.top.size.equalTo(syncFileBtn)
            }

            ledStatusSwitch.snp.makeConstraints { maker in
                maker.top.equalTo(syncFileBtn.snp.bottom).offset(5)
                maker.centerX.equalTo(syncFileStopBtn)
            }
            ledStatusLabel.snp.makeConstraints { maker in
                maker.right.equalTo(ledStatusSwitch.snp.left).offset(-10)
                maker.centerY.equalTo(ledStatusSwitch)
            }
            privacySwitch.snp.makeConstraints { maker in
                maker.top.equalTo(syncFileBtn.snp.bottom).offset(5)
                maker.centerX.equalTo(clearFilesBtn)
            }
            privacyLabel.snp.makeConstraints { maker in
                maker.right.equalTo(privacySwitch.snp.left).offset(-10)
                maker.centerY.equalTo(privacySwitch)
            }

            urlField.snp.makeConstraints { maker in
                maker.top.equalTo(privacyLabel.snp.bottom).offset(5)
                maker.left.size.equalTo(langSengment)
            }
            serTokenField.snp.makeConstraints { maker in
                maker.top.equalTo(privacyLabel.snp.bottom).offset(5)
                maker.left.equalTo(deleteFileBtn)
                maker.size.equalTo(langSengment)
            }
            devTokenField.snp.makeConstraints { maker in
                maker.top.equalTo(urlField.snp.bottom).offset(5)
                maker.left.size.equalTo(urlField)
            }
            getWebsocketUrlBtn.snp.makeConstraints { maker in
                maker.top.equalTo(devTokenField)
                maker.left.equalTo(devTokenField.snp.right).offset(10)
                maker.size.equalTo(scanButton)
            }
            getWebsocketSerTokenBtn.snp.makeConstraints { maker in
                maker.left.equalTo(getWebsocketUrlBtn.snp.right).offset(10)
                maker.top.size.equalTo(getWebsocketUrlBtn)
            }
            getWebsocketDevTokenBtn.snp.makeConstraints { maker in
                maker.top.equalTo(devTokenField.snp.bottom).offset(5)
                maker.left.size.equalTo(scanButton)
            }
            setWebsocketUrlBtn.snp.makeConstraints { maker in
                maker.left.equalTo(getWebsocketDevTokenBtn.snp.right).offset(10)
                maker.top.size.equalTo(getWebsocketDevTokenBtn)
            }
            setWebsocketSerTokenBtn.snp.makeConstraints { maker in
                maker.left.equalTo(setWebsocketUrlBtn.snp.right).offset(10)
                maker.top.size.equalTo(getWebsocketDevTokenBtn)
            }
            setWebsocketDevTokenBtn.snp.makeConstraints { maker in
                maker.left.equalTo(setWebsocketSerTokenBtn.snp.right).offset(10)
                maker.top.size.equalTo(getWebsocketDevTokenBtn)
            }

            testWebsocketBtn.snp.makeConstraints { maker in
                maker.top.equalTo(getWebsocketDevTokenBtn.snp.bottom).offset(5)
                maker.left.size.equalTo(getWebsocketDevTokenBtn)
            }
            testBleRate80Btn.snp.makeConstraints { maker in
                maker.left.equalTo(testWebsocketBtn.snp.right).offset(10)
                maker.top.size.equalTo(testWebsocketBtn)
            }
            testBleRate160Btn.snp.makeConstraints { maker in
                maker.left.equalTo(testBleRate80Btn.snp.right).offset(10)
                maker.top.size.equalTo(testWebsocketBtn)
            }
            stopBleRateBtn.snp.makeConstraints { maker in
                maker.left.equalTo(testBleRate160Btn.snp.right).offset(10)
                maker.top.size.equalTo(testBleRate160Btn)
            }

            packSizeField.snp.makeConstraints { maker in
                maker.top.equalTo(scanButton.snp.bottom).offset(5)
                maker.left.size.equalTo(scanButton)
            }

            testWiFiRateBtn.snp.makeConstraints { maker in
                maker.left.equalTo(packSizeField.snp.right).offset(10)
                maker.top.equalTo(packSizeField)
                maker.size.equalTo(testBleRate160Btn)
            }

            stopWiFiRateBtn.snp.makeConstraints { maker in
                maker.left.equalTo(testWiFiRateBtn.snp.right).offset(10)
                maker.top.size.equalTo(testWiFiRateBtn)
            }

            wifiGetRecordListBtn.snp.makeConstraints { maker in
                maker.top.equalTo(packSizeField.snp.bottom).offset(5)
                maker.left.size.equalTo(scanButton)
            }

            wifiSyncFileBtn.snp.makeConstraints { maker in
                maker.left.equalTo(wifiGetRecordListBtn.snp.right).offset(10)
                maker.top.equalTo(wifiGetRecordListBtn)
                maker.size.equalTo(scanButton)
                //                maker.bottom.equalToSuperview().inset(100)
            }

            wifiCloseBtn.snp.makeConstraints { maker in
                maker.left.equalTo(wifiSyncFileBtn.snp.right).offset(10)
                maker.top.equalTo(wifiGetRecordListBtn)
                maker.size.equalTo(scanButton)
            }

            vadSensitivitySegment.snp.makeConstraints { make in
                make.top.equalTo(testWebsocketBtn.snp_bottom).offset(5)
                make.left.equalTo(testWebsocketBtn)
                make.size.equalTo(CGSize(width: 150, height: 40))
            }

            readVadSensitivityBtn.snp.makeConstraints { make in
                make.top.equalTo(vadSensitivitySegment)
                make.left.equalTo(vadSensitivitySegment.snp_right).offset(10)
                make.size.equalTo(CGSize(width: 110, height: 36))
            }

            setVadSensitivityBtn.snp.makeConstraints { make in
                make.top.equalTo(vadSensitivitySegment)
                make.left.equalTo(readVadSensitivityBtn.snp_right).offset(10)
                make.size.equalTo(CGSize(width: 110, height: 36))
            }

            vpuSensitivitySegment.snp.makeConstraints { make in
                make.top.equalTo(vadSensitivitySegment.snp_bottom).offset(5)
                make.left.equalTo(vadSensitivitySegment)
                make.size.equalTo(CGSize(width: 150, height: 40))
            }

            readVpuSensitivityBtn.snp.makeConstraints { make in
                make.top.equalTo(vpuSensitivitySegment)
                make.left.equalTo(vpuSensitivitySegment.snp_right).offset(10)
                make.size.equalTo(CGSize(width: 110, height: 36))
            }

            setVpuSensitivityBtn.snp.makeConstraints { make in
                make.top.equalTo(vpuSensitivitySegment)
                make.left.equalTo(readVpuSensitivityBtn.snp_right).offset(10)
                make.size.equalTo(CGSize(width: 110, height: 36))
            }

            micGainSegment.snp.makeConstraints { make in
                make.top.equalTo(vpuSensitivitySegment.snp_bottom).offset(5)
                make.left.equalTo(vpuSensitivitySegment)
                make.size.equalTo(CGSize(width: 190, height: 40))
                make.bottom.equalToSuperview().inset(100)
            }

            readMicGainBtn.snp.makeConstraints { make in
                make.top.equalTo(micGainSegment)
                make.left.equalTo(micGainSegment.snp_right).offset(10)
                make.size.equalTo(scanButton)
            }

            setMicGainBtn.snp.makeConstraints { make in
                make.top.equalTo(micGainSegment)
                make.left.equalTo(readMicGainBtn.snp_right).offset(10)
                make.size.equalTo(scanButton)
            }
        }

        scrollView.addSubview(scrollContainer)
        scrollContainer.snp.makeConstraints { maker in
            maker.top.left.right.bottom.equalToSuperview()
            maker.width.equalToSuperview()
        }

        leftField.delegate = self
        rightField.delegate = self
        ssidField.delegate = self
        pwdField.delegate = self
        urlField.delegate = self
        serTokenField.delegate = self
        devTokenField.delegate = self
        packSizeField.delegate = self
        ledStatusSwitch.addTarget(self, action: #selector(onLedValueChange(uiSwitch:)), for: .valueChanged)
        privacySwitch.addTarget(self, action: #selector(onPrivacyValueChange(uiSwitch:)), for: .valueChanged)

        scanButton.addTarget(self, action: #selector(go2Scan(button:)), for: .touchUpInside)
        depairButton.addTarget(self, action: #selector(depair(button:)), for: .touchUpInside)
        getStateButton.addTarget(self, action: #selector(getState(button:)), for: .touchUpInside)
        getStorageButton.addTarget(self, action: #selector(getStorage(button:)), for: .touchUpInside)

        resetPwdButton.addTarget(self, action: #selector(resetPassword(button:)), for: .touchUpInside)
        getPowerButton.addTarget(self, action: #selector(readPower(button:)), for: .touchUpInside)
        getRecordListBtn.addTarget(self, action: #selector(getFileList(button:)), for: .touchUpInside)

        readBacklightDurationBtn.addTarget(self, action: #selector(readBacklightDuration(button:)), for: .touchUpInside)
        setBacklightDurationBtn.addTarget(self, action: #selector(setBacklightDuration(button:)), for: .touchUpInside)
        readBacklightBrightBtn.addTarget(self, action: #selector(readBacklightBright(button:)), for: .touchUpInside)
        setBacklightBrightBtn.addTarget(self, action: #selector(setBacklightBright(button:)), for: .touchUpInside)
        readLangBtn.addTarget(self, action: #selector(readLanguage(button:)), for: .touchUpInside)
        setLangBtn.addTarget(self, action: #selector(setLanguage(button:)), for: .touchUpInside)

        readDegreeBtn.addTarget(self, action: #selector(readDegree(button:)), for: .touchUpInside)
        setDegreeBtn.addTarget(self, action: #selector(setDegree(button:)), for: .touchUpInside)

        openWiFiBtn.addTarget(self, action: #selector(openWiFi(button:)), for: .touchUpInside)
        closeWiFiBtn.addTarget(self, action: #selector(closeWiFi(button:)), for: .touchUpInside)
        getWiFiBtn.addTarget(self, action: #selector(getWiFiSsid(button:)), for: .touchUpInside)
        setWiFiBtn.addTarget(self, action: #selector(setWiFiSsid(button:)), for: .touchUpInside)

        startRecordBtn.addTarget(self, action: #selector(startRecord(button:)), for: .touchUpInside)
        pauseRecordBtn.addTarget(self, action: #selector(pauseRecord(button:)), for: .touchUpInside)
        resumeRecordBtn.addTarget(self, action: #selector(resumeRecord(button:)), for: .touchUpInside)
        stopRecordBtn.addTarget(self, action: #selector(stopRecord(button:)), for: .touchUpInside)

        syncFileBtn.addTarget(self, action: #selector(syncFile(button:)), for: .touchUpInside)
        syncFileStopBtn.addTarget(self, action: #selector(syncFileStop(button:)), for: .touchUpInside)
        deleteFileBtn.addTarget(self, action: #selector(deleteFile(button:)), for: .touchUpInside)
        clearFilesBtn.addTarget(self, action: #selector(clearFiles(button:)), for: .touchUpInside)

        getWebsocketUrlBtn.addTarget(self, action: #selector(onGetWebsocketUrl(button:)), for: .touchUpInside)
        getWebsocketSerTokenBtn.addTarget(self, action: #selector(onGetWebsocketSerToken(button:)), for: .touchUpInside)
        getWebsocketDevTokenBtn.addTarget(self, action: #selector(onGetWebsocketDevToken(button:)), for: .touchUpInside)
        setWebsocketUrlBtn.addTarget(self, action: #selector(onSetWebsocketUrl(button:)), for: .touchUpInside)
        setWebsocketSerTokenBtn.addTarget(self, action: #selector(onSetWebsocketSerToken(button:)), for: .touchUpInside)
        setWebsocketDevTokenBtn.addTarget(self, action: #selector(onSetWebsocketDevToken(button:)), for: .touchUpInside)
        testWebsocketBtn.addTarget(self, action: #selector(onTestWebsocket(button:)), for: .touchUpInside)
        testBleRate80Btn.addTarget(self, action: #selector(onBleRateTest80(button:)), for: .touchUpInside)
        testBleRate160Btn.addTarget(self, action: #selector(onBleRateTest160(button:)), for: .touchUpInside)
        stopBleRateBtn.addTarget(self, action: #selector(onStopBleRateTest(button:)), for: .touchUpInside)

        testWiFiRateBtn.addTarget(self, action: #selector(onWiFiRateTest(button:)), for: .touchUpInside)
        stopWiFiRateBtn.addTarget(self, action: #selector(onStopWiFiRate(button:)), for: .touchUpInside)
        wifiGetRecordListBtn.addTarget(self, action: #selector(onWiFiGetRecordList(button:)), for: .touchUpInside)
        wifiSyncFileBtn.addTarget(self, action: #selector(onWiFiSyncFile(button:)), for: .touchUpInside)
        wifiCloseBtn.addTarget(self, action: #selector(onWiFiClose(button:)), for: .touchUpInside)

        setVadSensitivityBtn.addTarget(self, action: #selector(setVadSensitivity(button:)), for: .touchUpInside)
        readVadSensitivityBtn.addTarget(self, action: #selector(getVadSensitivity(button:)), for: .touchUpInside)

        setVpuSensitivityBtn.addTarget(self, action: #selector(setVpuSensitivity(button:)), for: .touchUpInside)
        readVpuSensitivityBtn.addTarget(self, action: #selector(getVpuSensitivity(button:)), for: .touchUpInside)

        setMicGainBtn.addTarget(self, action: #selector(setMicGain(button:)), for: .touchUpInside)
        readMicGainBtn.addTarget(self, action: #selector(getMicGain(button:)), for: .touchUpInside)

        bleAgent.glassDelegate = self
        test()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = NSLocalizedString("main.title", comment: "")
        guard bleAgent.isPoweredOn else {
            logTextView.text = NSLocalizedString("ble.status.powered_off", comment: "") + "\n\(logTextView.text!)"
            showOrHideSomeButtons(true)
            return
        }
        logTextView.text = NSLocalizedString("ble.status.powered_on", comment: "") + "\n\(logTextView.text!)"
        if bleAgent.isDeviceConnect() {
            logTextView.text = NSLocalizedString("ble.status.connected", comment: "") + ":\(bleAgent.bleDevice!.serialNumber)\n\(logTextView.text!)"
            bleAgent.getState()
            bleAgent.getLedState()
        } else {
            logTextView.text = NSLocalizedString("ble.status.disconnected", comment: "") + "\n\(logTextView.text!)"
        }
        showOrHideSomeButtons(!bleAgent.isDeviceConnect())
    }

    private func test() {
        //        let width = UIScreen.main.bounds.width
        //        let height = UIScreen.main.bounds.height
        //        let scale = UIScreen.main.scale
        //        debugPrint("width:\(width), height:\(height), scale:\(scale)")
    }

    private func showOrHideWiFiButtons(_ hidden: Bool) {
        packSizeField.isHidden = hidden
        testWiFiRateBtn.isHidden = hidden
        stopWiFiRateBtn.isHidden = hidden
        wifiGetRecordListBtn.isHidden = hidden
        wifiSyncFileBtn.isHidden = hidden
        wifiCloseBtn.isHidden = hidden
    }

    private func showOrHideSomeButtons(_ hidden: Bool) {
        depairButton.isHidden = hidden
        getStateButton.isHidden = hidden
        getStorageButton.isHidden = hidden
        resetPwdButton.isHidden = hidden
        getPowerButton.isHidden = hidden
        getRecordListBtn.isHidden = hidden

        brightDurationSegment.isHidden = hidden
        readBacklightDurationBtn.isHidden = hidden
        setBacklightDurationBtn.isHidden = hidden
        lightBrightSegment.isHidden = hidden
        readBacklightBrightBtn.isHidden = hidden
        setBacklightBrightBtn.isHidden = hidden
        langSengment.isHidden = hidden
        readLangBtn.isHidden = hidden
        setLangBtn.isHidden = hidden

        leftField.isHidden = hidden
        rightField.isHidden = hidden
        readDegreeBtn.isHidden = hidden
        setDegreeBtn.isHidden = hidden

        ssidField.isHidden = hidden
        pwdField.isHidden = hidden
        openWiFiBtn.isHidden = hidden
        closeWiFiBtn.isHidden = hidden
        getWiFiBtn.isHidden = hidden
        setWiFiBtn.isHidden = hidden

        startRecordBtn.isHidden = hidden
        pauseRecordBtn.isHidden = hidden
        resumeRecordBtn.isHidden = hidden
        stopRecordBtn.isHidden = hidden

        syncFileBtn.isHidden = hidden
        syncFileStopBtn.isHidden = hidden
        deleteFileBtn.isHidden = hidden
        clearFilesBtn.isHidden = hidden

        ledStatusLabel.isHidden = hidden
        ledStatusSwitch.isHidden = hidden
        privacyLabel.isHidden = hidden
        privacySwitch.isHidden = hidden

        urlField.isHidden = hidden
        serTokenField.isHidden = hidden
        devTokenField.isHidden = hidden
        getWebsocketUrlBtn.isHidden = hidden
        getWebsocketSerTokenBtn.isHidden = hidden
        getWebsocketDevTokenBtn.isHidden = hidden
        setWebsocketUrlBtn.isHidden = hidden
        setWebsocketSerTokenBtn.isHidden = hidden
        setWebsocketDevTokenBtn.isHidden = hidden
        testWebsocketBtn.isHidden = hidden
        testBleRate80Btn.isHidden = hidden
        testBleRate160Btn.isHidden = hidden
        stopBleRateBtn.isHidden = hidden
        if hidden {
            showOrHideWiFiButtons(hidden)
            scrollView.scrollsToTop = true
        }
    }

    // MARK: - Method Implementation

    @objc private func onWiFiClose(button _: UIButton) {
//        wifiAgent.disconnect()
    }

    @objc private func onWiFiSyncFile(button _: UIButton) {
        syncIndex = 0
        guard let bleFile = recordList.first else {
            logTextView.text = "File list is empty\n\(logTextView.text!)"
            return
        }
        let text = "Start syncing the 1st recording, sessionId:\(recordList[syncIndex].sessionId), size:\(recordList[syncIndex].size)"
        debugPrint(text)
        logTextView.text = "\(text)\n\(logTextView.text!)"
//        wifiAgent.appSyncFile(bleFile.sessionId, 0, 0, bleFile.scenes)
    }

    @objc private func onWiFiGetRecordList(button _: UIButton) {
//        wifiAgent.appGetFileList(Date().stampSec, 0)
    }

    @objc private func onStopWiFiRate(button _: UIButton) {
//        wifiAgent.appWiFiRate(false, 0)
    }

    @objc private func onWiFiRateTest(button _: UIButton) {
        guard let packSize = packSizeField.text, packSize.count > 0 else {
            logTextView.text = "Please enter test packet size\n\(logTextView.text!)"
            return
        }
//        wifiAgent.appWiFiRate(true, Int(packSize)!)
    }

    @objc private func onStopBleRateTest(button _: UIButton) {
        bleAgent.stopBleRateTest()
    }

    @objc private func onBleRateTest160(button _: UIButton) {
        bleAgent.startBleRateTest(160)
    }

    @objc private func onBleRateTest80(button _: UIButton) {
        bleAgent.startBleRateTest(80)
    }

    @objc private func onTestWebsocket(button _: UIButton) {
        bleAgent.testWebsocket()
    }

    @objc private func onSetWebsocketUrl(button _: UIButton) {
        guard let url = urlField.text, url.count > 0, url.count <= 63 else {
            logTextView.text = "url.count err, must be (0, 63]\n\(logTextView.text!)"
            return
        }
        bleAgent.setWebsocketProfile(type: .url, content: url)
    }

    @objc private func onSetWebsocketSerToken(button _: UIButton) {
        guard let serToken = serTokenField.text, serToken.count > 0, serToken.count <= 16 else {
            logTextView.text = "serToken.count err, must be (0, 16]\n\(logTextView.text!)"
            return
        }
        bleAgent.setWebsocketProfile(type: .serToken, content: serToken)
    }

    @objc private func onSetWebsocketDevToken(button _: UIButton) {
        guard let devToken = devTokenField.text, devToken.count > 0, devToken.count <= 16 else {
            logTextView.text = "devToken.count err, must be (0, 16]\n\(logTextView.text!)"
            return
        }
        bleAgent.setWebsocketProfile(type: .devToken, content: devToken)
    }

    @objc private func onGetWebsocketUrl(button _: UIButton) {
        bleAgent.getWebsocketProfile(type: .url)
    }

    @objc private func onGetWebsocketSerToken(button _: UIButton) {
        bleAgent.getWebsocketProfile(type: .serToken)
    }

    @objc private func onGetWebsocketDevToken(button _: UIButton) {
        bleAgent.getWebsocketProfile(type: .devToken)
    }

    @objc private func onPrivacyValueChange(uiSwitch: UISwitch) {
        debugPrint("onPrivacyValueChange:\(uiSwitch.isOn)")
        bleAgent.setPrivacy(onOff: uiSwitch.isOn ? 1 : 0)
    }

    @objc private func onLedValueChange(uiSwitch: UISwitch) {
        debugPrint("onLedValueChange:\(uiSwitch.isOn)")
        bleAgent.setLedState(onOff: uiSwitch.isOn ? 1 : 0)
    }

    @objc private func clearFiles(button _: UIButton) {
        guard !bleAgent.isRecording else {
            return
        }
        bleAgent.clearAllFile()
    }

    @objc private func deleteFile(button _: UIButton) {
        guard !bleAgent.isRecording else {
            return
        }
        showRecordSelectDialog { [weak self] bleFile in
            guard let `self` = self, let bleFile = bleFile else {
                return
            }
            self.bleAgent.deleteFile(sessionId: bleFile.sessionId)
        }
    }

    @objc private func syncFileStop(button _: UIButton) {
        bleAgent.stopSyncFile()
    }

    @objc private func syncFile(button _: UIButton) {
        guard !bleAgent.isRecording else {
            logTextView.text = "Only current recording file sync is supported during recording...\n\(logTextView.text!)"
            return
        }
        guard recordList.count > 0 else {
            logTextView.text = "Please get session list first...\n\(logTextView.text!)"
            return
        }
        showRecordSelectDialog { [weak self] bleFile in
            guard let `self` = self, let bleFile = bleFile else {
                return
            }
                         self.bleAgent.syncFile(sessionId: bleFile.sessionId, start: 0, end: 0, decode: true) // No need to decode for offline file sync
        }
    }

    private func showRecordSelectDialog(callback: @escaping (BleFile?) -> Void) {
        let optionController = UIAlertController(title: "Select Recording File", message: nil, preferredStyle: .actionSheet)
        for bleFile in recordList {
            let title = "{sessionId=\(bleFile.sessionId), size=\(bleFile.size), scenes:\(bleFile.scenes)}"
            let action = UIAlertAction(title: title, style: .default) { _ in
                callback(bleFile)
            }
            optionController.addAction(action)
        }
                 let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            callback(nil)
        }
        optionController.addAction(cancelAction)

        present(optionController, animated: true, completion: nil)
    }

    @objc private func getFileList(button _: UIButton) {
        // uid should be different each time, use timestamp (accurate to seconds)
        // sessionId uses the sessionId of the last synced file, 0 means pull all
        if bleAgent.bleDevice!.uDisk == 1 {
            logTextView.text = "Cannot operate files in USB disk mode\n\(logTextView.text!)"
            return
        }
        bleAgent.getFileList(uid: 10086, sessionId: 0)
    }

    @objc private func stopRecord(button _: UIButton) {
        guard bleAgent.isRecording && bleAgent.sessionId > 0 else {
            return
        }
        bleAgent.stopRecord()
    }

    @objc private func resumeRecord(button _: UIButton) {
        guard bleAgent.isRecording && bleAgent.sessionId > 0 else {
            return
        }
        bleAgent.resumeRecord(bleAgent.sessionId)
    }

    @objc private func pauseRecord(button _: UIButton) {
        guard bleAgent.isRecording else {
            return
        }
        bleAgent.pauseRecord(bleAgent.sessionId)
    }

    @objc private func startRecord(button _: UIButton) {
        bleAgent.startRecord()
    }

    @objc private func setWiFiSsid(button _: UIButton) {
        // Be especially careful if there are Chinese characters
        guard let ssid = ssidField.text, ssid.count > 0, ssid.count <= 33 else {
            logTextView.text = "ssid.count err, must be (0, 33]\n\(logTextView.text!)"
            return
        }
        guard let pwd = pwdField.text, pwd.count > 0, pwd.count <= 33 else {
            logTextView.text = "pwd.count err, must be (0, 33]\n\(logTextView.text!)"
            return
        }
        bleAgent.setWiFiSsid(ssid: ssid, password: pwd, isTest: true)
    }

    @objc private func getWiFiSsid(button _: UIButton) {
        bleAgent.getWiFiSsid()
    }

    @objc private func closeWiFi(button _: UIButton) {
        bleAgent.operateWiFi(open: false)
    }

    @objc private func openWiFi(button _: UIButton) {
        bleAgent.operateWiFi(open: true)
    }

    @objc private func setDegree(button _: UIButton) {
        //        bleAgent.setGlassDegree(left: -100, right: -10)
    }

    @objc private func readDegree(button _: UIButton) {
        //        bleAgent.readGlassDegree()
    }

    @objc private func setLanguage(button _: UIButton) {
        switch langSengment.selectedSegmentIndex {
        case 0: bleAgent.setLanguage(type: .SimpleChinese)
        case 1: bleAgent.setLanguage(type: .TradChinese)
        case 2: bleAgent.setLanguage(type: .English)
        default:
            break
        }
    }

    @objc private func readLanguage(button _: UIButton) {
        bleAgent.readLanguage()
    }

    @objc private func setBacklightBright(button _: UIButton) {
        switch lightBrightSegment.selectedSegmentIndex {
        case 0: bleAgent.setBacklight(bright: .Bright1)
        case 1: bleAgent.setBacklight(bright: .Bright2)
        case 2: bleAgent.setBacklight(bright: .Bright3)
        case 3: bleAgent.setBacklight(bright: .Bright4)
        case 4: bleAgent.setBacklight(bright: .Bright5)
        case 5: bleAgent.setBacklight(bright: .Bright6)
        default:
            break
        }
    }

    @objc private func readBacklightBright(button _: UIButton) {
        bleAgent.readBacklightBright()
    }

    @objc private func setBacklightDuration(button _: UIButton) {
        switch brightDurationSegment.selectedSegmentIndex {
        case 0:
            bleAgent.setBacklight(duration: .Sec10)
        case 1:
            bleAgent.setBacklight(duration: .Sec20)
        case 2:
            bleAgent.setBacklight(duration: .Sec30)
        case 3:
            bleAgent.setBacklight(duration: .SecAlways)
        default:
            break
        }
    }

    @objc private func readBacklightDuration(button _: UIButton) {
        bleAgent.readBacklightDuration()
    }

    @objc private func readPower(button _: UIButton) {
        bleAgent.readPower()
    }

    @objc private func resetPassword(button _: UIButton) {
        bleAgent.appResetPassword()
    }

    @objc private func getStorage(button _: UIButton) {
        bleAgent.getStorage()
    }

    @objc private func getState(button _: UIButton) {
        bleAgent.getState()
    }

    @objc private func depair(button _: UIButton) {
        bleAgent.depair(clear: false)
    }

    @objc private func go2Scan(button _: UIButton) {
        // let obj = PFoundationDemo()

        PrintManager.printMenthod()

        var agent = TestAgent.shared
        var ret = agent.testFunc()

        // var deviceAgent = PlaudDeviceAgent.shared
        // deviceAgent.startScan()
        // return;

        // self.navigationController?.pushViewController(DemoTestViewController(), animated: true)
        // return

        guard bleAgent.isPoweredOn, !bleAgent.isDeviceConnect() else {
            if !bleAgent.isPoweredOn {
                logTextView.text = "Re-initialize Bluetooth\n\(logTextView.text!)"
                bleAgent.initBluetooth()
            }
            return
        }
        navigationController?.pushViewController(ScanViewController(), animated: true)
    }

    @objc private func setVadSensitivity(button _: UIButton) {
        bleAgent.setVadSensitivity(sensitivity: vadSensitivitySegment.selectedSegmentIndex + 1)
    }

    @objc private func getVadSensitivity(button _: UIButton) {
        bleAgent.readVadSensitivity()
    }

    @objc private func setVpuSensitivity(button _: UIButton) {
        bleAgent.setVpuGain(gain: vadSensitivitySegment.selectedSegmentIndex + 1)
    }

    @objc private func getVpuSensitivity(button _: UIButton) {
        bleAgent.readVpuGain()
    }

    @objc private func setMicGain(button _: UIButton) {
        bleAgent.setMicGain(value: (micGainSegment.selectedSegmentIndex + 1) * 5)
    }

    @objc private func getMicGain(button _: UIButton) {
        bleAgent.readMicGain()
    }

         // MARK: - Callback Handling

    override func onWifiRate(_ instantRate: Int, _ averageRate: Int, _: Double) {
        bleRateLabel.text = "WiFi Speed Test: {Average=\(averageRate), Instant=\(instantRate)}"
    }

    override func onWifiRateFail(_ status: Int) {
        bleRateLabel.text = "WiFi Speed Test Failed: {status=\(status)}"
    }

    override func onWifiClose(_: Int) {
        bleAgent.setWiFiState(false)
        showOrHideWiFiButtons(true)
    }

    override func onWifiClientFail() {
        bleAgent.setWiFiState(false)
        showOrHideWiFiButtons(true)
    }

    override func onWifiFileDelete(_: Int, _: Int) {}

    override func onWifiDataComplete() {
        debugPrint("onWifiDataComplete")
        syncIndex += 1
        guard recordList.count > syncIndex else {
            return
        }
        let text = "Start syncing the \(syncIndex + 1)th recording, sessionId:\(recordList[syncIndex].sessionId), size:\(recordList[syncIndex].size)"
        debugPrint(text)
        logTextView.text = "\(text)\n\(logTextView.text!)"
//        wifiAgent.appSyncFile(recordList[syncIndex].sessionId, 0, 0, recordList[syncIndex].scenes)
    }

    override func onWifiSyncFileStop(_ status: Int) {
        debugPrint("onWifiSyncFileStop status:\(status)")
    }

    override func onWifiSyncFileData(_ sessionId: Int, _ offset: Int, _ count: Int, _: Data) {
        debugPrint("onWifiSyncFileData sessionId:\(sessionId), offset:\(offset), count:\(count)")
        //        if syncIndex < recordList.count, offset + count == recordList[syncIndex].size {
        //            onWifiDataComplete()
        //        }
    }

    override func onWifiSyncFile(_ sessionId: Int, _ status: Int) {
        debugPrint("onWifiSyncFile sessionId:\(sessionId), status:\(status)")
    }

    override func onWifiFileList(_ files: [BleFile]) {
        logTextView.text = "File count: \(files.count)\n\(logTextView.text!)"
        recordList.removeAll()
        recordList.append(contentsOf: files)
    }

    override func onWifiFileListFail(_: Int) {}

    override func onWifiPower(_: Int, _: Int) {}

    override func onWifiHandshake(_ status: Int) {
        logTextView.text = "WiFi handshake: {status=\(status)}\n\(logTextView.text!)"
        bleAgent.setWiFiState(status == 0)
        showOrHideWiFiButtons(status != 0)
    }

    override func onWifiCommonErr(_ cmd: Int, _ status: Int) {
        logTextView.text = "WiFi general exception: {cmd=\(cmd), status=\(status)}\n\(logTextView.text!)"
        BleAgent.shared.setWiFiState(false)
        showOrHideWiFiButtons(true)
    }

    override func onRate(lossRate _: Double, rate: Int, instantRate: Int) {
        bleRateLabel.text = "Bluetooth speed test: {Average=\(rate), Instant=\(instantRate)}"
    }

    override func onWebsocketProfile(_ type: Int, _ content: String?) {
        logTextView.text = "Server configuration: {type=\(type), content=\(String(describing: content))}\n\(logTextView.text!)"
    }

    override func onWebsocketTest(_ status: Int) {
        switch status {
        case 0:
            logTextView.text = "Server test: Success\n\(logTextView.text!)"
        case 1:
            logTextView.text = "Server test: AP not scanned\n\(logTextView.text!)"
        case 2:
            logTextView.text = "Server test: AP password error\n\(logTextView.text!)"
        case 3:
            logTextView.text = "Server test: Websocket connection failed\n\(logTextView.text!)"
        default:
            break
        }
    }

    override func onPrivacy(privacy: Int) {
        logTextView.text = "Privacy: {privacy=\(privacy)}\n\(logTextView.text!)"
        privacySwitch.isOn = privacy == 1
    }

    override func onLedState(onOff: Int) {
        logTextView.text = "LED status: {onOff=\(onOff)}\n\(logTextView.text!)"
        ledStatusSwitch.isOn = onOff == 1
    }

    override func onClearAllFile(status: Int) {
        logTextView.text = "Clear all recordings: {status=\(status)}\n\(logTextView.text!)"
        if status == 0 {
            recordList.removeAll()
        }
    }

    override func onDeleteFile(sessionId: Int, status: Int) {
        logTextView.text = "Delete recording: {sessionId=\(sessionId), status=\(status)}\n\(logTextView.text!)"
        if status == 0 {
            recordList.removeAll { bleFile in
                bleFile.sessionId == sessionId
            }
        }
    }

    override func onDataComplete() {
        logTextView.text = "Data reception completed...\n\(logTextView.text!)"
    }

    override func onSyncFileStop() {
        logTextView.text = "File sync completed...\n\(logTextView.text!)"
    }

    override func onSyncFileTail(sessionId: Int, crc: Int) {
        logTextView.text = "Sync file tail: {sessionId=\(sessionId), crc=\(crc)}\n\(logTextView.text!)"
    }

    override func onSyncFileHead(sessionId: Int, status: Int) {
        logTextView.text = "Sync file header: {sessionId=\(sessionId), status=\(status)}\n\(logTextView.text!)"
    }

    override func onFileList(bleFiles: [BleFile]) {
        logTextView.text = "File list: {bleFiles.count=\(bleFiles.count)}\n\(logTextView.text!)"
        recordList.removeAll()
        recordList.append(contentsOf: bleFiles)
    }

    override func onRecordStop(sessionId: Int, reason: Int, fileExist: Bool, fileSize: Int) {
        logTextView.text = "Recording ended: {sessionId=\(sessionId), reason=\(reason), fileExist=\(fileExist), fileSize=\(fileSize)}\n\(logTextView.text!)"
        bleAgent.stopSyncFile()
    }

    override func onRecordResume() {
        logTextView.text = "Recording resumed...\n\(logTextView.text!)"
        // The start value here needs to be recorded by yourself
        bleAgent.syncFile(sessionId: bleAgent.sessionId, start: fileOffset, end: 0, decode: true)
    }

    override func onRecordPause() {
        logTextView.text = "Recording paused...\n\(logTextView.text!)"
    }

    override func onPcmData(sessionId: Int, millsec: Int, pcmData: Data) {
        debugPrint("onPcmData:{sessionId=\(sessionId), millsec=\(millsec), pcmdata.count=\(pcmData.count)}")
    }

    override func onData(sessionId _: Int, start: Int, data: Data) {
        //        debugPrint("onData:{sessionId=\(sessionId), start=\(start), data.count=\(data.count)}")
        //        debugPrint("data:\(data.hexDescription)")
        fileOffset = start + data.count
    }

    override func onDecodeFail(start: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.decode_failed", comment: ""), start) + "\n\(logTextView.text!)"
    }

    override func onRecordStart(sessionId: Int, start: Int, status: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.record_started", comment: ""), sessionId, start, status) + "\n\(logTextView.text!)"
        if status == 0 {
            bleAgent.syncFile(sessionId: sessionId, start: start, end: 0, decode: true)
        }
    }

    override func onSetWiFiSsid(status: Int) {
        logTextView.text = String(format: NSLocalizedString("wifi.status.config", comment: ""), status) + "\n\(logTextView.text!)"
    }

    override func onGetWiFiSsid(status: Int, ssid: String?) {
        logTextView.text = String(format: NSLocalizedString("wifi.status.get_config", comment: ""), status, ssid ?? "") + "\n\(logTextView.text!)"
        guard let ssid = ssid else {
            ssidField.text = ""
            return
        }
        ssidField.text = ssid
    }

    override func onWiFiOpen(_ status: Int, _ wifiName: String, _ wholeName: String, _ wifiPass: String) {
        logTextView.text = String(format: NSLocalizedString("wifi.status.open", comment: ""), status, wifiName, wholeName, wifiPass) + "\n\(logTextView.text!)"
        // The returned WiFi name and password are generated according to general rules, specific projects may vary
        if status == 0 {
//            wifiAgent.bleDevice = bleAgent.bleDevice
            //            let jtName = "\(wifiName)-\(bleAgent.bleDevice!.serialNumber.dropLast(3).suffix(4))"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                WiFiAgent.shared.connectWifi(wifiName, wifiPass, 60)
            }
        }
    }

    override func onWiFiClose(_ status: Int) {
        logTextView.text = String(format: NSLocalizedString("wifi.status.close", comment: ""), status) + "\n\(logTextView.text!)"
        showOrHideWiFiButtons(true)
        bleAgent.setWiFiState(false)
    }

    override func onLanguage(_ type: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.language", comment: ""), type) + "\n\(logTextView.text!)"
    }

    override func onBacklightBright(_ bright: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.backlight_brightness", comment: ""), bright) + "\n\(logTextView.text!)"
        lightBrightSegment.selectedSegmentIndex = bright - 1
    }

    override func onBacklightDuration(_ duration: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.backlight_duration", comment: ""), duration) + "\n\(logTextView.text!)"
        brightDurationSegment.selectedSegmentIndex = duration
    }

    override func onChargingState(isCharging: Bool, level: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.power_charging_changed", comment: ""), isCharging ? "true" : "false", level) + "\n\(logTextView.text!)"
    }

    override func onPowerChange(power: Int, oldPower: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.power_changed", comment: ""), power, oldPower) + "\n\(logTextView.text!)"
    }

    override func onPasswordReset(password: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.password_reset", comment: ""), password) + "\n\(logTextView.text!)"
    }

    override func onStorage(total: Int, free: Int, duration: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.storage", comment: ""), total, free, duration) + "\n\(logTextView.text!)"
    }

    override func onPenState(state: Int, privacy: Int, keyState: Int, uDisk: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.state", comment: ""), state, privacy, keyState, uDisk) + "\n\(logTextView.text!)"
        privacySwitch.isOn = privacy == 1
    }

    override func onDepair(_ status: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.unbind_result", comment: ""), status) + "\n\(logTextView.text!)"
        if status == 0 {
            UserDefaults.standard.setValue(nil, forKey: "bindedSN")
            showOrHideSomeButtons(true)
        }
    }

    override func onConnectState(state: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.connection_changed", comment: ""), state) + "\n\(logTextView.text!)"
        showOrHideSomeButtons(!bleAgent.isDeviceConnect())
    }

    override func onState(powered: Bool) {
        guard powered else {
            return
        }
        guard bleAgent.isDeviceConnect() else {
            navigationController?.pushViewController(ScanViewController(), animated: true)
            return
        }
    }

    override func bleVadSensitivity(_ value: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.vad_sensitivity_changed", comment: ""), value) + "\n\(logTextView.text!)"
    }

    override func bleVpuGain(_ value: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.vpu_sensitivity_changed", comment: ""), value) + "\n\(logTextView.text!)"
    }

    override func bleMicGain(_ value: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.mic_sensitivity_changed", comment: ""), value) + "\n\(logTextView.text!)"
    }

    // Add shake detection
    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
        if motion == .motionShake {
            showLanguageSelection()
        }
    }

    private func showLanguageSelection() {
        let languageVC = PLLanguageSelectionViewController()
        languageVC.delegate = self
        languageVC.modalPresentationStyle = .overFullScreen
        present(languageVC, animated: true)
    }
}

extension MainViewController: GlassProtocol {
    func glassDegress(_ left: Int, _ right: Int) {
        logTextView.text = String(format: NSLocalizedString("device.status.glass_degree", comment: ""), left, right) + "\n\(logTextView.text!)"
    }

    func glassUserIdSet(_: Int) {}

    func glassUserIdRead(_: Int) {}

    func glassRemain(_: Int) {}

    func glassThreshold(_: Int) {}

    func glassData(_: Int, _: [GlassData]) {}

    func glassDataClear(_: Int) {}
}

extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Kotlin-like apply for setting parameters

protocol HasApply {}

extension HasApply {
    func apply(_ closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
}

extension UIView: HasApply {}

// Add language selection delegate
extension MainViewController: PLLanguageSelectionDelegate {
    func languageDidChange() {
        // No longer need dynamic refresh because we will restart the app
    }
}
