package com.plaud.nicebuild.ui
import android.annotation.SuppressLint
import android.os.Build
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.OnBackPressedCallback
import androidx.fragment.app.Fragment
import com.plaud.nicebuild.R
import com.google.android.material.button.MaterialButton
import android.widget.Toast
import androidx.lifecycle.ViewModelProvider
import com.plaud.nicebuild.viewmodel.MainViewModel
import android.widget.TextView
import com.plaud.nicebuild.ble.BleCore
import com.plaud.nicebuild.ble.BleManager
import sdk.penblesdk.entity.BleDevice
import androidx.navigation.fragment.findNavController
import androidx.core.content.ContextCompat
import org.json.JSONObject
import android.widget.ImageButton
import android.util.Log
import androidx.annotation.RequiresApi
import android.widget.LinearLayout
import android.os.Handler
import android.os.Looper
import sdk.penblesdk.Constants
import android.app.Dialog
import com.google.android.material.materialswitch.MaterialSwitch
import com.google.android.material.button.MaterialButton as MaterialButtonView
import sdk.penblesdk.TntAgent
import sdk.penblesdk.entity.bean.ble.response.FileDataCheckRsp
import sdk.penblesdk.entity.bean.ble.response.FileInfoSyncRsp
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import com.google.android.material.slider.Slider
import androidx.appcompat.widget.SwitchCompat
import android.widget.CompoundButton
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import sdk.NiceBuildSdk
import com.google.android.material.appbar.MaterialToolbar
import android.content.Intent
import android.net.Uri
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import android.Manifest
import android.content.pm.PackageManager
import android.os.Environment
import android.provider.Settings
import com.plaud.nicebuild.utils.PermissionUtils
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.widget.Button

class DeviceFeatureFragment : Fragment() {
    private val TAG: String = "DeviceFeatureFragment"
    private lateinit var tvRecordStatus: TextView
    private lateinit var mainViewModel: MainViewModel
    private lateinit var bleManager: BleManager
    private lateinit var bleCore: BleCore
    private lateinit var currentdevice: BleDevice
    private var isRecording = false
    private var isPaused = false
    private var isExpanded = true
    private val timeoutHandler = Handler(Looper.getMainLooper())
    private var timeoutRunnable: Runnable? = null

    // Views
    private lateinit var deviceInfoContent: View
    private lateinit var btnExpand: ImageButton
    private lateinit var tvSn: TextView
    private lateinit var tvBattery: TextView
    private lateinit var tvStorage: TextView
    private lateinit var layoutFileListEntry: View
    private lateinit var tvFileCountEntry: TextView
    private lateinit var deviceInfoTitleLayout: View
    private lateinit var layoutMicGain: View
    private lateinit var tvMicGainValue: TextView
    private lateinit var switchUdiskMode: SwitchCompat
    private lateinit var btnDisconnect: MaterialButton
    private lateinit var btnUnpair: MaterialButton
    private lateinit var btnRecordControl: MaterialButton
    private lateinit var btnPauseResume: MaterialButton
    private lateinit var btnGetState: MaterialButton
    private lateinit var btnGetFileList: MaterialButton
    private lateinit var btnSetWifiDomain: MaterialButton
    private lateinit var btnWifiCloud: MaterialButton
    private lateinit var btnBindCloud: MaterialButton
    private lateinit var btnUnbindCloud: MaterialButton

    private var uDiskSwitchListener: CompoundButton.OnCheckedChangeListener? = null
    
    // Unified launcher for all permissions
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        // For legacy storage, check if they were granted
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            if (permissions.all { it.value }) {
                navigateToFileList()
            } else {
                Toast.makeText(requireContext(), getString(R.string.toast_storage_permission_required_to_save), Toast.LENGTH_LONG).show()
            }
        }
        // For modern storage, the check is handled in onResume after returning from settings
    }

    // Launcher for modern storage settings (Android >= 11)
    private val requestManageStorageLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        // The result is checked in onResume
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mainViewModel = ViewModelProvider(requireActivity()).get(MainViewModel::class.java)
        bleManager = BleManager.getInstance(requireContext())
        bleCore = BleCore.getInstance(requireContext())
        // Handle physical back button
        requireActivity().onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                bleCore.disconnectDevice()
                mainViewModel.setCurrentDevice(null)
                findNavController().popBackStack()
            }
        })
        updateUiFromState(null)
    }

    @SuppressLint("MissingInflatedId")
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_device_feature, container, false)
        
        // Initialize views
        deviceInfoContent = view.findViewById(R.id.device_info_content)
        btnExpand = view.findViewById(R.id.btn_expand)
        deviceInfoTitleLayout = view.findViewById(R.id.device_info_title_layout)
        tvSn = view.findViewById(R.id.tv_sn)
        tvBattery = view.findViewById(R.id.tv_battery)
        tvStorage = view.findViewById(R.id.tv_storage)
        tvRecordStatus = view.findViewById(R.id.tv_record_status)
        layoutFileListEntry = view.findViewById(R.id.layout_file_list_entry)
        tvFileCountEntry = view.findViewById(R.id.tv_file_count_entry)
        layoutMicGain = view.findViewById(R.id.layout_mic_gain)
        tvMicGainValue = view.findViewById(R.id.tv_mic_gain_value)
        switchUdiskMode = view.findViewById(R.id.switch_udisk_mode)
        
        // Initialize buttons
        btnDisconnect = view.findViewById(R.id.btn_disconnect)
        btnUnpair = view.findViewById(R.id.btn_unpair)
        btnRecordControl = view.findViewById(R.id.btn_record_control)
        btnPauseResume = view.findViewById(R.id.btn_pause_resume)
        btnGetState = view.findViewById(R.id.btn_get_state)
        btnGetFileList = view.findViewById(R.id.btn_get_file_list)
        btnSetWifiDomain = view.findViewById(R.id.btn_set_wifi_domain)
        btnWifiCloud = view.findViewById(R.id.btn_wifi_cloud)
        btnBindCloud = view.findViewById(R.id.btn_bind_cloud)
        btnUnbindCloud = view.findViewById(R.id.btn_unbind_cloud)
        
        return view
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Set status bar color
        activity?.window?.statusBarColor = ContextCompat.getColor(requireContext(), R.color.background_secondary)
        @Suppress("DEPRECATION")
        activity?.window?.decorView?.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR

        val toolbar = view.findViewById<MaterialToolbar>(R.id.toolbar)
        toolbar.setNavigationOnClickListener {
            activity?.onBackPressedDispatcher?.onBackPressed()
        }

        setupDeviceInfoCard()
        setupControls()
        loadDeviceInfo()
        observeViewModel()
    }

    private fun setupDeviceInfoCard() {
        // Create a reusable click listener
        val toggleClickListener = View.OnClickListener {
            isExpanded = !isExpanded
            deviceInfoContent.visibility = if (isExpanded) View.VISIBLE else View.GONE
            btnExpand.rotation = if (isExpanded) 0f else 180f
        }

        // Set listener to both title bar and button
        deviceInfoTitleLayout.setOnClickListener(toggleClickListener)
        btnExpand.setOnClickListener(toggleClickListener)

        // Set initial state
        isExpanded = true
        deviceInfoContent.visibility = View.VISIBLE
        btnExpand.rotation = 0f
    }

    private fun loadDeviceInfo() {
        // Set serial number
        mainViewModel.currentDevice.value?.let { device ->
            currentdevice = device
            tvSn.text = getString(R.string.fragment_device_feature_serial_label, device.serialNumber)
        }

        // Get battery level
        bleCore.getBatteryState { batteryText ->
            requireActivity().runOnUiThread {
                tvBattery.text = getString(R.string.fragment_device_feature_battery_label, batteryText)
                Log.d(TAG, "Battery: $batteryText")
            }
        }
        
        // Get storage space
        bleCore.getStorage(requireContext()) { storageText ->
            requireActivity().runOnUiThread {
                tvStorage.text = getString(R.string.fragment_device_feature_storage_label, storageText)
                Log.d(TAG, "Storage: $storageText")
            }
        }

        // Get file list
        bleCore.getFileList(0) { fileList ->
             if (fileList != null) {
                 mainViewModel.updateFileList(fileList)
             }
        }

        bleManager.getMICGain { gain ->
            activity?.runOnUiThread {
                tvMicGainValue.text = gain.toString()
            }
        }
    }

    private fun setupControls() {
        bleCore.setOnRecordingStateChangeListener { isRecording ->
            this.isRecording = isRecording
            if (!isRecording) {
                isPaused = false
            }
            requireActivity().runOnUiThread {
                updateButtonStates()
            }
        }

        btnDisconnect.setOnClickListener {
            bleCore.disconnectDevice()
            mainViewModel.setCurrentDevice(null)
            findNavController().popBackStack()
        }

        btnUnpair.setOnClickListener {
            bleManager.depairDevice { success ->
                requireActivity().runOnUiThread {
                    if (success) {
                        Toast.makeText(requireContext(), getString(R.string.toast_unbind_successful), Toast.LENGTH_SHORT).show()
                        mainViewModel.setCurrentDevice(null)
                        findNavController().popBackStack()
                    } else {
                        Toast.makeText(requireContext(), getString(R.string.toast_unbind_failed), Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }

        btnRecordControl.setOnClickListener {
            if (isRecording) {
                bleManager.stopRecord { success ->
                    if (success) {
                        bleCore.getDeviceState { state ->
                            updateUiFromState(state)
                        }
                    }
                }
            } else {
                bleManager.startRecord { success ->
                    if (success) {
                        bleCore.getDeviceState { state ->
                            updateUiFromState(state)
                        }
                    }
                }
            }
        }

        btnPauseResume.setOnClickListener {
            val action: (((Boolean) -> Unit)) -> Unit = if (isPaused) {
                bleManager::resumeRecord
            } else {
                bleManager::pauseRecord
            }
            action { success ->
                if (success) {
                    // Refresh state without toast
                    bleCore.getDeviceState { state ->
                        updateUiFromState(state)
                    }
                }
            }
        }

        btnGetState.setOnClickListener {
            bleManager.getDeviceState { state ->
                requireActivity().runOnUiThread {
                    try {
                        val json = JSONObject(state)
                        val stateCode = json.getInt("state")
                        val isPaused = json.getBoolean("isPaused")
                        val sessionId = json.getLong("sessionId")

                        val stateText = when (stateCode.toLong()) {
                            Constants.DEVICE_STATUS_RECORD -> getString(R.string.device_status_idle)
                            Constants.DEVICE_STATUS_RECORDING -> getString(R.string.device_status_recording)
                            else -> getString(R.string.device_status_unknown, stateCode)
                        }

                        val formattedMessage = """
                            ${getString(R.string.dialog_status_label)}: $stateText
                            ${getString(R.string.dialog_paused_label)}: ${if (isPaused) getString(R.string.dialog_yes) else getString(R.string.dialog_no)}
                            ${getString(R.string.dialog_session_id_label)}: $sessionId
                        """.trimIndent()

                        showStatusDialog(formattedMessage)

                    } catch (e: Exception) {
                        Toast.makeText(requireContext(), getString(R.string.toast_parse_state_failed, e.message), Toast.LENGTH_SHORT).show()
                    }
                    updateUiFromState(state)
                }
            }
        }

        btnGetFileList.setOnClickListener {
            bleCore.getFileList(0) { fileList ->
                 if (fileList != null) {
                     mainViewModel.updateFileList(fileList)
                 }
            }
        }

        layoutFileListEntry.setOnClickListener {
            checkAndRequestStoragePermission()
        }

        btnSetWifiDomain.setOnClickListener {
            val domain = "platform.plaud.cn"
            bleManager.setWifiSyncDomain(domain) { success ->
                if (isAdded) { // Ensure fragment is still attached before updating UI
                    requireActivity().runOnUiThread {
                        if (success) {
                            Toast.makeText(
                                requireContext(),
                                getString(R.string.toast_domain_set_successfully),
                                Toast.LENGTH_SHORT
                            ).show()
                        } else {
                            Toast.makeText(
                                requireContext(),
                                getString(R.string.toast_failed_to_set_domain),
                                Toast.LENGTH_SHORT
                            ).show()
                        }
                    }
                }
            }
        }

        layoutMicGain.setOnClickListener {
            showMicGainDialog()
        }

        uDiskSwitchListener = CompoundButton.OnCheckedChangeListener { _, isChecked ->
            bleManager.setUDiskMode(isChecked) { success ->
                if (!success && isAdded) {
                    Toast.makeText(requireContext(), "Failed to set U-Disk Mode", Toast.LENGTH_SHORT)
                        .show()
                    // Revert on failure
                    requireActivity().runOnUiThread {
                        switchUdiskMode.setOnCheckedChangeListener(null)
                        switchUdiskMode.isChecked = !isChecked
                        switchUdiskMode.setOnCheckedChangeListener(uDiskSwitchListener)
                    }
                }
            }
        }
        switchUdiskMode.setOnCheckedChangeListener(uDiskSwitchListener)

        btnWifiCloud.setOnClickListener {
            findNavController().navigate(R.id.action_feature_to_wifiCloud)
        }

        btnBindCloud.setOnClickListener {
            lifecycleScope.launch {
                try {
                     val result = NiceBuildSdk.bindDevice(
                         "test-001",
                         currentdevice.serialNumber,
                         "notepin"
                     )
                      if (isAdded) {
                         val message = if (result!=null) getString(R.string.toast_bind_successful) else getString(R.string.toast_bind_failed)
                          Toast.makeText(requireContext(), message, Toast.LENGTH_SHORT).show()
                      }
                } catch (e: Exception) {
                    if (isAdded) {
                        Toast.makeText(requireContext(), "${getString(R.string.toast_bind_failed)}: ${e.message}", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }

        btnUnbindCloud.setOnClickListener {
            lifecycleScope.launch {
                try {
                     val result = NiceBuildSdk.unbindDevice( "test-001",
                         currentdevice.serialNumber,
                         "notepin")
                      if (isAdded) {
                         val message = if (result!=null) getString(R.string.toast_unbind_successful) else getString(R.string.toast_unbind_failed)
                          Toast.makeText(requireContext(), message, Toast.LENGTH_SHORT).show()
 
                      }
                } catch (e: Exception) {
                    if (isAdded) {
                        Toast.makeText(requireContext(), "${getString(R.string.toast_unbind_failed)}: ${e.message}", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
    }

    @SuppressLint("SetTextI18n")
    private fun showMicGainDialog() {
        if (!isAdded) return

        val dialog = Dialog(requireContext())
        val view = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_set_mic_gain, null)
        dialog.setContentView(view)
        dialog.window?.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        dialog.window?.setBackgroundDrawableResource(android.R.color.transparent)

        val slider = view.findViewById<Slider>(R.id.slider_dialog_mic_gain)
        val valueText = view.findViewById<TextView>(R.id.tv_dialog_mic_gain_value)
        val btnOk = view.findViewById<MaterialButton>(R.id.btn_dialog_ok)
        val btnCancel = view.findViewById<MaterialButton>(R.id.btn_dialog_cancel)

        val initialValue = tvMicGainValue.text.toString().toFloatOrNull() ?: 15f
        slider.value = initialValue
        valueText.text = initialValue.toInt().toString()

        slider.addOnChangeListener { _, value, _ ->
            valueText.text = value.toInt().toString()
        }

        btnCancel.setOnClickListener {
            dialog.dismiss()
        }

        btnOk.setOnClickListener {
            val finalGain = slider.value.toInt()
            bleManager.setMICGain(finalGain) { success ->
                if (isAdded) {
                    requireActivity().runOnUiThread {
                        if (success) {
                            tvMicGainValue.text = finalGain.toString()
                            Toast.makeText(requireContext(), "Mic Gain set to $finalGain", Toast.LENGTH_SHORT).show()
                        } else {
                            Toast.makeText(requireContext(), "Failed to set Mic Gain", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            }
            dialog.dismiss()
        }

        dialog.show()
    }

    private fun showStatusDialog(message: String) {
        if (!isAdded) return

        val dialog = Dialog(requireContext()).apply {
            setContentView(R.layout.dialog_device_status)
            window?.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            window?.setBackgroundDrawableResource(android.R.color.transparent)
        }

        val tvMessage = dialog.findViewById<TextView>(R.id.tv_dialog_message)
        val btnOk = dialog.findViewById<MaterialButtonView>(R.id.btn_dialog_ok)

        tvMessage.text = message
        btnOk.setOnClickListener {
            dialog.dismiss()
        }

        dialog.show()
    }

    private fun observeViewModel() {
        mainViewModel.currentDevice.observe(viewLifecycleOwner) { device ->
            device?.let {
                currentdevice = it
            }
        }
        
        mainViewModel.fileList.observe(viewLifecycleOwner) { fileList ->
            val count = fileList?.size ?: 0
            tvFileCountEntry.text = getString(R.string.fragment_device_feature_files_count, count)
        }
    }

    private fun updateButtonStates() {
        if (isRecording) {
            btnRecordControl.text = getString(R.string.fragment_device_feature_stop_recording)
            btnPauseResume.visibility = View.VISIBLE
            btnPauseResume.isEnabled = true
            if (isPaused) {
                btnPauseResume.text = getString(R.string.fragment_device_feature_resume_recording)
                tvRecordStatus.text = getString(R.string.device_feature_status_paused_state)
                tvRecordStatus.setTextColor(ContextCompat.getColor(requireContext(), R.color.system_blue))
            } else {
                btnPauseResume.text = getString(R.string.fragment_device_feature_pause_recording)
                tvRecordStatus.text = getString(R.string.device_feature_status_recording_state)
                tvRecordStatus.setTextColor(ContextCompat.getColor(requireContext(), R.color.system_red))
            }
        } else {
            btnRecordControl.text = getString(R.string.fragment_device_feature_start_recording)
            btnPauseResume.visibility = View.GONE
            btnPauseResume.isEnabled = false
            tvRecordStatus.text = getString(R.string.device_feature_status_not_recording)
            tvRecordStatus.setTextColor(ContextCompat.getColor(requireContext(), R.color.text_secondary))
        }
    }

    private fun updateUiFromState(state: String?) {
        try {
            val json = state?.let { JSONObject(it) } ?: JSONObject()
            val isRecordingState = json.getInt("state").toLong() == Constants.DEVICE_STATUS_RECORDING
            val isPausedState = json.optBoolean("isPaused", false)
            val isUsbState = json.optInt("privacy", 0) == 0

            this.isRecording = isRecordingState
            this.isPaused = isPausedState
            
            if (isAdded) {
                switchUdiskMode.setOnCheckedChangeListener(null)
                switchUdiskMode.isChecked = isUsbState
                switchUdiskMode.setOnCheckedChangeListener(uDiskSwitchListener)
            }

            updateButtonStates()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse device state JSON", e)
        }
    }

    override fun onResume() {
        super.onResume()
        activity?.window?.statusBarColor = ContextCompat.getColor(requireContext(), R.color.background_secondary)
        @Suppress("DEPRECATION")
        activity?.window?.decorView?.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        
        mainViewModel.currentDevice.value?.let {
            bleCore.getFileList(0) { fileList ->
                 if (fileList != null) {
                     mainViewModel.updateFileList(fileList)
                 }
            }
            // Initial state sync without toast
            bleCore.getDeviceState { state ->
                requireActivity().runOnUiThread {
                    updateUiFromState(state)
                }
            }
        }

        // When returning from settings, re-check the "All files access" permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (Environment.isExternalStorageManager()) {
                 // We don't automatically navigate here, to avoid navigating just by switching apps.
                 // The user needs to click the button again to trigger the check.
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        // Restore default status bar color and appearance
        activity?.window?.statusBarColor = ContextCompat.getColor(requireContext(), R.color.white)
        @Suppress("DEPRECATION")
        activity?.window?.decorView?.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR

        timeoutRunnable?.let { timeoutHandler.removeCallbacks(it) }
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun requestStoragePermission() {
        // ... existing code ...
    }

    // 1. Send file info
    private suspend fun syncAppFileInfoSuspend(type: Int, totalSize: Long): FileInfoSyncRsp? {
        return suspendCoroutine { continuation ->
            TntAgent.getInstant().bleAgent.syncAppFileInfo(type, totalSize, { req ->
                Log.d("DeviceFeatureFragment", "syncAppFileInfoSuspend command sent: [$req]")
            }) { infoRsp ->
                Log.d("DeviceFeatureFragment", "syncAppFileInfoSuspend response received: [$infoRsp]")
                continuation.resume(infoRsp)
            }
        }
    }

    // 2. Send file data
    private suspend fun syncAppFileDataSuspend(type: Int, offset: Long, size: Int, bytes: ByteArray): FileInfoSyncRsp? {
        return suspendCoroutine { continuation ->
            TntAgent.getInstant().bleAgent.syncAppFileData(type, offset, size, bytes, {
                Log.d("DeviceFeatureFragment","syncAppFileDataSuspend command sent: [$it]")
            }) {
                Log.d("DeviceFeatureFragment", "syncAppFileDataSuspend response received: [$it]")
                continuation.resume(it)
            }
        }
    }

    // 3. Send CRC verification
    private suspend fun fileDataCheckSuspend(type: Int, crc: Short): FileDataCheckRsp? {
        return suspendCoroutine { continuation ->
            TntAgent.getInstant().bleAgent.fileDataCheck(type, crc, {
                Log.d("DeviceFeatureFragment","fileDataCheckSuspend command sent: [$it]")
            }) {
                Log.d("DeviceFeatureFragment","fileDataCheckSuspend response received: [$it]")
                continuation.resume(it)
            }
        }
    }

    private fun checkAndRequestStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (Environment.isExternalStorageManager()) {
                navigateToFileList()
            } else {
                showCustomPermissionDialog()
            }
        } else {
            // For legacy storage, use the new unified PermissionUtils
            val permissions = arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)
            PermissionUtils.checkAndRequestPermissions(
                requireActivity(),
                permissions,
                requestPermissionLauncher,
                "storage_permissions",
                ::navigateToFileList
            )
        }
    }
    
    private fun showCustomPermissionDialog() {
        val dialog = Dialog(requireContext())
        dialog.setContentView(R.layout.dialog_custom_permission)
        dialog.window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))

        val btnPositive = dialog.findViewById<Button>(R.id.btn_positive)
        val btnNegative = dialog.findViewById<Button>(R.id.btn_negative)

        btnPositive.setOnClickListener {
            dialog.dismiss()
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:${requireContext().packageName}"))
                requestManageStorageLauncher.launch(intent)
            } catch (e: Exception) {
                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                requestManageStorageLauncher.launch(intent)
            }
        }

        btnNegative.setOnClickListener {
            dialog.dismiss()
        }

        dialog.show()
    }

    private fun navigateToFileList() {
        findNavController().navigate(R.id.action_deviceFeature_to_fileList)
    }
}