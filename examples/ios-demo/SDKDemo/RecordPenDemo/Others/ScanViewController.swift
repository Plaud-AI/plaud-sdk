import PenBleSDK
import UIKit

class ScanViewController: BaseViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        return tableView
    }()

    private var bindedSN: String?
    private var deviceArr: [BleDevice] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scan Pen"

        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true

        bindedSN = UserDefaults.standard.string(forKey: "bindedSN")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bleAgent.setFilter(name: nil) // No filter, show all
        bleAgent.startScan()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        bleAgent.stopScan()
    }

    override func onScanResult(bleDevices: [BleDevice]) {
        deviceArr.removeAll()
        deviceArr.append(contentsOf: bleDevices)
        tableView.reloadData()

//        bleDevices.forEach { (device) in
//            if bindedSN != nil && device.serialNumber == bindedSN && device.bindCode == 1 {
//                debugPrint("Directly connect to bound device")
//                bleAgent.connectBleDevice(bleDevice: device)
//            }
//        }
    }

    override func onHandshakeWait(_: Int) {
        debugPrint("Please confirm on the pen")
    }

    override func onBind(sn _: String?, status: Int, protVersion _: Int, timezone _: Int) {
        if status == 0 {
            debugPrint("Binding successful")
            UserDefaults.standard.set(bleAgent.bleDevice!.serialNumber, forKey: "bindedSN")
            navigationController?.popViewController(animated: true)
        } else {
            debugPrint("Binding failed, token mismatch")
        }
    }
}

extension ScanViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return deviceArr.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let device = deviceArr[indexPath.row]
//        var showName = device.wholeName
//        //var sn = device.ssn
//        if device.bindCode == 1 {
//            showName.append("(Bound)")
//        }
        var showName = device.serialNumber
        cell.textLabel?.text = showName
        cell.accessoryType = .disclosureIndicator // Right side arrow
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let device = deviceArr[indexPath.row]
        //        guard device.bindCode == 0 else {
        //            debugPrint("Device already bound, cannot bind to a new device")
        //            return
        //        }
        bleAgent.connectBleDevice(bleDevice: device, nil, "JianXi")
    }
}
