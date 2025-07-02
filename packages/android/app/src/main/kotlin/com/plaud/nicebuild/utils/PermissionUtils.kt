package com.plaud.nicebuild.utils

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.widget.Toast
import androidx.activity.result.ActivityResultLauncher
import androidx.appcompat.app.AlertDialog
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.plaud.nicebuild.R

object PermissionUtils {

    // Helper to check if it's the first time requesting a specific permission group
    private fun isFirstRequest(context: Context, permissionKey: String): Boolean {
        val prefs = context.getSharedPreferences("PermissionPrefs", Context.MODE_PRIVATE)
        return prefs.getBoolean(permissionKey, true)
    }

    private fun setFirstRequest(context: Context, permissionKey: String, isFirst: Boolean) {
        val prefs = context.getSharedPreferences("PermissionPrefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean(permissionKey, isFirst).apply()
    }
    
    fun checkAndRequestPermissions(
        activity: Activity,
        permissions: Array<String>,
        launcher: ActivityResultLauncher<Array<String>>,
        permissionKey: String,
        onAllGranted: () -> Unit
    ) {
        val permissionsToRequest = permissions.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }.toTypedArray()

        if (permissionsToRequest.isEmpty()) {
            onAllGranted()
            return
        }

        // Check for permanently denied permissions
        val permanentlyDenied = permissionsToRequest.any { permission ->
            !isFirstRequest(activity, permissionKey) && !ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
        }

        if (permanentlyDenied) {
            // Show toast and guide user to settings
            Toast.makeText(
                activity,
                R.string.toast_permission_required_settings,
                Toast.LENGTH_LONG
            ).show()
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", activity.packageName, null))
            activity.startActivity(intent)
        } else {
            // Request permissions
            launcher.launch(permissionsToRequest)
            setFirstRequest(activity, permissionKey, false)
        }
    }
} 