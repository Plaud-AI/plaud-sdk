package com.plaud.nicebuild.ble

import android.annotation.SuppressLint
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import com.plaud.nicebuild.R
import com.plaud.nicebuild.utils.AppKeyManager
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import sdk.NiceBuildSdk
import sdk.NiceBuildSdk.getAuthAndPermission
import sdk.penblesdk.TntAgent
import sdk.penblesdk.core.IBleAgent
import sdk.penblesdk.entity.BleDevice
import sdk.penblesdk.entity.BleErrorCode
import sdk.penblesdk.entity.BluetoothStatus
import sdk.penblesdk.entity.BleFile
import sdk.penblesdk.entity.bean.ble.response.ClearRecordFileRsp
import sdk.penblesdk.entity.bean.ble.response.GetStateRsp
import sdk.penblesdk.entity.bean.ble.response.RecordStartRsp
import sdk.penblesdk.entity.bean.ble.response.RecordStopRsp
import sdk.penblesdk.entity.bean.ble.response.SyncRecFileDelRsp
import sdk.penblesdk.impl.ble.BleAgentListener
import sdk.penblesdk.viocedata.IVoiceData
import sdk.penblesdk.viocedata.creator.VoiceDataCreatorFactory
import sdk.penblesdk.Constants

class BleCore private constructor(private val context: Context) {
    private val TAG: String = "Plaud App --BleManager"
    private val TNT_PENBLESDK_APPKEY = "0b1ef6247326fc79b200163e0a0431dc"
    private val TNT_CONNECTION_BLE_CONNECTTIMEOUT = 5000L
    private val TNT_CONNECTION_BLE_HANDSHAKETIMEOUT = 10000L
    private val bleDeviceList = mutableListOf<BleDevice>()
    private var bleAgentListener: BleAgentListener? = null
    private var scanCallback: ((List<BleDevice>) -> Unit)? = null
    private var connectCallback: ((Boolean, String?, String?) -> Unit)? = null
    private var getDeviceStateCallback: ((String) -> Unit)? = null
    private var currentSessionId: Long = -1
    private var currentScene: Int = -1
    private var isPaused: Boolean = false
    public var isRecording: Boolean = false
    private var onRecordingStateChangeListener: ((Boolean) -> Unit)? = null
    private var curTimeZoneHour = 0
    private var curTimeZoneMin = 0
    private var isConnecting: Boolean = false

    // Retry related variables
    private var retryCount = 0
    private val MAX_RETRY_COUNT = 3
    private var currentRetryDevice: BleDevice? = null
    private var currentRetryToken: String? = null
    private var connectTimeoutHandler: Handler? = null


    companion object {
        @SuppressLint("StaticFieldLeak")
        @Volatile
        private var instance: BleCore? = null

        fun getInstance(context: Context): BleCore {
            return instance ?: synchronized(this) {
                instance ?: BleCore(context).also { instance = it }
            }
        }
    }

    init {
        setupBleAgentListener()
        bleAgentListener?.let { listener ->
            // Always perform initialization, if key is null, pass empty string
            val (appKey, appSecret) = AppKeyManager.getAppKeyPair(context)
            NiceBuildSdk.initSdk(
                context,
                appKey ?: "",
                appSecret ?: "",
                listener,
                "Plaud SDK Showcase",
                null
            )
        }
    }

    fun updateAppKeyAndSecret(appKey: String, appSecret: String) {
        GlobalScope.launch {
            try {
                getAuthAndPermission(appKey, appSecret)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating AppKey and Secret", e)
            }
        }
    }

    private fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
        }
    }

    private fun setupBleAgentListener() {
        bleAgentListener = object : BleAgentListener {
            override fun scanBleDeviceReceiver(device: BleDevice) {
                Log.i(
                    TAG,
                    "scanBleDeviceReceiver-- name:${device.name} ,serialNumber${device.serialNumber}"
                )
                addBleDevice(device)
            }

            override fun btStatusChange(p0: String?, p1: BluetoothStatus) {
                Log.i(TAG, "btStatusChange: ${p1.name}")
                when (p1) {
                    BluetoothStatus.CONNECTED -> {
                        connectTimeoutHandler?.removeCallbacksAndMessages(null)
                        if (isConnecting) {
                            isConnecting = false
                            retryCount = 0
                            getDeviceState { json ->
                                Log.i(TAG, "Device connected successfully, getting device state: $json")
                                getBleAgent().syncTime({
                                    Log.i(TAG, "syncTime request callback: $it")
                                }, {
                                    Log.i(TAG, "syncTime response callback: ${it?.timezone}")
                                    it?.let {
                                        curTimeZoneHour = it.timezone
                                        curTimeZoneMin = getBleAgent().timezoneMin
                                        Log.i(
                                            TAG,
                                            "Setting timezone: hour=$curTimeZoneHour, min=$curTimeZoneMin"
                                        )
                                    }
                                })
                            }
                            connectCallback?.invoke(true, null, null)
                        }
                    }

                    BluetoothStatus.DISCONNECTED -> {
                        isConnecting = false
                        Log.i(TAG, "Bluetooth disconnected")
                    }

                    else -> {}
                }
            }

            override fun bleConnectFail(p0: String?, p1: sdk.penblesdk.Constants.ConnectBleFailed) {
                Log.e(TAG, "bleConnectFail: ${p1.name}")
                isConnecting = false
                val reason = p1.name

                connectCallback?.invoke(false, "-3", context.getString(R.string.connect_error_generic_fail_with_reason, reason))

            }

            override fun scanFail(p0: sdk.penblesdk.Constants.ScanFailed) {
                Log.e(TAG, "scanFail: ${p0.name}")
            }

            override fun handshakeWaitSure(p0: String?, p1: Long) {
                Log.i(TAG, "handshakeWaitSure received, considering this as successful connection.")
                connectTimeoutHandler?.removeCallbacksAndMessages(null)
                if (isConnecting) {
                    isConnecting = false
                    retryCount = 0
                    getDeviceState { json ->
                        Log.i(TAG, "Device connected successfully (via handshake), getting device state: $json")
                        getBleAgent().syncTime({
                            Log.i(TAG, "syncTime request callback: $it")
                        }, {
                            Log.i(TAG, "syncTime response callback: ${it?.timezone}")
                            it?.let {
                                curTimeZoneHour = it.timezone
                                curTimeZoneMin = getBleAgent().timezoneMin
                                Log.i(
                                    TAG,
                                    "Setting timezone: hour=$curTimeZoneHour, min=$curTimeZoneMin"
                                )
                            }
                        })
                    }
                    connectCallback?.invoke(true, null, null)
                }
            }
            override fun rssiChange(p0: String?, p1: Int) {}
            override fun mtuChange(p0: String?, p1: Int, p2: Boolean) {}
            override fun batteryLevelUpdate(p0: String?, p1: Int) {}
            override fun chargingStatusChange(p0: String?, p1: Boolean) {}
            override fun deviceOpRecordStart(
                sn: String?,
                bean: RecordStartRsp
            ) {
                isRecording = true
                Handler(Looper.getMainLooper()).post {
                    onRecordingStateChangeListener?.invoke(true)
                }
            }

            override fun deviceOpRecordStop(
                sn: String?,
                bean: RecordStopRsp
            ) {
                isRecording = false
                Handler(Looper.getMainLooper()).post {
                    onRecordingStateChangeListener?.invoke(false)
                }
            }

            override fun deviceStatusRsp(
                sn: String?,
                bean: GetStateRsp
            ) {
                if (bean.getStateCode() == Constants.DEVICE_STATUS_RECORDING) {
                    currentSessionId = bean.sessionId
                    currentScene = bean.scene
                    Log.i(TAG, "Device is recording, sessionId: ${bean.sessionId}")
                } else {
                    Log.i(TAG, "Device state: ${bean.getStateCode()}")
                }
            }
        }
    }

    fun startScan(start: Boolean, callback: ((List<BleDevice>) -> Unit)? = null) {
        Log.i(TAG, "startScan")
        if (callback != null) scanCallback = callback
        val agent = getBleAgent()
        agent.scanBle(start, { errorCode -> handleBleError(errorCode) })
    }

    fun stopScan() {
        Log.i(TAG, "stopScan")
        val agent = getBleAgent()
        agent.scanBle(false, { errorCode -> handleBleError(errorCode) })
        scanCallback = null
    }

    fun connectDevice(
        serialNumber: String,
        token: String,
        callback: (Boolean, String?, String?) -> Unit
    ) {
        Log.i(TAG, "Starting to connect device: $serialNumber")

        if (isConnecting) {
            Log.e(TAG, "Connection in progress, rejecting new connection request")
            callback(false, "-1", context.getString(R.string.connect_error_connecting_in_progress))
            return
        }

        var findDevice: BleDevice? = null
        for (device in bleDeviceList) {
            if (device.serialNumber == serialNumber) {
                findDevice = device
                break
            }
        }

        if (findDevice == null) {
            if (getBleAgent().lastConnectedDevice == null || getBleAgent().lastConnectedDevice.serialNumber != serialNumber) {
                Log.e(TAG, "Device not found: $serialNumber")
                callback(false, "-2", context.getString(R.string.connect_error_device_not_found))
                return
            }
            findDevice = getBleAgent().lastConnectedDevice
        }

        currentRetryDevice = findDevice
        currentRetryToken = token
        retryCount = 0

        startConnect(findDevice, token, callback)
    }

    private fun startConnect(
        device: BleDevice?,
        token: String,
        callback: (Boolean, String?, String?) -> Unit
    ) {
        val agent = getBleAgent()
        agent.scanBle(false, { errorCode -> handleBleError(errorCode) })
        isConnecting = true
        connectCallback = callback

        connectTimeoutHandler?.removeCallbacksAndMessages(null)
        connectTimeoutHandler = Handler(Looper.getMainLooper()).apply {
            postDelayed({
                if (isConnecting) {
                    handleConnectTimeout(callback)
                }
            }, TNT_CONNECTION_BLE_CONNECTTIMEOUT)
        }

        try {
            Log.i(TAG, "Starting BLE connection, attempt ${retryCount + 1}")
            agent.connectionBLE(
                device,
                token,
                null,
                null,
                TNT_CONNECTION_BLE_CONNECTTIMEOUT,
                TNT_CONNECTION_BLE_HANDSHAKETIMEOUT
            )
        } catch (e: Exception) {
            Log.e(TAG, "Connection error occurred: ${e.message}")
            handleConnectError(callback, e.message ?: context.getString(R.string.ble_error_unknown))
        }
    }

    fun isConnected(): Boolean {
        return getBleAgent().isConnected()
    }

    private fun handleConnectTimeout(callback: (Boolean, String?, String?) -> Unit) {
        Log.e(TAG, "Connection timeout")
        isConnecting = false
        if (retryCount < MAX_RETRY_COUNT - 1) {
            retryCount++
            Log.i(TAG, "Preparing retry attempt ${retryCount + 1}")
            currentRetryDevice?.let { device ->
                currentRetryToken?.let { token ->
                    Handler(Looper.getMainLooper()).postDelayed({
                        startConnect(device, token, callback)
                    }, 1000)
                }
            }
        } else {
            Log.e(TAG, "Maximum retry attempts exhausted")
            val message = context.getString(R.string.connect_error_timeout_retried_formatted, MAX_RETRY_COUNT)
            callback(false, "-1", message)
            retryCount = 0
            currentRetryDevice = null
            currentRetryToken = null
        }
    }

    private fun handleConnectError(
        callback: (Boolean, String?, String?) -> Unit,
        errorMessage: String
    ) {
        isConnecting = false
        if (retryCount < MAX_RETRY_COUNT - 1) {
            retryCount++
            Log.i(TAG, "Preparing retry attempt ${retryCount + 1}")
            currentRetryDevice?.let { device ->
                currentRetryToken?.let { token ->
                    Handler(Looper.getMainLooper()).postDelayed({
                        startConnect(device, token, callback)
                    }, 1000)
                }
            }
        } else {
            Log.e(TAG, "Maximum retry attempts exhausted")
            val message = context.getString(R.string.connect_error_generic_retried_formatted, errorMessage, MAX_RETRY_COUNT)
            callback(false, "-4", message)
            retryCount = 0
            currentRetryDevice = null
            currentRetryToken = null
        }
    }

    fun disconnectDevice() {
        Log.i(TAG, "Starting to disconnect")
        connectTimeoutHandler?.removeCallbacksAndMessages(null)
        try {
            getBleAgent().disconnectBle()
        } catch (e: Exception) {
            Log.e(TAG, "Error occurred during disconnection: ${e.message}")
        } finally {
            isConnecting = false
            retryCount = 0
            currentRetryDevice = null
            currentRetryToken = null
        }
    }

    fun depairDevice(callback: ((Boolean) -> Unit)? = null) {
        getBleAgent().depair(false, { req ->
            Log.i(TAG, "depairDevice request: $req")
        }, { res ->
            Log.i(TAG, "depairDevice response: $res")
            val success = res?.status == 0
            if (success) {
                currentSessionId = -1
                currentScene = -1
                isPaused = false
                isRecording = false
                bleDeviceList.clear()
                getBleAgent().disconnectBle()
            }
            callback?.invoke(success)
        }, { errorCode -> handleBleError(errorCode) })
    }

    fun startRecord(callback: ((Boolean) -> Unit)? = null) {
        getBleAgent().startRecord(0, {
            Log.i(TAG, "startRecord request: $it")
        }, {
            Log.i(TAG, "startRecord response: $it")
            val success = if (it != null) {
                currentSessionId = it.sessionId
                currentScene = it.scene
                isPaused = false
                true
            } else {
                false
            }
            callback?.invoke(success)
        }, { error ->
            Log.e(TAG, "startRecord error: $error")
            handleBleError(error)
            callback?.invoke(false)
        })
    }

    fun stopRecord(callback: ((Boolean) -> Unit)? = null) {
        getBleAgent().stopRecord(0, {
            Log.i(TAG, "stopRecord request: $it")
        }, {
            Log.i(TAG, "stopRecord response: $it")
            currentSessionId = -1
            currentScene = -1
            isPaused = false
            callback?.invoke(true) // stopRecord is likely to succeed if called.
        }, { error ->
            Log.e(TAG, "stopRecord error: $error")
            handleBleError(error)
            callback?.invoke(false)
        })
    }

    fun pauseRecord(callback: ((Boolean) -> Unit)? = null) {
        if (currentSessionId != -1L) {
            getBleAgent().recordPause(currentSessionId, currentScene, {
                Log.i(TAG, "pauseRecord request: $it")
            }, {
                Log.i(TAG, "pauseRecord response: $it")
                isPaused = true
                callback?.invoke(true)
            }, { error ->
                Log.e(TAG, "pauseRecord error: $error")
                handleBleError(error)
                callback?.invoke(false)
            })
        } else {
            callback?.invoke(false)
        }
    }

    fun resumeRecord(callback: ((Boolean) -> Unit)? = null) {
        if (currentSessionId != -1L) {
            getBleAgent().recordResume(currentSessionId, currentScene, {
                Log.i(TAG, "resumeRecord request: $it")
            }, {
                Log.i(TAG, "resumeRecord response: $it")
                isPaused = false
                callback?.invoke(true)
            }, { error ->
                Log.e(TAG, "resumeRecord error: $error")
                handleBleError(error)
                callback?.invoke(false)
            })
        } else {
            callback?.invoke(false)
        }
    }

    fun getFileList(sessionId: Long, callback: (List<BleFile>?) -> Unit) {
        try {
            getBleAgent().getRecSessions(sessionId, {}, { rsp ->
                Log.i(TAG, "getFileList: sessionId=$sessionId, rsp=$rsp")
                callback(rsp?.fileList)
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "getFileList error: ${e.message}", e)
            callback(null)
        }
    }

    fun clearAllFile(callback: ((ClearRecordFileRsp?) -> Unit)? = null) {
        getBleAgent().clearRecordFile({}, { rsp ->
            Log.i(TAG, "clearRecordFile: $rsp")
            callback?.invoke(rsp)
        }, { errorCode -> handleBleError(errorCode) })
    }

    fun deleteFile(sessionId: Long, callback: ((SyncRecFileDelRsp?) -> Unit)? = null) {
        getBleAgent().syncFileDel(sessionId, {}, { rsp ->
            Log.i(TAG, "deleteRecordFile: $rsp")
            callback?.invoke(rsp)
        }, { errorCode -> handleBleError(errorCode) })
    }

    private fun getBleAgent(): IBleAgent {
        return TntAgent.getInstant().bleAgent
    }

    private fun addBleDevice(device: BleDevice) {
        if (!bleDeviceList.any { it.serialNumber == device.serialNumber }) {
            bleDeviceList.add(device)
            scanCallback?.invoke(bleDeviceList)
        }
    }

    fun getDeviceState(callback: (String) -> Unit) {
        try {
            getBleAgent().getState({}, { response ->
                if (response != null) {
                    val effectiveSessionId = if (response.sessionId == 0L && currentSessionId != -1L) {
                        currentSessionId
                    } else {
                        response.sessionId
                    }

                    val result = GetStateResult(
                        sessionId = effectiveSessionId.toInt(),
                        state = response.stateCode.toInt(),
                        keyState = response.keyStateCode.toInt(),
                        privacy = if (response.isPrivacyEnable) 1 else 0,
                        uDisk = if (response.isUsbState) 1 else 0,
                        hasFindMyToken = response.hasFindMyToken(),
                        hasSoundPlusToken = response.hasSndpKeyState(),
                        hasHttpToken = response.hasHttpToken()
                    )
                    val jsonString = """
                    {
                        "sessionId": ${result.sessionId},
                        "state": ${result.state},
                        "keyState": ${result.keyState},
                        "privacy": ${result.privacy},
                        "uDisk": ${result.uDisk},
                        "hasFindMyToken": ${result.hasFindMyToken},
                        "hasSoundPlusToken": ${result.hasSoundPlusToken},
                        "hasHttpToken": ${result.hasHttpToken},
                        "isPaused": ${isPaused}
                    }
                    """.trimIndent()
                    Handler(Looper.getMainLooper()).post {
                        callback(jsonString)
                    }
                    Log.i(TAG, "getDeviceState: $jsonString")
                } else {
                    Handler(Looper.getMainLooper()).post {
                        callback("{}")
                    }
                    Log.e(TAG, "getDeviceState: response is null")
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "getDeviceState error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback("{}")
            }
        }
    }

    fun getBatteryState(callback: (String) -> Unit) {
        getBleAgent().getBattStatus({}, { response ->
            val level = response?.level ?: 0
            callback("$level%")
        }, { errorCode -> handleBleError(errorCode) })
    }

    fun getStorage(uiContext: Context, callback: (String) -> Unit) {
        getBleAgent().getStorage({}, { response ->
            val freeMB = (response?.getFree() ?: 0) / (1024 * 1024)
            val totalMB = (response?.getTotal() ?: 0) / (1024 * 1024)
            val usedMB = totalMB - freeMB
            val usedText = if (usedMB >= 1000) {
                String.format("%.1f GB", usedMB / 1024.0)
            } else {
                "$usedMB MB"
            }
            callback(uiContext.getString(R.string.storage_info_formatted, usedText))
        }, { errorCode -> handleBleError(errorCode) })
    }

    fun getCurrentSessionId(): Long {
        return currentSessionId
    }

    fun syncBleFile(
        sessionId: Long,
        start: Long = 0L,
        end: Long = 0L,
        decode: Boolean = false,
        onOpusData: (type: Int, start: Long, data: ByteArray) -> Unit,
        onPCMData: (type: Int, start: Long, data: ShortArray) -> Unit,
        onFinish: (endingTag: String) -> Unit
    ) {
        val processDataCallBack = IVoiceData { data: ShortArray?, startPos: Long ->
            data?.let {
                if (decode) onPCMData(1, startPos, it)
            }
        }
        val originalDataCallBack = IVoiceData { data: ByteArray?, startPos: Long ->
            data?.let {
                onOpusData(1, startPos, it)
            }
        }
        val dataProcess = VoiceDataCreatorFactory.newOpusToPcm()
        dataProcess.setOriginalDataCallBack(originalDataCallBack)
        dataProcess.setProcessDataCallBack(processDataCallBack)

        getBleAgent().syncFileStart(
            sessionId, start, end,
            { 
                Log.i(TAG, "syncBleFile: start")
            },
            { onOpusData(0, 0, ByteArray(0)); if (decode) onPCMData(0, 0, ShortArray(0)) },
            {
                onFinish("syncBleFileEnd")
                Log.i(TAG, "syncBleFile: finish")
            },
            dataProcess,
            { errorCode ->
                handleBleError(errorCode)
            },
        )
    }

    fun isRecordingActive(): Boolean {
        return isRecording && !isPaused
    }

    fun isPaused(): Boolean {
        return isPaused
    }

    fun clearDeviceList() {
        bleDeviceList.clear()
    }

    fun setOnRecordingStateChangeListener(listener: (Boolean) -> Unit) {
        onRecordingStateChangeListener = listener
    }

    data class GetStateResult(
        val sessionId: Int,
        val state: Int,
        val keyState: Int,
        val privacy: Int,
        val uDisk: Int,
        val hasFindMyToken: Int,
        val hasSoundPlusToken: Int,
        val hasHttpToken: Int
    )

    data class DeviceFile(
        val serialNumber: String,
        val sessionId: Long,
        val fileSize: Long,
        val scene: Int,
        val channel: Int,
        val timeZoneHour: Int,
        val timeZoneMin: Int
    )

    fun setAutoSync(enable: Boolean, callback: (Boolean) -> Unit) {
        try {
            val type =
                if (enable) sdk.penblesdk.Constants.CommonSwitch.ON else sdk.penblesdk.Constants.CommonSwitch.OFF
            getBleAgent().setAutoSync(type, {}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    val success = rsp?.value?.toInt() == 1
                    callback(success)
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "setAutoSync error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(false)
            }
        }
    }

    fun getAutoSync(callback: (Boolean?, String?) -> Unit) {
        try {
            getBleAgent().getAutoSync({}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    if (rsp != null) {
                        val enabled = rsp.value.toInt() == 1
                        callback(enabled, "success")
                    } else {
                        callback(null, "response is null")
                    }
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "getAutoSync error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(null, e.message)
            }
        }
    }

    fun getWifiInfo(
        wifiIndex: Int,
        callback: (sdk.penblesdk.entity.bean.ble.response.GetWifiInfoRsp?) -> Unit
    ) {
        try {
            getBleAgent().getWifiInfo(wifiIndex, {}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    callback(rsp)
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "getWifiInfo error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(null)
            }
        }
    }

    fun setSyncWifi(
        operation: Int,
        ssid: String,
        password: String,
        wifiIndex: Int,
        callback: (sdk.penblesdk.entity.bean.ble.response.SetWifiRsp?) -> Unit
    ) {
        try {
            getBleAgent().setSyncWifi(operation, ssid, password, wifiIndex, {}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    callback(rsp)
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "setSyncWifi error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(null)
            }
        }
    }

    fun deleteWifiInfo(
        wifiIndexList: List<Long>,
        callback: (sdk.penblesdk.entity.bean.ble.response.DeleteWifiRsp?) -> Unit
    ) {
        try {
            getBleAgent().deleteWifiInfo(wifiIndexList, {}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    callback(rsp)
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "deleteWifiInfo error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(null)
            }
        }
    }

    fun testWifiInfo(
        wifiIndex: Long,
        callback: (sdk.penblesdk.entity.bean.ble.response.TestWifiInfoRsp?) -> Unit
    ) {
        try {
            getBleAgent().testWifiInfo(wifiIndex, {}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    callback(rsp)
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "testWifiInfo error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(null)
            }
        }
    }

    fun testWifiResult(
        wifiIndex: Long,
        callback: (sdk.penblesdk.entity.bean.ble.response.TestWifiResultRsp?) -> Unit
    ) {
        try {
            getBleAgent().testWifiResult(wifiIndex, {}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    callback(rsp)
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "testWifiResult error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(null)
            }
        }
    }

    fun getWifiList(callback: (sdk.penblesdk.entity.bean.ble.response.GetWifiListRsp?) -> Unit) {
        try {
            getBleAgent().getWifiList({}, { rsp ->
                Handler(Looper.getMainLooper()).post {
                    callback(rsp)
                }
            }, { errorCode -> handleBleError(errorCode) })
        } catch (e: Exception) {
            Log.e(TAG, "getWifiList error: ${e.message}", e)
            Handler(Looper.getMainLooper()).post {
                callback(null)
            }
        }
    }

    fun setWifiSyncDomain(domain: String, callback: (Boolean) -> Unit) {
        getBleAgent().setWifiSyncDomain(domain,
            { success ->
                if (!success) {
                    callback(false)
                }
            },
            { response ->
                callback(response?.status == 0)
            },
            { error ->
                handleBleError(error)
                callback(false)
            }
        )
    }

    fun getMICGain(callback: (Int) -> Unit) {
        getBleAgent().getMICGain({
            Log.d(TAG, "getMICGain request: $it")
        }, {
            Log.d(TAG, "getMICGain response: $it")
            callback(it?.value?.toInt() ?: 15) // Default to 15 if null
        }, {
            handleBleError(it)
            callback(15) // Default to 15 on error
        })
    }

    fun setMICGain(gain: Int, callback: (Boolean) -> Unit) {
        getBleAgent().setMICGain(gain, {
            Log.d(TAG, "setMICGain request: $it")
        }, {
            Log.d(TAG, "setMICGain response: $it")
            callback(it != null)
        }, {
            handleBleError(it)
            callback(false)
        })
    }

    fun setUDiskMode(enable: Boolean, callback: (Boolean) -> Unit) {
        getBleAgent().setUDiskMode(enable, {
            Log.d(TAG, "setUDiskMode request: $it")
        }, {
            Log.d(TAG, "setUDiskMode response: $it")
            callback(it?.isOnOff == enable)
        })
    }

    private fun handleBleError(errorCode: BleErrorCode) {
        Log.e(TAG, "BLE Error: ${errorCode.name}")
        showToast("BLE Error: ${errorCode.name}")
        val message = when (errorCode) {
            BleErrorCode.NO_BASE_PERMISSION -> context.getString(R.string.toast_bluetooth_permission_required)
            BleErrorCode.BLUETOOTH_NOT_ENABLED -> context.getString(R.string.ble_error_bluetooth_not_enabled)
            BleErrorCode.NO_DOWNLOAD_PERMISSION -> context.getString(R.string.ble_error_no_download_permission)
            BleErrorCode.BLUETOOTH_NOT_SUPPORTED -> context.getString(R.string.ble_error_bluetooth_not_supported)
            BleErrorCode.BLUETOOTH_NOT_CONNECTED -> context.getString(R.string.ble_error_bluetooth_not_connected)
            BleErrorCode.OPERATION_TIMEOUT -> context.getString(R.string.ble_error_operation_timeout)
            BleErrorCode.OPERATION_FAILED -> context.getString(R.string.ble_error_operation_failed)
//            BleErrorCode.RECORD_START_FAILED -> context.getString(R.string.ble_error_record_start_failed)
//            BleErrorCode.RECORD_STOP_FAILED -> context.getString(R.string.ble_error_record_stop_failed)
//            BleErrorCode.RECORD_PAUSE_FAILED -> context.getString(R.string.ble_error_record_pause_failed)
//            BleErrorCode.RECORD_RESUME_FAILED -> context.getString(R.string.ble_error_record_resume_failed)
            BleErrorCode.UNKNOWN_ERROR -> context.getString(R.string.ble_error_unknown)
            null -> context.getString(R.string.ble_error_unknown)
            else -> context.getString(R.string.ble_error_unknown) + " (${errorCode.name})"
        }
        if (message.isNotBlank()) {
            showToast(message)
        }
        Log.e(TAG, "handleBleError: ${errorCode.name} - Toast: $message")
    }
}