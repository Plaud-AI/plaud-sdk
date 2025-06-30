## Introduction
This document provides guidance for integrating and using of the PLAUD SDK.

## Function Overview

    - PLAUD SDK
      - Initialization
        - Get App Key
        - Bind Device
      - Connection Management
        - Start scanning
        - Discover devices
        - Stop scanning
        - Connect device
        - Disconnect device
      - Device Information
        - Device status
        - Storage capacity
        - Power status
        - etc
      - Recording control
        - Start recording
        - Pause recording
        - Resume recording
        - Stop recording
      - Data Export
        - Get file list
        - Download file
        - Stop download
        - Delete file
        - Delete all files
      - Wifi Cloud Sync
        - Add Wifi
        - Delete Wifi
        - Update Wifi
        - Get Wifi list
        - Set cloud address
      - Cloud Processing Service
        - AI Transcription & Summarization



## Interface Description

### Android Platform   

* Dependency Injection

```code
  // Import the provided aar
  implementation(name: 'plaud-sdk', ext: 'aar')

  // Required dependencies
  implementation("com.google.guava:guava:28.2-android")
  implementation "androidx.navigation:navigation-fragment-ktx:2.7.7"
  implementation "androidx.navigation:navigation-ui-ktx:2.7.7"
  implementation 'com.squareup.retrofit2:retrofit:2.9.0'
  implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
  implementation 'com.squareup.okhttp3:okhttp:4.10.0'
  implementation 'com.squareup.okhttp3:logging-interceptor:4.10.0'
  implementation platform('com.google.firebase:firebase-bom:32.7.4')
  implementation 'com.google.firebase:firebase-analytics'
```

####  Device Connection

*  Initialization

```code
// SDK initialization method
fun initSdk(
 context: Context,
 appKey: String,
 bleAgentListener: BleAgentListener,
 hostName: String,
 extra: Map<String, Any>?
)

// Application
bleAgentListener = object : BleAgentListener {
 // Implement on your own
}
bleAgentListener?.let { Sdk.initSdk(context, "plaud-zoem8KYd-1748487531106", it, hostName, null) }
```

* Start/Stop Scan

```code
/**
 * @param isStart Start/stop scan
 */
agent.scanBle(boolean isStart)
```

* Get Scanned Devices

```code
BleAgentListener {
 override fun scanBleDeviceReceiver (device: BleDevice) {
 // addDevice
 }
}
```

* Start Connection

```code
/**
 * @param device Device instance {@link BleDevice}
 * @param bindToken Binding token
 * @param devToken Device binding code (not required)
 * @param userName User name (not required)
 * @param connectTimeout Connection timeout duration (must be > 0)
* @param handshakeTimeout Handshake timeout duration (must be > 0)*/

agent.connectionBLE(BleDevice device, String bindToken, String devToken,
         String userName, long connectTimeout, long handshakeTimeout)
```

* Unpair

```code
    /**
     * Unpair the device
     *
     * @param isClearFile Whether to clear device files
     * @param onRequest Send callback
     * @param onResponse Device return callback
     */
    agent.depair(boolean isClearFile, AgentCallback.OnRequest onRequest,
          AgentCallback.OnResponse<DepairRsp> onResponse);
```

- Disconnect

```code
    agent.disconnectBle()
```

#### Device Information

- Get Device Status

```code
    /**
     * Get device status
     *
     * @param onRequest Send callback
     * @param onResponse Device return callback
     */
    agent.getState(AgentCallback.OnRequest onRequest,
           AgentCallback.OnResponse<GetStateRsp> onResponse);
```

- Get Battery Status

```code
  /**
   * Get battery status
   *
   * @param onRequest Send callback
   * @param onResponse Device return callback
   */
  agent.getBattStatus(AgentCallback.OnRequest onRequest, 
            AgentCallback.OnResponse<BattStatusRsp> onResponse);
```

- Get Storage Capacity
```code
  /**
   * Get remaining system capacity
   *
   * @param onRequest Send callback
   * @param onResponse Device return callback
   */
  agent.getStorage (AgentCallback.OnRequest onRequest,
           AgentCallback.OnResponse<StorageRsp> onResponse);
```

#### Recording Control

- Start Recording

```code
  /**
   * Start recording
   *
   * @param scene Scene
   * @param onRequest Send callback
   * @param onResponse Device return callback
   */
  agent.startRecord(int scene, AgentCallback.OnRequest onRequest,
           AgentCallback.OnResponse<RecordStartRsp> onResponse);
```

- Pause Recording

```code
  /**
   * Pause recording
   *
   * @param sessionId Session ID

    * @param onRequest Send callback
    * @param onResponse Device return callback
    */
    agent.recordPause(long sessionId, int scene, AgentCallback.OnRequest onRequest,
           AgentCallback.OnResponse<RecordPauseRsp> onResponse);

```

- Resume Recording

```code
    /**
     * Resume recording
     *
     * @param sessionId Session ID
     * @param scene Scene
     * @param onRequest Send callback
     * @param onResponse Device return callback
     */
     agent.recordResume(long sessionId, int scene, AgentCallback.OnRequest onRequest,
          AgentCallback.OnResponse<RecordResumeRsp> onResponse);
```

- Stop Recording

```code
   /**
    * Stop recording
    *
    * @param scene Scene
    * @param onRequest Send callback
    * @param onResponse Device return callback
    */
    agent.stopRecord(int scene, AgentCallback.OnRequest onRequest,
           AgentCallback.OnResponse<RecordStopRsp> onResponse);
```

 ####  Export Recording

- Get File List

```code
   /**
    * Get list of recording session files
    * @param sessionId Session ID
    * @param onRequest Send callback
    * @param onResponse Device return callback*/
    agent.getRecSessions(long sessionId, AgentCallback.OnRequest onRequest,
           AgentCallback.OnResponse<GetRecSessionsRsp> onResponse);

```

- Download File

```code
  /**
   * Download file
   * When downloading a single file, two information packets (head & tail) are added
   * to mark the start and end of the data packet (package) transmission.
   *
   * @param sessionId Recording session ID
   * @param start Start position
   * @param end End position
   * @param onRequest Send callback
   * @param onHeadResponse Download file head callback {@link AgentCallback.OnResponse <SyncFileHeadRsp>}
   * @param onTailResponse Download file tail callback {@link AgentCallback.OnResponse <SyncFileTailRsp>}
   * @param voiceDataCreator This parameter cannot be null {@link ISyncVoiceDataKeepOut} */
   agent.syncFileStart(long sessionId, long start, long end,
        AgentCallback.OnRequest onRequest,
        AgentCallback.OnResponse <SyncFileHeadRsp> onHeadResponse,
        AgentCallback.OnResponse<SyncFileTailRsp> onTailResponse,
        ISyncVoiceDataKeepOut voiceDataCreator);
```

- Stop Download

```code
  /**
   * Stop file download
   *
   * @param onRequest Send callback
   * @param onResponse Device return callback*/
   agent.syncFileStop(AgentCallback.OnRequest onRequest,
        AgentCallback.OnResponse<SyncRecFileStopRsp> onResponse);
```

- Delete File

```code
   /**
    * Delete file
    *
    * @param sessionId File ID
    * @param onRequest Send callback
    * @param onResponse Device return callback*/
    agent.syncFileDel(long sessionId, AgentCallback.OnRequest onRequest,
         AgentCallback.OnResponse<SyncRecFileDelRsp> onResponse);
```

- Clear Files

```code
   /**
    * Clear recording files on the device end
    *
    * @param onRequest Send callback
    * @param onResponse Device return callback
    */
   agent.clearRecordFile(AgentCallback.OnRequest onRequest,
        AgentCallback.OnResponse<ClearRecordFileRsp> onResponse);
```

#### Device Wi-Fi Sync

- Set Wi-Fi Auto-Sync Switch

```code
   /**
    * Set idle time sync
    *
    * @param type On/Off
    * @param onRequest Send callback
    * @param onResponse Device return callback
    */
   agent.setAutoSync(Constants.CommonSwitch type, AgentCallback.OnRequest onRequest,
        AgentCallback.OnResponse<CommonSettingsRsp> onResponse);
```

- Get Wi-Fi Auto-Sync Switch

```code
/**
 * Get idle time sync
 *
 * @param onRequest Send callback
 * @param onResponse Device return callback
 */
agent.getAutoSync(AgentCallback.OnRequest onRequest,
         AgentCallback.OnResponse<CommonSettingsRsp> onResponse);
```

- Get Wi-Fi Information

```code
/**
 * Get idle time Wi-Fi information
 *
 * @param onRequest Send callback
 * @param onResponse Device return callback
 */
agent.getWifiInfo(int wifiIndex, AgentCallback.OnRequest onRequest,
                    AgentCallback.OnResponse<GetWifiInfoRsp> onResponse);
```

• Set Wi-Fi Information

```code
/**
 * Set Wi-Fi information
 *
 * @param onRequest Send callback
 * @param onResponse Device return callback
 */
agent.setSyncWifi(int operation,
                   String ssid,
                   String password,
                   int wifiIndex, AgentCallback.OnRequest onRequest,
                   AgentCallback.OnResponse<SetWifiRsp> onResponse);
```

• Delete Wi-Fi Information

```code
/**
 * Delete idle time Wi-Fi information
 *
 * @param onRequest Send callback
* @param onResponse Device return callback

agent.deleteWifiInfo(List<Long> wifiIndexs, AgentCallback.OnRequest onRequest,
      AgentCallback.OnResponse<DeleteWifiRsp> onResponse);
```

- Test Wi-Fi Network

```code
/**
 * Test idle time sync Wi-Fi
 *
 * @param onRequest Send callback
 * @param onResponse Device return callback
 */
agent.testWifiInfo(Long wifiIndex, AgentCallback.OnRequest onRequest,
      AgentCallback.OnResponse<TestWifiInfoRsp> onResponse);
```

- Get Wi-Fi Network Test Result (Note: The connection will be lost during this process. Manual reconnection is required to get the result.)

```code
/**
 * Get the result of the idle time sync Wi-Fi test
 *
 * @param onRequest Send callback
 * @param onResponse Device return callback
 */
agent.testWifiResult(Long wifiIndex, AgentCallback.OnRequest onRequest,
      AgentCallback.OnResponse<TestWifiResultRsp> onResponse);
```

- Get Wi-Fi List

```code
/**
 * Get the idle time sync Wi-Fi list
 *
 * @param onRequest Send callback
 * @param onResponse Device return callback
 */
agent.getWifiList(AgentCallback.OnRequest onRequest,
      AgentCallback.OnResponse<GetWifiListRsp> onResponse);
```

- Set Wi-Fi Upload Domain

```code
agent.setWifiSyncDomain(String url, AgentCallback. OnRequest onRequest,
        AgentCallback. OnResponse<CommonStringSetRsp> onResponse,
        AgentCallback.OnError onError);
```

#### AI Cloud Workflow

- Transcribe and Summary

```code
   /**
    * Transcribe  and Summary
    *
    * @param fileId
    * @param workflows A list of workflows that define the processing steps to be applied to the file. Each workflow may represent a different set of operations or transformations that are to be performed on the file.
    */

    SubmitResponse response = NiceBuildSdk.submit(fileId: String,workflows: List<Workflow>?,)
```

### iOS Platform

- Dependency Injection

You need to import `PenBleSDK.framework` and `PlaudDeviceBasicSDK.framework`. For specific import methods, please refer to the DemoApp.

#### Device Connection

Get Plaud device agent, initialize SDK

```code
@property (nonatomic, strong) PlaudDeviceAgent* deviceAgent;
self.deviceAgent = [PlaudDeviceAgent shared];
[self.deviceAgent initSDKWithHostName: @"" appKey:@"PLAUD-3d8f7a2b-1712345678" bindToken:@"123456789" extra:@{}];
```

Implementer's component implements the delegate protocol: `PlaudDeviceAgentProtocol`

```code
@interface ScanDeviceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PlaudDeviceAgentProtocol>
```

- Start Scan

```code
[self.deviceAgent startScan];
```

Receive Scanned Devices
In the delegate method, receive and display the scanned devices. Refer to the implementation of `ScanDeviceViewController`

```code
  - (void)bleScanResultWithBleDevices:(NSArray<BleDevice *> *)bleDevices {
      [self.devices removeAllObjects];
      [self.devices addObjectsFromArray:bleDevices];
      [self.tableView reloadData];
  }
```

- Connect Device

From the returned devices, select a specific device and call the connect device interface.

```code
  - (void)connectToDevice:(BleDevice *)device {
      if (device) {
          [self.deviceAgent connectBleDeviceWithBleDevice:device];
      }
  }
```

The connection status will be returned in the following callback:

```code
  - (void)bleConnectStateWithState:(NSInteger)state {
      NSString *message;
      switch (state) {
          case 0:
              message = @"Device not connected";
              break;
          case 1:
              message = @"Device connected successfully";
              break;
         case 2:
             message = @"Device connection failed";
              break;
         default:
              message = @"Unknown connection state";
              break;
      }
      NSLog(@"bleConnectStateWithState, %@", message);
      [self showToastWithMessage:message];
  }
```

- Disconnect

```code
   [self.deviceAgent disconnect];
```

#### Device Information

- Get Device Status

```code
   [self.deviceAgent getState];
   // Result callback, see blePenState
```

- Get Battery Status

```code
   self.deviceAgent.getChargingState()
   // Result callback, see bleChargingState
   // where isCharging indicates if it's charging
   // where level is the battery percentage
```

- Get Storage Capacity

```code
   self.deviceAgent.getStorage()
   // Result callback, see bleStorage
```

#### Recording Control  

- Start Recording
```code
  [self.deviceAgent startRecord];
// Result callback, see bleRecordStart
```

- Pause Recording

```code
  [self.deviceAgent pauseRecord];
  // Result callback, see bleRecordPause
```

- Resume Recording

```code
  [self.deviceAgent resumeRecord];
  // Result callback, see resumeRecord
```

- Stop Recording

```code
  [self.deviceAgent stopRecord];
  // Result callback, see bleRecordStop
```

#### Export Recording

- Get File List

```code
  // Trigger: getFileList
  // Parameter: sessionId: From which file to start downloading. O means download all.
  self.deviceAgent.getFileList(sessionId: 0)
  // Result callback, where bleFiles is the file list
  func bleFileList (bleFiles: [BleFile])
```

- Download File

```code
  /// Download file
  ///
  /// - Parameters:
  /// - sessionId: The unique ID of the recording file
  /// - outputPath: The path to save the recording file
  self.deviceAgent.downloadFile(sessionId: bleFile.sessionId, outputPath: targetPath)

  // Result callback
  /// @see Callback bleDownloadFile
  // which includes file ID, download path, download status, download progress, and a prompt message.

```

- Stop Download

```code
  self.deviceAgent.stopDownloadFile()
  // Result callback bleDownloadFileStop
```

- Delete File

```code
  // Parameter sessionId: Unique ID of the recording file
  self.bleAgent.deleteFile(sessionId: bleFile.sessionId)
  // Result callback bleDeleteFile
```

- Delete All Files

```code
  self.bleAgent.clearAllFile()
  // Result callback bleClearAllFile
```

#### Device Wi-Fi Sync

- Wi-Fi Sync Switch

```code
  // Set Wi-Fi Sync Switch
  // Parameter value: 0: Off, 1: On
  self.deviceAgent.setWifiSyncEnable(value: Int)

  // Get switch status, result callback onWifiSyncEnabled
  func getWifiSyncEnable()
  /// Set upload address
  /// - Parameter path: Upload address
  @objc public func setWifiSyncDomain(path: String)
```

- Wi-Fi Sync List

```code
  /// Set Wi-Fi Configuration
  /// - Parameters:
  /// - operation: Operation type (1: Add, 2: Modify)
  /// - wifiIndex: Wi-Fi index (4 bytes)
  /// - ssid: Wi-Fi SSID
  /// - password: Wi-Fi Password
  @objc public func setWifiSyncConfig(operation: Int, wifiIndex: UInt32, ssid: String, password: String)

  /// Get Wi-Fi Configuration
  /// - Parameter wifiIndex: Wi-Fi index (4 bytes)
  @objc public func getWifiSyncConfig(wifiIndex: UInt32)

  /// Delete Wi-Fi Configuration
  /// - Parameters:
  /// - wifiIndices: Array of Wi-Fi indices to delete (each index is 4 bytes)
  @objc public func deleteWifiSyncConfig(wifiIndices: [UInt32])

  /// Get Wi-Fi List
  @objc public func getWifiSyncList()
```

- Wi-Fi Connectivity Test

```code
  /// Initiate Wi-Fi Test
  /// - Parameter wifiIndex: Wi-Fi index (4 bytes)
  @objc public func setWifiSyncTest(wifiIndex: UInt32)

  /// Get Wi-Fi Test Result
  /// - Parameter wifiIndex: Wi-Fi index (4 bytes)
  @objc public func getWifiSyncTestResult(wifiIndex: UInt32)
```

#### AI Cloud Workflow

- Transcribe and Summary

```code
     public func submitAndWaitForCompletion(
        _ request: WorkflowSubmitRequest,
        timeout: TimeInterval,
        progressHandler: ((WorkflowStatusResponse) -> Void)? = nil,
        completion: @escaping (WorkflowResult<WorkflowResultResponse>) -> Void
    )
```

## Download Link

- Bill of Materials
      *   Android: `plaud-sdk.aar`
      *   iOS: `PenBleSDK.framework`, `PlaudDeviceBasicSDK.framework` 
      *   DemoApp: SDK Demo  
