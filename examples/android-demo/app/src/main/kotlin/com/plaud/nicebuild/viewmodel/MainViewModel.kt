package com.plaud.nicebuild.viewmodel

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.plaud.nicebuild.ble.BleCore
import com.plaud.nicebuild.ble.BleManager
import com.plaud.nicebuild.data.WifiCacheManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import sdk.NiceBuildSdk
import sdk.network.manager.S3UploadManager
import sdk.penblesdk.entity.BleDevice
import sdk.penblesdk.entity.BleFile
import sdk.penblesdk.entity.bean.ble.response.GetWifiInfoRsp
import java.io.File
import java.util.TimeZone
import kotlinx.coroutines.withTimeoutOrNull
import sdk.network.model.WorkflowResultResponse
import sdk.network.model.WorkflowStatusResponse
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeout

class MainViewModel(application: Application) : AndroidViewModel(application) {
    private val _deviceList = MutableLiveData<List<BleDevice>>(emptyList())
    val deviceList: LiveData<List<BleDevice>> = _deviceList

    private val _currentDevice = MutableLiveData<BleDevice?>()
    val currentDevice: LiveData<BleDevice?> = _currentDevice

    private val _fileList = MutableLiveData<List<BleFile>>(emptyList())
    val fileList: LiveData<List<BleFile>> = _fileList

    private val _wifiList = MutableLiveData<List<GetWifiInfoRsp>>(emptyList())
    val wifiList: LiveData<List<GetWifiInfoRsp>> = _wifiList

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _workflowStatus = MutableLiveData<WorkflowStatusResponse?>()
    val workflowStatus: LiveData<WorkflowStatusResponse?> = _workflowStatus

    private val _workflowResult = MutableLiveData<WorkflowResultResponse?>()
    val workflowResult: LiveData<WorkflowResultResponse?> = _workflowResult

    private val bleManager = BleManager.getInstance(application) // UI-aware manager
    private val bleCore = BleCore.getInstance(application)   // Pure data agent
    private val s3UploadManager: S3UploadManager by lazy { NiceBuildSdk.s3UploadManager }
    private val appContext = application.applicationContext

    fun setLoading(loading: Boolean) {
        _isLoading.postValue(loading)
    }

    fun updateDeviceList(list: List<BleDevice>) {
        _deviceList.postValue(list)
    }

    fun setCurrentDevice(device: BleDevice?) {
        _currentDevice.value = device
    }

    fun updateFileList(list: List<BleFile>) {
        _fileList.postValue(list)
    }

    fun uploadFile(
        opusFile: File,
        bleFile: BleFile,
        onProgress: (Float) -> Unit,
        onResult: (Boolean, String?, String?) -> Unit // success, errorMessage, fileId
    ) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val sn = currentDevice.value?.serialNumber ?: "Unknown"
                val apiToken = NiceBuildSdk.apiToken ?: throw IllegalStateException("SDK Token not available")

                val fileId = s3UploadManager.uploadFile(
                    apiToken = apiToken,
                    filePath = opusFile.absolutePath,
                    fileSize = opusFile.length(),
                    fileType = "opus",
                    snType = "notepin",
                    sn = sn,
                    startTime = bleFile.sessionId,
                    endTime = bleFile.sessionId, // Placeholder
                    timezone = TimeZone.getDefault().rawOffset / 3600000,
                    zoneMins = (TimeZone.getDefault().rawOffset % 3600000) / 60000,
                    onProgress = onProgress
                )

                launch(Dispatchers.Main) { onResult(true, null, fileId) }

            } catch (e: Exception) {
                Log.e("MainViewModel", "Upload failed", e)
                launch(Dispatchers.Main) { onResult(false, e.message, null) }
            }
        }
    }

    fun submit(fileId: String, onResult: (workflowId: String?, success: Boolean, message: String) -> Unit) {
        viewModelScope.launch {
            val response = NiceBuildSdk.submit(fileId)
            if (response != null) {
                val message = "Status: ${response.status}"
                onResult(response.id, true, message)
            } else {
                onResult(null, false, "Submit failed: Response was null")
            }
        }
    }

    fun getWorkflowStatus(workflowId: String) {
        viewModelScope.launch {
            try {
                withTimeout(60_000_000L) {
                    while (isActive) {
                        val statusResponse = NiceBuildSdk.getWorkflowStatus(workflowId)

                        if (statusResponse == null) {
                            _workflowStatus.postValue(null)
                            break
                        }

                        when {
                            statusResponse.status.equals("SUCCESS", ignoreCase = true) ||
                                    statusResponse.status.equals("FAILURE", ignoreCase = true) -> {
                                val resultResponse = NiceBuildSdk.getWorkflowResult(workflowId)
                                if (statusResponse.status.equals("SUCCESS", ignoreCase = true)) {
                                    _workflowResult.postValue(resultResponse)
                                }
                                break
                            }

                            statusResponse.status.equals("PROGRESS", ignoreCase = true) ||
                                    statusResponse.status.equals("PENDING", ignoreCase = true) -> {
                                _workflowStatus.postValue(statusResponse)
                                delay(5_000L)
                            }

                            else -> {
                                _workflowStatus.postValue(statusResponse)
                                break
                            }
                        }
                    }
                }
            } catch (e: TimeoutCancellationException) {
                val timeoutResponse = WorkflowStatusResponse(
                    id = workflowId,
                    status = "TIMEOUT",
                    totalTasks = 0,
                    completedTasks = 0,
                    startTime = 0,
                    updateTime = 0,
                    endTime = 0
                )
                _workflowStatus.postValue(timeoutResponse)
            }
        }
    }

    fun loadWifiList() {
        viewModelScope.launch(Dispatchers.IO) {
            val cachedList = WifiCacheManager.getWifiListFromCache(appContext)
            _wifiList.postValue(cachedList.sortedBy { it.getSSID() })

            bleCore.getWifiList { rsp ->
                viewModelScope.launch(Dispatchers.IO) {
                    val newWifiIds = rsp?.list?.map { it.toLong() } ?: emptyList()
                    val cachedWifiIds = cachedList.map { it.getWifiIndex() }

                    val idsToRemove = cachedWifiIds.filter { it !in newWifiIds }
                    if (idsToRemove.isNotEmpty()) {
                        val currentCache = WifiCacheManager.getWifiListFromCache(appContext)
                        currentCache.removeAll { it.getWifiIndex() in idsToRemove }
                        WifiCacheManager.saveWifiListToCache(appContext, currentCache)
                        _wifiList.postValue(currentCache.sortedBy { it.getSSID() })
                    }

                    newWifiIds.forEach { wifiId ->
                        val info = withTimeoutOrNull(3000L) {
                            suspendCoroutine<GetWifiInfoRsp?> { continuation ->
                                bleCore.getWifiInfo(wifiId.toInt()) { infoResult ->
                                    if (continuation.context.isActive) {
                                        continuation.resume(infoResult)
                                    }
                                }
                            }
                        }
                        if (info != null) {
                            WifiCacheManager.addOrUpdateWifiInCache(appContext, info)
                        }
                    }

                    val finalList = WifiCacheManager.getWifiListFromCache(appContext)
                    _wifiList.postValue(finalList.sortedBy { it.getSSID() })
                }
            }
        }
    }

    fun setWifi(
        operation: Int,
        ssid: String,
        pwd: String,
        wifiIndex: Int,
        callback: (Boolean) -> Unit
    ) {
        _isLoading.postValue(true)
        bleManager.setWifi(operation, ssid, pwd, wifiIndex) { success ->
            _isLoading.postValue(false)
            callback(success)
        }
    }

    fun deleteWifi(wifiIndex: Int, callback: (Boolean) -> Unit) {
        _isLoading.postValue(true)
        bleManager.deleteWifi(wifiIndex) { success ->
            _isLoading.postValue(false)
            callback(success)
        }
    }

    fun clearWifiCache() {
        WifiCacheManager.clearCache(appContext)
        _wifiList.postValue(emptyList())
    }
}