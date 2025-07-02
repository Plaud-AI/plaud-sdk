package com.plaud.nicebuild.ui

import android.app.AlertDialog
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.navigation.fragment.findNavController
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText
import com.plaud.nicebuild.viewmodel.MainViewModel
import com.plaud.nicebuild.R
import com.plaud.nicebuild.ble.BleCore
import android.widget.TextView
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import sdk.penblesdk.entity.bean.ble.response.GetWifiInfoRsp

class DeviceWifiSettingFragment : Fragment() {
    private lateinit var wifiNameEdit: TextInputEditText
    private lateinit var wifiPwdEdit: TextInputEditText
    private lateinit var saveButton: MaterialButton
    private lateinit var testButton: MaterialButton
    private lateinit var forgetButton: MaterialButton
    private var wifiIndex = -1
    private var isAdd = true
    private var testWasInitiated = false
    private var loadingDialog: AlertDialog? = null
    private val testHandler = Handler(Looper.getMainLooper())
    private val mainViewModel: MainViewModel by lazy {
        ViewModelProvider(requireActivity()).get(MainViewModel::class.java)
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_device_wifi_setting, container, false)
        wifiNameEdit = view.findViewById(R.id.et_wifi_name)
        wifiPwdEdit = view.findViewById(R.id.et_wifi_pwd)
        saveButton = view.findViewById(R.id.btn_save)
        testButton = view.findViewById(R.id.btn_test)
        forgetButton = view.findViewById(R.id.btn_forget)

        view.findViewById<MaterialToolbar>(R.id.toolbar).setOnClickListener {
            findNavController().popBackStack()
        }

        return view
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        wifiIndex = arguments?.getInt("wifiIndex", -1) ?: -1
        val defaultSsid = arguments?.getString("defaultSsid") ?: ""
        isAdd = (wifiIndex == -1)
        
        if (isAdd) {
            // Add mode
            wifiNameEdit.setText(defaultSsid)
            forgetButton.visibility = View.GONE
            // Use a temporary unique ID
            wifiIndex = (System.currentTimeMillis() / 1000).toInt()
        } else {
            // Edit mode
            forgetButton.visibility = View.VISIBLE
            BleCore.getInstance(requireContext()).getWifiInfo(wifiIndex) { info ->
                wifiNameEdit.setText(info?.getSSID() ?: "")
                wifiPwdEdit.setText(info?.getPwd() ?: "")
            }
        }
        
        saveButton.setOnClickListener {
            val ssid = wifiNameEdit.text.toString()
            val pwd = wifiPwdEdit.text.toString()
            if (ssid.isBlank()) {
                Toast.makeText(context, getString(R.string.toast_wifi_ssid_cannot_be_empty), Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val existingWifi = mainViewModel.wifiList.value?.find { it.getSSID() == ssid }
            if (isAdd && existingWifi != null) {
                showOverwriteDialog(ssid, pwd, existingWifi)
            } else {
                val operation = if (isAdd) 1 else 2 // 1 for add, 2 for modify
                mainViewModel.setWifi(operation, ssid, pwd, wifiIndex) { success ->
                    if (success) {
                        Toast.makeText(context, getString(R.string.toast_save_successful), Toast.LENGTH_SHORT).show()
                        findNavController().popBackStack()
                    } else {
                        Toast.makeText(context, getString(R.string.toast_save_failed), Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }

        testButton.setOnClickListener {
            if (isAdd) {
                Toast.makeText(context, getString(R.string.toast_save_before_test), Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            testWifiConnection()
        }

        forgetButton.setOnClickListener {
            if (!isAdd) {
                mainViewModel.deleteWifi(wifiIndex) { success ->
                    if (success) {
                        Toast.makeText(context, getString(R.string.toast_deleted), Toast.LENGTH_SHORT).show()
                        findNavController().popBackStack()
                    } else {
                        Toast.makeText(context, getString(R.string.toast_delete_failed), Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
    }

    private fun showOverwriteDialog(ssid: String, pwd: String, existingWifi: GetWifiInfoRsp) {
        val dialogView = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_wifi_overwrite, null)
        val dialog = MaterialAlertDialogBuilder(requireContext())
            .setView(dialogView)
            .create()

        dialog.window?.setBackgroundDrawableResource(android.R.color.transparent)

        val messageView = dialogView.findViewById<TextView>(R.id.dialog_message)
        val overwriteButton = dialogView.findViewById<TextView>(R.id.btn_overwrite)
        val cancelButton = dialogView.findViewById<TextView>(R.id.btn_cancel)

        messageView.text = "Wi-Fi named \"$ssid\" already exists. Do you want to overwrite it?"

        overwriteButton.setOnClickListener {
            mainViewModel.setWifi(2, ssid, pwd, existingWifi.getWifiIndex().toInt()) { success ->
                if (success) {
                    Toast.makeText(context, getString(R.string.toast_save_successful), Toast.LENGTH_SHORT).show()
                    findNavController().popBackStack()
                } else {
                    Toast.makeText(context, getString(R.string.toast_save_failed), Toast.LENGTH_SHORT).show()
                }
            }
            dialog.dismiss()
        }

        cancelButton.setOnClickListener {
            dialog.dismiss()
        }

        dialog.show()
    }

    private fun testWifiConnection() {
        showLoadingDialog()
        BleCore.getInstance(requireContext()).testWifiInfo(wifiIndex.toLong()) { rsp ->
            if (rsp == null) {
                dismissLoadingDialog()
                Toast.makeText(context, "Failed to send test command.", Toast.LENGTH_SHORT).show()
                return@testWifiInfo
            }

            // Wait 10 seconds, then reconnect and get result
            testHandler.postDelayed({
                reconnectAndGetTestResult()
            }, 10000) // Wait 10 seconds
        }
    }

    private fun reconnectAndGetTestResult() {
        if (!isAdded) {
            dismissLoadingDialog()
            return
        }

        val device = mainViewModel.currentDevice.value
        if (device == null) {
            dismissLoadingDialog()
            Toast.makeText(context, "Device information not available", Toast.LENGTH_SHORT).show()
            return
        }

        // Reconnect Bluetooth
        BleCore.getInstance(requireContext()).connectDevice(
            device.serialNumber, 
            device.serialNumber
        ) { success, errorCode, errorMessage ->
            if (!isAdded) {
                dismissLoadingDialog()
                return@connectDevice
            }

            if (success) {
                // Get test result after successful connection
                getWifiTestResult()
            } else {
                dismissLoadingDialog()
                Toast.makeText(context, "Failed to reconnect: $errorMessage", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun getWifiTestResult() {
        if (!isAdded) {
            dismissLoadingDialog()
            return
        }

        BleCore.getInstance(requireContext()).testWifiResult(wifiIndex.toLong()) { result ->
            if (!isAdded) {
                dismissLoadingDialog()
                return@testWifiResult
            }

            dismissLoadingDialog()
            val resultCode = result?.result?.toInt()
            
            if (resultCode != null) {
                val resultText = when (resultCode) {
                    0 -> getString(R.string.wifi_test_result_0)
                    1 -> getString(R.string.wifi_test_result_1)
                    2 -> getString(R.string.wifi_test_result_2)
                    3 -> getString(R.string.wifi_test_result_3)
                    4 -> getString(R.string.wifi_test_result_4)
                    255 -> "Test in progress or no result available"
                    else -> getString(R.string.wifi_test_result_unknown, resultCode.toString())
                }
                Toast.makeText(context, getString(R.string.toast_test_result_formatted, resultText), Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(context, "Failed to get test result", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun showLoadingDialog() {
        if (loadingDialog == null) {
            val builder = AlertDialog.Builder(requireContext())
            val dialogView = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_loading, null)
            builder.setView(dialogView)
            builder.setCancelable(true) // Allow cancellation via back button
            loadingDialog = builder.create().apply {
                window?.setBackgroundDrawableResource(android.R.color.transparent)
                // If user cancels dialog, we also return to previous interface
                setOnCancelListener {
                    testHandler.removeCallbacksAndMessages(null)
                }
            }
        }
        loadingDialog?.show()
    }

    private fun dismissLoadingDialog() {
        loadingDialog?.dismiss()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        dismissLoadingDialog() // Ensure dialog is closed when Fragment is destroyed
        testHandler.removeCallbacksAndMessages(null) // Remove all pending callbacks to prevent crashes

        if (testWasInitiated) {
            val device = mainViewModel.currentDevice.value
            if (device != null && !BleCore.getInstance(requireContext()).isConnected()) {
                BleCore.getInstance(requireContext()).connectDevice(device.serialNumber, device.serialNumber) { _, _, _ ->
                    // Reconnect in background, no UI feedback needed
                }
            }
        }
    }
} 