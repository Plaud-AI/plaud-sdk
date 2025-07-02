package com.plaud.nicebuild.utils

import android.content.Context
import android.widget.Toast
import com.plaud.nicebuild.R
import com.plaud.nicebuild.ble.BleManager
import sdk.NiceBuildSdk
import sdk.ServerEnvironment
import sdk.models.AppKeyPairEnv

/**
 * Language configuration manager
 * Automatically matches corresponding AppKey, AppSecret and ServerEnvironment based on language code  
 */
object LanguageConfigManager {
    
    /**
     * Language configuration data class
     */
    data class LanguageConfig(
        val appKeyPairEnv: AppKeyPairEnv,
        val serverEnvironment: ServerEnvironment,
        val displayName: String
    )
    
    /**
     * Language configuration mapping table
     */
    private val languageConfigMap = mapOf(
        AppLanguage.CHINESE.code to LanguageConfig(
            appKeyPairEnv = AppKeyPairEnv.CHINA_PROD,
            serverEnvironment = ServerEnvironment.CHINA_PROD,
            displayName = "China Environment"
        ),
        AppLanguage.ENGLISH.code to LanguageConfig(
            appKeyPairEnv = AppKeyPairEnv.OVERSEAS_PROD,
            serverEnvironment = ServerEnvironment.OVERSEAS_PROD,
            displayName = "Overseas Environment"
        )
    )
    
    /**
     * Get configuration based on language code
     */
    fun getConfigForLanguage(languageCode: String): LanguageConfig? {
        return languageConfigMap[languageCode]
    }
    
    /**
     * Apply complete configuration based on language code
     * @param context Context
     * @param languageCode Language code
     * @param bleManager BLE manager instance
     * @return Whether configuration was successfully applied
     */
    fun applyConfigForLanguage(
        context: Context, 
        languageCode: String, 
        bleManager: BleManager
    ): Boolean {
        val config = getConfigForLanguage(languageCode)
        if (config == null) {
            Toast.makeText(
                context, 
                context.getString(R.string.toast_language_config_not_found), 
                Toast.LENGTH_SHORT
            ).show()
            return false
        }
        
        try {
            // 1. Save and apply AppKey configuration
            AppKeyManager.saveAppKeyPair(
                context, 
                config.appKeyPairEnv.appKey, 
                config.appKeyPairEnv.appSecret
            )
            
            // 2. Update BLE manager's AppKey
            bleManager.updateAppKey(
                config.appKeyPairEnv.appKey, 
                config.appKeyPairEnv.appSecret
            )
            
            // 3. Switch server environment
            NiceBuildSdk.switchEnvironment(config.serverEnvironment)
            
            // 4. Show success message
            Toast.makeText(
                context,
                context.getString(R.string.toast_language_config_applied, config.displayName),
                Toast.LENGTH_SHORT
            ).show()
            
            return true
        } catch (e: Exception) {
            Toast.makeText(
                context,
                context.getString(R.string.toast_language_config_apply_failed),
                Toast.LENGTH_SHORT
            ).show()
            return false
        }
    }
    
    /**
     * Get configuration information for current language
     */
    fun getCurrentConfig(context: Context): LanguageConfig? {
        val currentLanguageCode = LocaleHelper.getLanguage(context)
        return getConfigForLanguage(currentLanguageCode)
    }
    
    /**
     * Check if current configuration matches language
     */
    fun isConfigSyncedWithLanguage(context: Context): Boolean {
        val currentLanguageCode = LocaleHelper.getLanguage(context)
        val expectedConfig = getConfigForLanguage(currentLanguageCode) ?: return false
        
        val (currentAppKey, currentAppSecret) = AppKeyManager.getAppKeyPair(context)
        val currentEnvironment = NiceBuildSdk.getCurrentEnvironment()
        
        return currentAppKey == expectedConfig.appKeyPairEnv.appKey &&
               currentAppSecret == expectedConfig.appKeyPairEnv.appSecret &&
               currentEnvironment == expectedConfig.serverEnvironment
    }
} 