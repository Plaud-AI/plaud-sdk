package com.plaud.nicebuild.ui

import android.Manifest
import android.app.AlertDialog
import android.content.pm.PackageManager
import android.os.Bundle
import android.text.InputType
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.lifecycleScope
import androidx.navigation.fragment.findNavController
import com.plaud.nicebuild.R
import com.google.android.material.button.MaterialButton
import android.util.Log
import com.plaud.nicebuild.utils.LocaleHelper
import com.plaud.nicebuild.utils.AppLanguage
import com.plaud.nicebuild.utils.PermissionUtils
import com.plaud.nicebuild.utils.LanguageConfigManager
import kotlinx.coroutines.launch
import sdk.NiceBuildSdk
import sdk.network.manager.FeatureManager
import android.app.Dialog
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Typeface
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import com.plaud.nicebuild.ble.BleManager
import com.plaud.nicebuild.utils.AppKeyManager
import com.plaud.nicebuild.viewmodel.MainViewModel
import sdk.ServerEnvironment
import sdk.models.AppKeyPairEnv
import androidx.activity.result.contract.ActivityResultContracts

class IntroFragment : Fragment() {
    private val REQUIRED_PERMISSIONS = arrayOf(
        Manifest.permission.BLUETOOTH_SCAN,
        Manifest.permission.BLUETOOTH_CONNECT,
        Manifest.permission.ACCESS_FINE_LOCATION
    )
    private val PERMISSION_KEY = "ble_permissions"
    
    private val mainViewModel: MainViewModel by activityViewModels()
    private lateinit var bleManager: BleManager
    
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.all { it.value }) {
            navigateToDeviceList()
        } else {
            // Toast is shown by PermissionUtils for permanently denied cases.
            // For one-time denial, we just don't navigate.
             Toast.makeText(
                requireContext(),
                getString(R.string.toast_permission_required_to_scan),
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    private fun checkAndRequestPermissions() {
        PermissionUtils.checkAndRequestPermissions(
            requireActivity(),
            REQUIRED_PERMISSIONS,
            requestPermissionLauncher,
            PERMISSION_KEY,
            ::navigateToDeviceList
        )
    }

    private fun navigateToDeviceList() {
        findNavController().navigate(R.id.action_intro_to_deviceList)
    }

    override fun onResume() {
        super.onResume()
        // Check if returning from settings and permissions are now granted
        val allGranted = REQUIRED_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(requireContext(), it) == PackageManager.PERMISSION_GRANTED
        }
        // We don't auto-navigate here. User has to click the button again.
        // This avoids navigating just by switching apps.
        
        // Check if current config is synced with language
        checkAndSyncLanguageConfig()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle physical back button
        requireActivity().onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                requireActivity().finish()
            }
        })
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_intro, container, false)
        bleManager = BleManager.getInstance(requireContext())

        val btnStart = view.findViewById<MaterialButton>(R.id.btn_start_scan)
        btnStart.setOnClickListener {
            checkAndRequestPermissions()
        }

        val btnSelectLanguage = view.findViewById<MaterialButton>(R.id.btn_select_language)
        btnSelectLanguage.setOnClickListener {
            showLanguageSelectionDialog()
        }

        // Removed btnSetAppKey and btnSwitchDomain setup, as these functions are now handled automatically through language selection

//        val tvSdkVersion = view.findViewById<TextView>(R.id.tv_sdk_version)
        // tvSdkVersion.text = getString(R.string.sdk_version_label, NiceBuildSdk.VERSION)

        return view
    }
    
    /**
     * Check and sync language configuration
     * If current configuration doesn't match language, automatically apply corresponding configuration
     */
    private fun checkAndSyncLanguageConfig() {
        if (!LanguageConfigManager.isConfigSyncedWithLanguage(requireContext())) {
            val currentLanguageCode = LocaleHelper.getLanguage(requireContext())
            val config = LanguageConfigManager.getConfigForLanguage(currentLanguageCode)
            if (config != null) {
                LanguageConfigManager.applyConfigForLanguage(
                    requireContext(),
                    currentLanguageCode,
                    bleManager
                )
            }
        }
    }

    private fun showLanguageSelectionDialog() {
        val languages = AppLanguage.values()
        val currentLanguage = AppLanguage.fromCode(LocaleHelper.getLanguage(requireContext()))
        val currentLangName = currentLanguage.displayName

        val options = languages.associate { language ->
            language.displayName to {
                val currentLanguageCode = LocaleHelper.getLanguage(requireContext())
                if (currentLanguageCode != language.code) {
                    // 1. Switch language
                    LocaleHelper.setLocale(requireContext(), language.code)
                    
                    // 2. Automatically apply corresponding configuration (AppKey, AppSecret, ServerEnvironment)
                    val success = LanguageConfigManager.applyConfigForLanguage(
                        requireContext(),
                        language.code,
                        bleManager
                    )
                    
                    // 3. Recreate Activity to apply language changes
                    if (success) {
                        requireActivity().recreate()
                    }
                } else {
                    Toast.makeText(requireContext(), getString(R.string.toast_already_this_language), Toast.LENGTH_SHORT).show()
                }
            }
        }

        showOptionSelectionDialog(options, currentLangName)
    }
    
    private fun showOptionSelectionDialog(options: Map<String, () -> Unit>, currentSelection: String?) {
        val dialog = Dialog(requireContext())
        dialog.setContentView(R.layout.dialog_language_selection)
        dialog.window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        dialog.window?.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        dialog.window?.setGravity(Gravity.BOTTOM)

        val optionsContainer = dialog.findViewById<LinearLayout>(R.id.ll_options_container)
        val btnCancel = dialog.findViewById<TextView>(R.id.btn_cancel)

        options.forEach { (text, action) ->
            val optionView = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_item_selection, optionsContainer, false) as TextView
            optionView.text = text
            
            if (text == currentSelection) {
                optionView.typeface = Typeface.DEFAULT_BOLD
                optionView.append("  ✓")
            }

            optionView.setOnClickListener {
                action.invoke()
                dialog.dismiss()
            }
            optionsContainer.addView(optionView)
        }

        btnCancel.setOnClickListener { dialog.dismiss() }
        dialog.show()
    }
} 