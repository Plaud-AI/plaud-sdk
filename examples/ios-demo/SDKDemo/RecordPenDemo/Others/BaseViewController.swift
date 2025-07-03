import PenBleSDK
import UIKit

// import PenWiFiSdk

class BaseViewController: UIViewController {
    var bleAgent = BleAgent.shared
    // var wifiAgent = WiFiAgent.shared

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bleAgent.delegate = self
        // wifiAgent.delegate = self
    }

    func onUpdatePowerLowErr() {}
    func onDeviceDisconnectErr() {}
    func onUDiskErr(funcName _: String) {}
    func onAppKeyState(result _: Int) {}
    func onState(powered _: Bool) {}
    func onConnectState(state _: Int) {}
    func onScanResult(bleDevices _: [BleDevice]) {}
    func onScanOverTime() {}
    func onHandshakeWait(_: Int) {}
    func onBind(sn _: String?, status _: Int, protVersion _: Int, timezone _: Int) {}
    func onPowerChange(power _: Int, oldPower _: Int) {}
    func onChargingState(isCharging _: Bool, level _: Int) {}
    func onPenState(state _: Int, privacy _: Int, keyState _: Int, uDisk _: Int) {}
    func onPenTime(stamp _: Int, timezone _: Int, zoneMin _: Int) {}
    func onDepair(_: Int) {}
    func onStorage(total _: Int, free _: Int, duration _: Int) {}
    func onPasswordReset(password _: Int) {}
    func onBacklightDuration(_: Int) {}
    func onBacklightBright(_: Int) {}
    func onLanguage(_: Int) {}
    func onAutoClear(_: Bool) {}
    func onWiFiOpen(_: Int, _: String, _: String, _: String) {}
    func onWiFiClose(_: Int) {}
    func onSetWiFiSsid(status _: Int) {}
    func onGetWiFiSsid(status _: Int, ssid _: String?) {}
    func onVoiceAbnormal(status _: Int) {}
    func onWebsocketProfile(_: Int, _: String?) {}
    func onWebsocketTest(_: Int) {}
    func onRecordStart(sessionId _: Int, start _: Int, status _: Int) {}
    func onRecordStop(sessionId _: Int, reason _: Int, fileExist _: Bool, fileSize _: Int) {}
    func onRecordPause() {}
    func onRecordResume() {}
    func onLedState(onOff _: Int) {}
    func onSetLedState(onOff _: Int) {}
    func onFileList(bleFiles _: [BleFile]) {}
    func onSyncFileHead(sessionId _: Int, status _: Int) {}
    func onSyncFileTail(sessionId _: Int, crc _: Int) {}
    func onMarking(sessionId _: Int, status _: Int, markList _: [UInt32]) {}
    func onDataComplete() {}
    func onData(sessionId _: Int, start _: Int, data _: Data) {}
    func onPcmData(sessionId _: Int, millsec _: Int, pcmData _: Data) {}
    func onDecodeFail(start _: Int) {}
    func onSyncFileStop() {}
    func onDeleteFile(sessionId _: Int, status _: Int) {}
    func onFotaResult(uid _: Int, status _: Int, errmsg _: String?) {}
    func onFotaPackReq(uid _: Int, start _: Int, end _: Int) {}
    func onFotaPackFin(uid _: Int, status _: Int, errmsg _: String?) {}
    func onOtaDataSendFail() {}
    func onRate(lossRate _: Double, rate _: Int, instantRate _: Int) {}
    func onPrivacy(privacy _: Int) {}
    func onClearAllFile(status _: Int) {}

    func onWifiCommonErr(_: Int, _: Int) {}
    func onWifiHandshake(_: Int) {}
    func onWifiPower(_: Int, _: Int) {}
    func onWifiFileListFail(_: Int) {}
    func onWifiFileList(_: [BleFile]) {}
    func onWifiSyncFile(_: Int, _: Int) {}
    func onWifiSyncFileData(_: Int, _: Int, _: Int, _: Data) {}
    func onWifiDataComplete() {}
    func onWifiSyncFileStop(_: Int) {}
    func onWifiFileDelete(_: Int, _: Int) {}
    func onWifiClientFail() {}
    func onWifiClose(_: Int) {}
    func onWifiRateFail(_: Int) {}
    func onWifiRate(_: Int, _: Int, _: Double) {}
    func onWifiLogsFail(_: Int) {}
    func onWifiLogs(_: Data?) {}
    func onWifiTips(_: Int) {}
}

/* extension BaseViewController: WiFiAgentProtocol {
     func wifiCommonErr(_ cmd: Int, _ status: Int) {
         debugPrint("wifiCommonErr cmd:\(cmd), status:\(status)")
         self.onWifiCommonErr(cmd, status)
     }

     func wifiHandshake(_ status: Int) {
         debugPrint("wifiHandshake status:\(status)")
         self.onWifiHandshake(status)
     }

     func wifiPower(_ power: Int, _ voltage: Int) {
         debugPrint("wifiPower power:\(power), voltage:\(voltage)")
         self.onWifiPower(power, voltage)
     }

     func wifiFileListFail(_ status: Int) {
         debugPrint("wifiFileListFail status:\(status)")
         self.onWifiFileListFail(status)
     }

     func wifiFileList(_ files: [BleFile]) {
         debugPrint("wifiFileList files.count:\(files.count)")
         self.onWifiFileList(files)
     }

     func wifiSyncFile(_ sessionId: Int, _ status: Int) {
         debugPrint("wifiSyncFile sessionId:\(sessionId), status:\(status)")
         self.onWifiSyncFile(sessionId, status)
     }

     func wifiSyncFileData(_ sessionId: Int, _ offset: Int, _ count: Int, _ binData: Data) {
         debugPrint("wifiSyncFileData sessionId:\(sessionId), offset:\(offset), count:\(count), binData:\(binData)")
         self.onWifiSyncFileData(sessionId, offset, count, binData)
     }

     func wifiDataComplete() {
         debugPrint("wifiDataComplete")
         self.onWifiDataComplete()
     }

     func wifiSyncFileStop(_ status: Int) {
         debugPrint("wifiSyncFileStop status:\(status)")
         self.onWifiSyncFileStop(status)
     }

     func wifiFileDelete(_ sessionId: Int, _ status: Int) {
         debugPrint("wifiFileDelete sessionId:\(sessionId), status:\(status)")
         self.onWifiFileDelete(sessionId, status)
     }

     func wifiClientFail() {
         debugPrint("wifiClientFail")
         self.onWifiClientFail()
     }

     func wifiClose(_ status: Int) {
         debugPrint("wifiClose status:\(status)")
         self.onWiFiClose(status)
     }

     func wifiRateFail(_ status: Int) {
         debugPrint("wifiRateFail status:\(status)")
         self.onWifiRateFail(status)
     }

     func wifiRate(_ instantRate: Int, _ averageRate: Int, _ lossRate: Double) {
         debugPrint("wifiRate instantRate:\(instantRate), averageRate:\(averageRate), lossRate:\(lossRate)")
         self.onWifiRate(instantRate, averageRate, lossRate)
     }

     func wifiLogsFail(_ status: Int) {
         debugPrint("wifiLogsFail status:\(status)")
         self.onWifiLogsFail(status)
     }

     func wifiLogs(_ logData: Data?) {
         debugPrint("wifiLogs logData.count:\(logData?.count ?? 0)")
         self.onWifiLogs(logData)
     }

     func wifiTips(_ tips: Int) {
         debugPrint("wifiTips tips:\(tips)")
         self.onWifiTips(tips)
     }

 }
  */

extension BaseViewController: BleAgentProtocol {
    func bleDeviceName(name _: String?) {}

    func blePenState(state _: Int, privacy _: Int, keyState _: Int, uDisk _: Int, findMyToken _: Int, hasSndpKey _: Int, deviceAccessToken _: Int) {}

    func bleSwitchHandler(_: Int) {}

    func bleAutoPowerOff(_: Int) {}

    func bleRawWaveEnabled(_: Int) {}

    func bleRecordingAfterDisConnetEnabled(_: Int) {}

    func bleSyncWhenIdleEnabled(_: Int) {}

    func bleFindMyState(_: Int) {}

    func bleVPUCLKState(_: Int) {}

    func bleStopRecordingAfterCharging(_: Int) {}

    func bleSetActive(status _: Int) {}

    func onBinaryFileReq(type _: Int, packageOffset _: Int, packageSize _: Int, endStatus _: Int) {}

    func onBinaryFileEnd(result _: Int) {}

    func onSyncIdleWifiConfigReceived(index _: UInt32, ssid _: String, password _: String) {}

    func onSyncIdleWifiConfigSet(result _: Int) {}

    func onSyncIdleWifiListReceived(list _: [UInt32]) {}

    func onSyncIdleWifiDeleteResult(result _: Int) {}

    func onSyncIdleWifiTestStarted(index _: UInt32) {}

    func onSyncIdleWillStart(seconds _: Int) {}

    func onSyncIdleWifiTestResult(index _: UInt32, result _: Int, rawCode _: Int) {}

    func onResetFindmyResult(result _: Int) {}

    func onSetSoundPlusTokenResult(licenseKey _: String) {}

    func onGetSDFlashCIDResult(cid _: String) {}

    func bleVadSensitivity(_: Int) {}

    func bleVpuGain(_: Int) {}

    func bleMicGain(_: Int) {}

    func bleRecScene(_: Int) {}

    func bleRecMode(_: Int) {}

    func bleAngles(pitchAngle _: Float, rollbackAngle _: Float, yawAngle _: Float) {}

    func bleAlarmRec(start _: Int, duration _: Int, repeatMode _: Int) {}

    func bleVad(_: Bool) {}

    func bleRecordPause(sessionId _: Int, reason _: Int, fileExist _: Bool, fileSize _: Int) {}

    func bleRecordResume(sessionId _: Int, start _: Int, status _: Int, scene _: Int, startTime _: Int) {}

    func blePcmData(sessionId _: Int, millsec _: Int, pcmData _: Data, isMusic _: Bool) {}

    func bleUpdatePowerLowErr() {
        debugPrint("bleUpdatePowerLowErr")
    }

    func bleDeviceDisconnectErr() {
        debugPrint("bleDeviceDisconnectErr")
    }

    func bleUDiskErr(funcName _: String) {
        debugPrint("bleUDiskErr")
    }

    func bleAppKeyState(result: Int) {
        debugPrint("bleAppKeyState result:\(result)")
    }

    func bleState(powered: Bool) {
        debugPrint("bleState powered:\(powered)")
        onState(powered: powered)
    }

    func bleConnectState(state: Int) {
        debugPrint("bleConnectState state:\(state)")
        onConnectState(state: state)
    }

    func bleScanResult(bleDevices: [BleDevice]) {
        debugPrint("bleScanResult bleDevices.count:\(bleDevices.count)")
        onScanResult(bleDevices: bleDevices)
    }

    func bleScanOverTime() {
        debugPrint("bleScanOverTime")
    }

    func bleHandshakeWait(timeout: Int) {
        debugPrint("bleHandshakeWait timeout:\(timeout)")
        onHandshakeWait(timeout)
    }

    func bleBind(sn: String?, status: Int, protVersion: Int, timezone: Int) {
        debugPrint("bleBind sn:\(String(describing: sn)), status:\(status), protVersion:\(protVersion), timezone:\(timezone)")
        onBind(sn: sn, status: status, protVersion: protVersion, timezone: timezone)
    }

    func blePowerChange(power: Int, oldPower: Int) {
        debugPrint("blePowerChange power:\(power), oldPower:\(oldPower)")
        onPowerChange(power: power, oldPower: oldPower)
    }

    func bleChargingState(isCharging: Bool, level: Int) {
        debugPrint("bleChargingState isCharging:\(isCharging), level:\(level)")
        onChargingState(isCharging: isCharging, level: level)
    }

    func blePenState(state: Int, privacy: Int, keyState: Int, uDisk: Int) {
        debugPrint("blePenState state:\(state), privacy:\(privacy), keyState:\(keyState), uDisk:\(uDisk)")
        onPenState(state: state, privacy: privacy, keyState: keyState, uDisk: uDisk)
    }

    func blePenTime(stamp: Int, timezone: Int, zoneMin: Int) {
        debugPrint("blePenTime stamp:\(stamp), timezone:\(timezone), zoneMin:\(zoneMin)")
        onPenTime(stamp: stamp, timezone: timezone, zoneMin: zoneMin)
    }

    func bleDepair(_ status: Int) {
        debugPrint("bleDepair status:\(status)")
        onDepair(status)
    }

    func bleStorage(total: Int, free: Int, duration: Int) {
        debugPrint("bleStorage total:\(total), free:\(free), duration:\(duration)")
        onStorage(total: total, free: free, duration: duration)
    }

    func blePasswordReset(password: Int) {
        debugPrint("blePasswordReset password:\(password)")
        onPasswordReset(password: password)
    }

    func bleBacklightDuration(_ duration: Int) {
        debugPrint("bleBacklightDuration duration:\(duration)")
        onBacklightDuration(duration)
    }

    func bleBacklightBright(_ bright: Int) {
        debugPrint("bleBacklightBright bright:\(bright)")
        onBacklightBright(bright)
    }

    func bleLanguage(_ type: Int) {
        debugPrint("bleLanguage type:\(type)")
        onLanguage(type)
    }

    func bleAutoClear(_ open: Bool) {
        debugPrint("bleAutoClear open:\(open)")
        onAutoClear(open)
    }

    func bleWiFiOpen(_ status: Int, _ wifiName: String, _ wholeName: String, _ wifiPass: String) {
        debugPrint("bleWiFiOpen status:\(status), wifiName:\(wifiName), wholeName:\(wholeName), wifiPass:\(wifiPass)")
        onWiFiOpen(status, wifiName, wholeName, wifiPass)
    }

    func bleWiFiClose(_ status: Int) {
        debugPrint("bleWiFiClose status:\(status)")
        onWiFiClose(status)
    }

    func bleSetWiFiSsid(status: Int) {
        debugPrint("bleSetWiFiSsid status:\(status)")
        onSetWiFiSsid(status: status)
    }

    func bleGetWiFiSsid(status: Int, ssid: String?) {
        debugPrint("bleGetWiFiSsid status:\(status), ssid:\(String(describing: ssid))")
        onGetWiFiSsid(status: status, ssid: ssid)
    }

    func bleVoiceAbnormal(status: Int) {
        debugPrint("bleVoiceAbnormal satus:\(status)")
        onVoiceAbnormal(status: status)
    }

    func bleWebsocketProfile(_ type: Int, _ conent: String?) {
        debugPrint("bleWebsocketProfile type:\(type), conent:\(String(describing: conent))")
        onWebsocketProfile(type, conent)
    }

    func bleWebsocketTest(_ status: Int) {
        debugPrint("bleWebsocketTest status:\(status)")
        onWebsocketTest(status)
    }

    func bleRecordStart(sessionId: Int, start: Int, status: Int, scene _: Int, startTime _: Int) {
        debugPrint("bleRecordStart sessionId:\(sessionId), start:\(start), status:\(status)")
        onRecordStart(sessionId: sessionId, start: start, status: status)
    }

    func bleRecordStop(sessionId: Int, reason: Int, fileExist: Bool, fileSize: Int) {
        debugPrint("bleRecordStop sessionId:\(sessionId), reason:\(reason), fileExist:\(fileSize), fileSize:\(fileSize)")
        onRecordStop(sessionId: sessionId, reason: reason, fileExist: fileExist, fileSize: fileSize)
    }

    func bleRecordPause() {
        debugPrint("bleRecordPause")
        onRecordPause()
    }

    func bleRecordResume() {
        debugPrint("bleRecordResume")
        onRecordResume()
    }

    func bleLedState(onOff: Int) {
        debugPrint("bleLedState onOff:\(onOff)")
        onLedState(onOff: onOff)
    }

    func bleSetLedState(onOff: Int) {
        debugPrint("bleSetLedState onOff:\(onOff)")
        onSetLedState(onOff: onOff)
    }

    func bleFileList(bleFiles: [BleFile]) {
        debugPrint("bleFileList bleFiles.count:\(bleFiles.count)")
        onFileList(bleFiles: bleFiles)
    }

    func bleSyncFileHead(sessionId: Int, status: Int) {
        debugPrint("bleSyncFileHead sessionId:\(sessionId), status:\(status)")
        onSyncFileHead(sessionId: sessionId, status: status)
    }

    func bleSyncFileTail(sessionId: Int, crc: Int) {
        debugPrint("bleSyncFileTail sessionId:\(sessionId), crc:\(crc)")
        onSyncFileTail(sessionId: sessionId, crc: crc)
    }

    func bleMarking(sessionId: Int, status: Int, markList: [UInt32]) {
        debugPrint("bleMarking sessionId:\(sessionId), status:\(status), markList.count:\(markList.count)")
        onMarking(sessionId: sessionId, status: status, markList: markList)
    }

    func bleDataComplete() {
        debugPrint("bleDataComplete")
        onDataComplete()
    }

    func bleData(sessionId: Int, start: Int, data: Data) {
        debugPrint("bleData sessionId:\(sessionId), start:\(start), data.count:\(data.count)")
        onData(sessionId: sessionId, start: start, data: data)
    }

    func blePcmData(sessionId: Int, millsec: Int, pcmData: Data) {
        debugPrint("blePcmData sessionId:\(sessionId), millsec:\(millsec), pcmData.count:\(pcmData.count)")
        onPcmData(sessionId: sessionId, millsec: millsec, pcmData: pcmData)
    }

    func bleDecodeFail(start: Int) {
        debugPrint("bleDecodeFail start:\(start)")
        onDecodeFail(start: start)
    }

    func bleSyncFileStop() {
        debugPrint("bleSyncFileStop")
        onSyncFileStop()
    }

    func bleDeleteFile(sessionId: Int, status: Int) {
        debugPrint("bleDeleteFile sessionId:\(sessionId), status:\(status)")
        onDeleteFile(sessionId: sessionId, status: status)
    }

    func bleFotaResult(uid: Int, status: Int, errmsg: String?) {
        debugPrint("bleFotaResult uid:\(uid), status:\(status), errmsg:\(String(describing: errmsg))")
        onFotaResult(uid: uid, status: status, errmsg: errmsg)
    }

    func bleFotaPackReq(uid: Int, start: Int, end: Int) {
        debugPrint("bleFotaPackReq uid:\(uid), start:\(start), end:\(end)")
        onFotaPackReq(uid: uid, start: start, end: end)
    }

    func bleFotaPackFin(uid: Int, status: Int, errmsg: String?) {
        debugPrint("bleFotaPackFin uid:\(uid), status:\(status), errmsg:\(String(describing: errmsg))")
        onFotaPackFin(uid: uid, status: status, errmsg: errmsg)
    }

    func bleOtaDataSendFail() {
        debugPrint("bleOtaDataSendFail")
        onOtaDataSendFail()
    }

    func bleRate(lossRate: Double, rate: Int, instantRate: Int) {
        debugPrint("bleRate lossRate:\(lossRate), rate:\(rate), instantRate:\(instantRate)")
        onRate(lossRate: lossRate, rate: rate, instantRate: instantRate)
    }

    func blePrivacy(privacy: Int) {
        debugPrint("blePrivacy privacy:\(privacy)")
        onPrivacy(privacy: privacy)
    }

    func bleClearAllFile(status: Int) {
        debugPrint("bleClearAllFile status:\(status)")
        onClearAllFile(status: status)
    }
}
