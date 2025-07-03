package com.plaud.nicebuild.utils

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.util.Log
import sdk.penblesdk.viocedata.creator.VoiceDataCreatorFactory
import java.io.File
import java.io.IOException
import java.io.RandomAccessFile
import java.util.concurrent.Executors
import kotlin.math.min

class OpusPlayer(private val listener: PlayerStateListener) {

    private val TAG = "OpusPlayer"

    private var audioTrack: AudioTrack? = null
    private var playerExecutor = Executors.newSingleThreadExecutor()
    private var isPlaying = false
    private var isPaused = false

    private var currentFilePath: String? = null
    private var totalDurationMillis: Long = 0
    private var currentPositionMillis: Long = 0

    private var fileAccess: RandomAccessFile? = null
    private val pcmBufferSize = 4096

    interface PlayerStateListener {
        fun onProgress(currentPosition: Int, totalDuration: Int)
        fun onCompleted()
        fun onError(message: String)
        fun onPrepared(duration: Int)
    }

    fun play(file: File) {
        if (isPlaying) {
            stop()
        }
        currentFilePath = file.absolutePath
        playerExecutor.submit {
            try {
                preparePlayer(file)
                loopAndPlay()
            } catch (e: Exception) {
                Log.e(TAG, "Playback error", e)
                listener.onError("Playback failed: ${e.message}")
                release()
            }
        }
    }

    private fun preparePlayer(file: File) {
        // Opus is 16kHz, mono
        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_OUT_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)

        audioTrack = AudioTrack(
            AudioManager.STREAM_MUSIC,
            sampleRate,
            channelConfig,
            audioFormat,
            bufferSize,
            AudioTrack.MODE_STREAM
        )

        // Crude way to estimate duration. A proper implementation might read metadata.
        // 16000 samples/sec * 2 bytes/sample (16-bit) = 32000 bytes/sec for PCM.
        // Opus is variable bitrate, but we can make a rough guess, e.g., 32kbps -> 4000 bytes/sec
        // A more accurate way is needed if the file doesn't have a fixed structure.
        // For now, let's assume a rough compression ratio of 8:1 for duration estimation.
        totalDurationMillis = (file.length() / 4000) * 1000
        
        fileAccess = RandomAccessFile(file, "r")
        isPlaying = true
        isPaused = false

        listener.onPrepared(totalDurationMillis.toInt())
    }

    private fun loopAndPlay() {
        val voiceDataCreator = VoiceDataCreatorFactory.newOpusToPcm()
        val file = File(currentFilePath!!)
        val packageSize = 320 // A common Opus frame size processed at once
        val buffer = ByteArray(packageSize)
        var bytesRead: Int

        audioTrack?.play()

        voiceDataCreator.setProcessDataCallBack { pcmData, _ ->
            audioTrack?.write(pcmData, 0, pcmData.size)
        }.setFinishCallBack {
            if (isPlaying) {
                 listener.onCompleted()
            }
            release()
        }

        while (isPlaying) {
            while (isPaused) {
                Thread.sleep(100)
            }

            bytesRead = fileAccess?.read(buffer) ?: -1
            if (bytesRead <= 0) {
                voiceDataCreator.flush()
                break
            }

            currentPositionMillis = (fileAccess?.filePointer ?: 0) * totalDurationMillis / file.length()
            listener.onProgress(currentPositionMillis.toInt(), totalDurationMillis.toInt())
            
            val readData = if (bytesRead < packageSize) buffer.copyOf(bytesRead) else buffer
            voiceDataCreator.receiveVoiceData(readData, 0)
        }
        voiceDataCreator.flush()
    }

    fun pause() {
        if (isPlaying && !isPaused) {
            isPaused = true
            audioTrack?.pause()
        }
    }

    fun resume() {
        if (isPlaying && isPaused) {
            isPaused = false
            audioTrack?.play()
        }
    }

    fun stop() {
        if (isPlaying) {
            isPlaying = false
        }
        playerExecutor.submit {
            release()
        }
    }

    fun seekTo(positionMillis: Int) {
        if (fileAccess != null) {
            val fileLength = fileAccess!!.length()
            val newFilePos = (positionMillis.toLong() * fileLength) / totalDurationMillis
            try {
                fileAccess?.seek(newFilePos)
                currentPositionMillis = positionMillis.toLong()
            } catch (e: IOException) {
                Log.e(TAG, "Seek failed", e)
            }
        }
    }

    private fun release() {
        isPlaying = false
        isPaused = false
        try {
            audioTrack?.stop()
            audioTrack?.release()
            audioTrack = null
            fileAccess?.close()
            fileAccess = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing resources", e)
        }
    }
} 