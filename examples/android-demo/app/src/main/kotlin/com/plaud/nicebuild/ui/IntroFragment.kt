package com.plaud.nicebuild.ui

import android.Manifest
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ImageButton
import android.widget.ProgressBar
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.TextView
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

    // Long press handler for language selection
    private val longPressHandler = Handler(Looper.getMainLooper())
    private var longPressRunnable: Runnable? = null
    private val LONG_PRESS_DURATION = 5000L // 5 seconds

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.all { it.value }) {
            navigateToDeviceList()
        } else {
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
        val allGranted = REQUIRED_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(requireContext(), it) == PackageManager.PERMISSION_GRANTED
        }

        checkAndSyncLanguageConfig()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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

        val btnSetAppKey = view.findViewById<MaterialButton>(R.id.btn_set_app_key)
        btnSetAppKey.setOnClickListener {
            showAppKeySettingDialog()
        }

        // Set up long press on title for language selection
        val tvTitle = view.findViewById<TextView>(R.id.tv_title)
        setupLongPressLanguageSelection(tvTitle)

        // Set up privacy policy link
        val tvPrivacyPolicy = view.findViewById<TextView>(R.id.tv_privacy_policy)
        tvPrivacyPolicy.setOnClickListener {
            openPrivacyPolicy()
        }

        return view
    }

    private fun setupLongPressLanguageSelection(titleView: TextView) {
        titleView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    longPressRunnable = Runnable {
                        showLanguageSelectionDialog()
                    }
                    longPressHandler.postDelayed(longPressRunnable!!, LONG_PRESS_DURATION)
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    longPressRunnable?.let {
                        longPressHandler.removeCallbacks(it)
                    }
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    // Cancel long press if finger moves too much
                    if (event.x < 0 || event.y < 0 ||
                        event.x > titleView.width || event.y > titleView.height) {
                        longPressRunnable?.let {
                            longPressHandler.removeCallbacks(it)
                        }
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun showAppKeySettingDialog() {
        val currentLanguageCode = LocaleHelper.getLanguage(requireContext())
        val config = LanguageConfigManager.getConfigForLanguage(currentLanguageCode)

        // Determine what to show in the dialog
        val (currentAppKey, currentAppSecret) = AppKeyManager.getAppKeyPair(requireContext())
        val hasManuallySet = AppKeyManager.hasManuallySetAppKey(requireContext())

        val defaultAppKey = config?.appKeyPairEnv?.appKey ?: ""
        val defaultAppSecret = config?.appKeyPairEnv?.appSecret ?: ""

        // If user hasn't manually set, show default values
        // If user has manually set, show their cached values
        val displayAppKey = if (hasManuallySet) currentAppKey ?: "" else defaultAppKey
        val displayAppSecret = if (hasManuallySet) currentAppSecret ?: "" else defaultAppSecret

        val dialogView = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_set_app_key, null)
        val etAppKey = dialogView.findViewById<TextInputEditText>(R.id.et_app_key)
        val etAppSecret = dialogView.findViewById<TextInputEditText>(R.id.et_app_secret)

        etAppKey.setText(displayAppKey)
        etAppSecret.setText(displayAppSecret)

        MaterialAlertDialogBuilder(requireContext())
            .setTitle(getString(R.string.dialog_title_set_app_key))
            .setView(dialogView)
            .setPositiveButton(getString(R.string.dialog_btn_set)) { _, _ ->
                val appKey = etAppKey.text?.toString()?.trim() ?: ""
                val appSecret = etAppSecret.text?.toString()?.trim() ?: ""

                if (appKey.isNotEmpty() && appSecret.isNotEmpty()) {
                    AppKeyManager.saveAppKeyPair(requireContext(), appKey, appSecret)
                    bleManager.updateAppKey(appKey, appSecret)
                    Toast.makeText(
                        requireContext(),
                        getString(R.string.toast_app_key_set_success),
                        Toast.LENGTH_SHORT
                    ).show()
                } else {
                    Toast.makeText(
                        requireContext(),
                        getString(R.string.toast_app_key_empty),
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
            .setNegativeButton(getString(R.string.dialog_btn_cancel), null)
            .show()
    }

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
                    LocaleHelper.setLocale(requireContext(), language.code)

                    val success = LanguageConfigManager.applyConfigForLanguage(
                        requireContext(),
                        language.code,
                        bleManager
                    )

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

    private fun openPrivacyPolicy() {
        showPrivacyPolicyDialog()
    }

    private fun showPrivacyPolicyDialog() {
        val dialog = Dialog(requireContext())
        dialog.setContentView(R.layout.dialog_privacy_policy)
        
        // Set dialog to full screen with iOS-style presentation
        dialog.window?.setLayout(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        
        // Remove default dialog styling for clean iOS look
        dialog.window?.setBackgroundDrawableResource(android.R.color.transparent)
        
        val webView = dialog.findViewById<WebView>(R.id.webview_privacy_policy)
        val loadingContainer = dialog.findViewById<LinearLayout>(R.id.loading_container)
        val btnClose = dialog.findViewById<TextView>(R.id.btn_close)
        
        // Setup WebView with iOS-style behavior
        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                super.onPageStarted(view, url, favicon)
                loadingContainer.visibility = View.VISIBLE
            }
            
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                loadingContainer.visibility = View.GONE
            }
            
            override fun onReceivedError(
                view: WebView?,
                errorCode: Int,
                description: String?,
                failingUrl: String?
            ) {
                super.onReceivedError(view, errorCode, description, failingUrl)
                loadingContainer.visibility = View.GONE
                
                // Show iOS-style error message
                Toast.makeText(
                    requireContext(),
                    "Unable to load content",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
        
        // Configure WebView settings for optimal iOS-like experience
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            loadWithOverviewMode = true
            useWideViewPort = true
            builtInZoomControls = false
            displayZoomControls = false
            
            // iOS-like text rendering
            textZoom = 100
            minimumFontSize = 12
            
            // Smooth scrolling
            setSupportZoom(false)
        }
        
        // Load privacy policy URL
        val privacyPolicyUrl = getString(R.string.privacy_policy_url)
        webView.loadUrl(privacyPolicyUrl)
        
        // Setup close button with iOS-style interaction
        btnClose.setOnClickListener {
            dialog.dismiss()
        }
        
        // Handle back button in dialog
        dialog.setOnKeyListener { _, keyCode, event ->
            if (keyCode == android.view.KeyEvent.KEYCODE_BACK && event.action == android.view.KeyEvent.ACTION_UP) {
                if (webView.canGoBack()) {
                    webView.goBack()
                    true
                } else {
                    dialog.dismiss()
                    true
                }
            } else {
                false
            }
        }
        
        dialog.show()
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

    override fun onDestroy() {
        super.onDestroy()
        longPressRunnable?.let {
            longPressHandler.removeCallbacks(it)
        }
    }
} 