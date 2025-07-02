package com.plaud.nicebuild.data

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import sdk.penblesdk.entity.bean.ble.response.GetWifiInfoRsp
import java.util.Collections

object WifiCacheManager {

    private const val PREFS_NAME = "wifi_cache_prefs"
    private const val KEY_WIFI_LIST = "wifi_list"
    private val gson = Gson()

    private fun getSharedPreferences(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getWifiListFromCache(context: Context): MutableList<GetWifiInfoRsp> {
        val prefs = getSharedPreferences(context)
        val json = prefs.getString(KEY_WIFI_LIST, null)
        return if (json != null) {
            val type = object : TypeToken<MutableList<GetWifiInfoRsp>>() {}.type
            gson.fromJson(json, type)
        } else {
            mutableListOf()
        }
    }

    fun saveWifiListToCache(context: Context, list: List<GetWifiInfoRsp>) {
        val prefs = getSharedPreferences(context)
        val json = gson.toJson(list)
        prefs.edit().putString(KEY_WIFI_LIST, json).apply()
    }

    fun addOrUpdateWifiInCache(context: Context, wifiInfo: GetWifiInfoRsp) {
        val cachedList = getWifiListFromCache(context)
        val existingIndex = cachedList.indexOfFirst { it.getWifiIndex() == wifiInfo.getWifiIndex() }
        if (existingIndex != -1) {
            cachedList[existingIndex] = wifiInfo
        } else {
            cachedList.add(wifiInfo)
        }
        saveWifiListToCache(context, cachedList)
    }
    
    fun removeWifiFromCache(context: Context, wifiId: Long) {
        val cachedList = getWifiListFromCache(context)
        cachedList.removeAll { it.getWifiIndex() == wifiId }
        saveWifiListToCache(context, cachedList)
    }

    fun clearCache(context: Context) {
        val prefs = getSharedPreferences(context)
        prefs.edit().remove(KEY_WIFI_LIST).apply()
    }
} 