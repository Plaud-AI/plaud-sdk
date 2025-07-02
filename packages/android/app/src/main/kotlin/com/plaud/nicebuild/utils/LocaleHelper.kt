package com.plaud.nicebuild.utils

import android.annotation.TargetApi
import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import android.os.Build
import java.util.Locale

enum class AppLanguage(val code: String, val displayName: String) {
    ENGLISH("en", "English"),
    CHINESE("zh", "Chinese");

    companion object {
        val DEFAULT = ENGLISH
        
        fun fromCode(code: String?): AppLanguage {
            return values().find { it.code == code } ?: DEFAULT
        }
        
        fun getAllCodes(): Array<String> {
            return values().map { it.code }.toTypedArray()
        }
        
        fun getAllDisplayNames(): Array<String> {
            return values().map { it.displayName }.toTypedArray()
        }
    }
    
    fun isDefault(): Boolean = this == DEFAULT
}

object LocaleHelper {

    private const val PREFS_NAME = "app_locale_prefs"
    private const val SELECTED_LANGUAGE = "selected_language"

    fun onAttach(context: Context): Context {
        val lang = getPersistedLocale(context)
        return setLocale(context, lang)
    }

    fun getLanguage(context: Context): String {
        return getPersistedLocale(context)
    }

    fun setLocale(context: Context, language: String?): Context {
        persistLocale(context, language)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            updateResources(context, language)
        } else {
            updateResourcesLegacy(context, language)
        }
    }

    private fun getPersistedLocale(context: Context): String {
        val preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // Use saved language, or default to English if none is set.
        return preferences.getString(SELECTED_LANGUAGE, AppLanguage.DEFAULT.code) ?: AppLanguage.DEFAULT.code
    }

    private fun persistLocale(context: Context, language: String?) {
        val preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = preferences.edit()
        editor.putString(SELECTED_LANGUAGE, language)
        editor.apply()
    }

    @TargetApi(Build.VERSION_CODES.N)
    private fun updateResources(context: Context, language: String?): Context {
        val locale = if (language.isNullOrEmpty()) Locale.getDefault() else Locale(language)
        Locale.setDefault(locale)

        val configuration = context.resources.configuration
        configuration.setLocale(locale)
        configuration.setLayoutDirection(locale)
        return context.createConfigurationContext(configuration)
    }

    @Suppress("DEPRECATION")
    private fun updateResourcesLegacy(context: Context, language: String?): Context {
        val locale = if (language.isNullOrEmpty()) Locale.getDefault() else Locale(language)
        Locale.setDefault(locale)

        val resources: Resources = context.resources
        val configuration: Configuration = resources.configuration
        configuration.locale = locale
        configuration.setLayoutDirection(locale)
        resources.updateConfiguration(configuration, resources.displayMetrics)
        return context
    }
} 