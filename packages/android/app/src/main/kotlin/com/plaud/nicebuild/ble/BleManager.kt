package com.plaud.nicebuild.ble

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import sdk.LoadingManager
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.withContext
import sdk.penblesdk.entity.BleDevice

class BleManager private constructor(private val context: Context) {

    private val bleCore = BleCore.getInstance(context)

    companion object {
        @Volatile
        private var instance: BleManager? = null

        fun getInstance(context: Context): BleManager =
            instance ?: synchronized(this) {
                instance ?: BleManager(context.applicationContext).also { instance = it }
            }
    }
    
    fun connectDevice(
        device: BleDevice,
        callback: (Boolean, String?, String?) -> Unit
    ) {
        CoroutineScope(Dispatchers.Main).launch {
            LoadingManager.showLoading(context, "Connecting...")
            bleCore.stopScan()

            val result = withTimeoutOrNull(20000L) { // 20s timeout from fragment
                suspendCoroutine<Triple<Boolean, String?, String?>> { continuation ->
                    bleCore.connectDevice(device.serialNumber, device.serialNumber) { success, code, message ->
                        if (continuation.context.isActive) {
                            continuation.resume(Triple(success, code, message))
                        }
                    }
                }
            }
            
            LoadingManager.hideLoading()

            if (result != null) {
                if (!result.first) {
                    bleCore.disconnectDevice()
                }
                callback(result.first, result.second, result.third)
            } else { // timeout
                bleCore.disconnectDevice()
                callback(false, "-100", "Connection timed out")
            }
        }
    }
    
    fun getDeviceState(callback: (String) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            LoadingManager.showLoading(context, "Getting device state...")
            val state = withTimeoutOrNull(5000L) { // 5s timeout
                suspendCoroutine<String> { continuation ->
                    bleCore.getDeviceState { stateString ->
                        if (continuation.context.isActive) {
                            continuation.resume(stateString)
                        }
                    }
                }
            }
            LoadingManager.hideLoading()
            callback(state ?: "{}") // return empty json on timeout/error
        }
    }

    fun setWifiSyncDomain(domain: String, callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            LoadingManager.showLoading(context, "Setting WiFi Domain...")
            val success = withTimeoutOrNull(10000L) { // 10s timeout
                suspendCoroutine<Boolean> { continuation ->
                    bleCore.setWifiSyncDomain(domain) { result ->
                        if (continuation.context.isActive) {
                            continuation.resume(result)
                        }
                    }
                }
            }
            LoadingManager.hideLoading()
            callback(success ?: false)
        }
    }

    fun depairDevice(callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            LoadingManager.showLoading(context, "Unpairing device...")
            val success = withTimeoutOrNull(10000L) { // 10s timeout
                suspendCoroutine<Boolean> { continuation ->
                    bleCore.depairDevice { result ->
                        if (continuation.context.isActive) {
                            continuation.resume(result)
                        }
                    }
                }
            }
            LoadingManager.hideLoading()
            callback(success ?: false)
        }
    }

    fun startRecord(callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            val success = suspendCoroutine<Boolean> { continuation ->
                bleCore.startRecord { result ->
                    if (continuation.context.isActive) {
                        continuation.resume(result)
                    }
                }
            }
            callback(success)
        }
    }

    fun stopRecord(callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            val success = suspendCoroutine<Boolean> { continuation ->
                bleCore.stopRecord { result ->
                    if (continuation.context.isActive) {
                        continuation.resume(result)
                    }
                }
            }
            callback(success)
        }
    }

    fun pauseRecord(callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            val success = suspendCoroutine<Boolean> { continuation ->
                bleCore.pauseRecord { result ->
                    if (continuation.context.isActive) {
                        continuation.resume(result)
                    }
                }
            }
            callback(success)
        }
    }

    fun resumeRecord(callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            val success = suspendCoroutine<Boolean> { continuation ->
                bleCore.resumeRecord { result ->
                    if (continuation.context.isActive) {
                        continuation.resume(result)
                    }
                }
            }
            callback(success)
        }
    }

    fun getMICGain(callback: (Int) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            LoadingManager.showLoading(context, "Getting Mic Gain...")
            val gain = withTimeoutOrNull(5000L) { // 5s timeout
                suspendCoroutine<Int> { continuation ->
                    bleCore.getMICGain { result ->
                        if (continuation.context.isActive) {
                            continuation.resume(result)
                        }
                    }
                }
            }
            LoadingManager.hideLoading()
            callback(gain ?: 15) // Default to 15 on timeout/error
        }
    }

    fun setMICGain(gain: Int, callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            val success = suspendCoroutine<Boolean> { continuation ->
                bleCore.setMICGain(gain) { result ->
                    if (continuation.context.isActive) {
                        continuation.resume(result)
                    }
                }
            }
            callback(success)
        }
    }

    fun setUDiskMode(enable: Boolean, callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            val success = withTimeoutOrNull(5000L) { // 5s timeout
                suspendCoroutine<Boolean> { continuation ->
                    bleCore.setUDiskMode(enable) { result ->
                        if (continuation.context.isActive) {
                            continuation.resume(result)
                        }
                    }
                }
            }
            LoadingManager.hideLoading()
            callback(success ?: false)
        }
    }
    
    fun setWifi(
        operation: Int,
        ssid: String,
        pwd: String,
        wifiIndex: Int,
        callback: (Boolean) -> Unit
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            withContext(Dispatchers.Main) { LoadingManager.showLoading(context, "Saving WiFi...") }
            val success = withTimeoutOrNull(10000L) { // 10-second timeout
                suspendCoroutine<Boolean> { continuation ->
                    bleCore.setSyncWifi(operation, ssid, pwd, wifiIndex) { rsp ->
                        if (continuation.context.isActive) {
                            continuation.resume(rsp != null)
                        }
                    }
                }
            } ?: false
            withContext(Dispatchers.Main) {
                LoadingManager.hideLoading()
                callback(success)
            }
        }
    }

    fun deleteWifi(wifiIndex: Int, callback: (Boolean) -> Unit) {
        CoroutineScope(Dispatchers.IO).launch {
            withContext(Dispatchers.Main) { LoadingManager.showLoading(context, "Deleting WiFi...") }
            val success = withTimeoutOrNull(10000L) { // 10-second timeout
                suspendCoroutine<Boolean> { continuation ->
                    bleCore.deleteWifiInfo(listOf(wifiIndex.toLong())) { rsp ->
                        if (continuation.context.isActive) {
                            continuation.resume(rsp != null)
                        }
                    }
                }
            } ?: false
            withContext(Dispatchers.Main) {
                LoadingManager.hideLoading()
                callback(success)
            }
        }
    }
    
    fun isConnected(): Boolean {
        return bleCore.isConnected()
    }

    fun updateAppKey(appKey: String, appSecret: String) {
        bleCore.updateAppKeyAndSecret(appKey, appSecret)
    }
} 