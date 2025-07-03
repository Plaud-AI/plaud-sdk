package com.plaud.nicebuild.utils

import android.os.Environment
import sdk.penblesdk.entity.BleFile
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object FileHelper {
    fun getOpusFile(file: BleFile): File {
        val sdf = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault())
        val timestamp = sdf.format(Date(file.sessionId * 1000L))
        val outputDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
        val targetDir = File(outputDir, "PlaudOpus")
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }
        return File(targetDir, "${timestamp}.opus")
    }
} 