package com.plaud.nicebuild

import android.content.Context
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import com.plaud.nicebuild.ble.BleCore
import com.plaud.nicebuild.utils.LocaleHelper
import sdk.permission.PermissionManager
import androidx.navigation.NavController
import androidx.navigation.fragment.NavHostFragment
import com.plaud.nicebuild.viewmodel.MainViewModel

class MainActivity : AppCompatActivity() {
    private val TAG: String = "Plaud App--MainActivity"
    private lateinit var bleManager: BleCore
    private lateinit var permissionManager: PermissionManager
    private lateinit var mainViewModel: MainViewModel
    private lateinit var navController: NavController

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(LocaleHelper.onAttach(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Initialize ViewModel
        mainViewModel = ViewModelProvider(this)[MainViewModel::class.java]

        // Initialize Navigation
        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navController = navHostFragment.navController

        // Initialize BLE Manager
        bleManager = BleCore.getInstance(this)
        permissionManager = PermissionManager(this)

        setupNavigation()

        // Ensure BleCore is initialized which in turn initializes the SDK
        BleCore.getInstance(applicationContext)
    }

    private fun setupNavigation() {
        // ... existing code ...
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        permissionManager.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        ) { granted ->
            // Handle permission request result
        }
    }
}
