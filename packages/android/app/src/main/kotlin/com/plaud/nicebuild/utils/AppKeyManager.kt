package com.plaud.nicebuild.utils

import android.content.Context
import android.content.SharedPreferences

object AppKeyManager {
    private const val PREFS_NAME = "app_key_prefs"
    private const val KEY_APP_KEY = "app_key"
    private const val KEY_APP_SECRET = "app_secret"

    private fun getPreferences(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveAppKeyPair(context: Context, appKey: String, appSecret: String) {
        val editor = getPreferences(context).edit()
        editor.putString(KEY_APP_KEY, appKey)
        editor.putString(KEY_APP_SECRET, appSecret)
        editor.apply()
    }

    fun getAppKey(context: Context): String? {
        return getPreferences(context).getString(KEY_APP_KEY, null)
    }

    fun getAppSecret(context: Context): String? {
        return getPreferences(context).getString(KEY_APP_SECRET, null)
    }

    fun getAppKeyPair(context: Context): Pair<String?, String?> {
        val prefs = getPreferences(context)
        val appKey = prefs.getString(KEY_APP_KEY, null)
        val appSecret = prefs.getString(KEY_APP_SECRET, null)
        return Pair(appKey, appSecret)
    }
} 