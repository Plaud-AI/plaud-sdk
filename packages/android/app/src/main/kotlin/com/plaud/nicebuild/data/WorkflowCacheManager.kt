package com.plaud.nicebuild.data

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import sdk.penblesdk.entity.BleFile

data class WorkflowInfo(
    val fileId: String,
    var workflowId: String? = null
)

object WorkflowCacheManager {

    private const val PREFS_NAME = "workflow_cache"
    private val gson = Gson()

    private fun getSharedPreferences(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun saveFileId(context: Context, bleFile: BleFile, fileId: String) {
        // First, get the existing info to see if there's an old workflowId to clean up.
        val existingInfo = getWorkflowInfo(context, bleFile)

        // When a file is (re-)uploaded, we get a new fileId, and should start fresh.
        val newInfo = WorkflowInfo(fileId = fileId, workflowId = null)

        val editor = getSharedPreferences(context).edit()
        editor.putString(bleFile.sessionId.toString(), gson.toJson(newInfo))

        // If there was an old workflowId, clear its associated summary.
        existingInfo?.workflowId?.let { oldWorkflowId ->
            if (oldWorkflowId.isNotBlank()) {
                editor.remove("summary_$oldWorkflowId")
            }
        }

        editor.apply()
    }

    fun saveWorkflowId(context: Context, fileId: String, workflowId: String) {
        val prefs = getSharedPreferences(context)
        val allEntries = prefs.all
        for ((key, value) in allEntries) {
            try {
                val info = gson.fromJson(value as String, WorkflowInfo::class.java)
                if (info.fileId == fileId) {
                    info.workflowId = workflowId
                    prefs.edit().putString(key, gson.toJson(info)).apply()
                    return // Found and updated
                }
            } catch (e: Exception) {
                // Ignore malformed entries
            }
        }
    }
    
    fun getWorkflowInfo(context: Context, bleFile: BleFile): WorkflowInfo? {
        val json = getSharedPreferences(context).getString(bleFile.sessionId.toString(), null)
        return if (json != null) {
            gson.fromJson(json, WorkflowInfo::class.java)
        } else {
            null
        }
    }

    fun clearAll(context: Context) {
        getSharedPreferences(context).edit().clear().apply()
    }

    fun saveSummary(context: Context, workflowId: String, summary: String) {
        val editor = getSharedPreferences(context).edit()
        editor.putString("summary_$workflowId", summary)
        editor.apply()
    }

    fun getSummary(context: Context, workflowId: String): String? {
        return getSharedPreferences(context).getString("summary_$workflowId", null)
    }
} 