package com.plaud.nicebuild.utils

import android.content.Context
import android.media.*
import android.os.Environment
import android.util.Log
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

class MP3Converter private constructor() {

    private val isConverting = AtomicBoolean(false)
    private var mediaCodec: MediaCodec? = null
    private var mediaMuxer: MediaMuxer? = null
    private var trackIndex = -1
    private var muxerStarted = false
    private var presentationTimeUs = 0L

    companion object {
        private const val TAG = "MP3Converter"
        private const val SAMPLE_RATE = 16000
        private const val CHANNELS = 1
        private const val BIT_RATE = 32000
        private const val TIMEOUT_US = 10000L

        @Volatile
        private var instance: MP3Converter? = null

        fun getInstance(): MP3Converter {
            return instance ?: synchronized(this) {
                instance ?: MP3Converter().also { instance = it }
            }
        }
    }

    private fun getPublicStorageDir(): File {
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "MP3Converter")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    fun startNewConversion(fileName: String): File? {
        if (!isConverting.compareAndSet(false, true)) {
            Log.w(TAG, "Another conversion is in progress, new conversion request ignored.")
            return null
        }
        Log.d(TAG, "Starting new conversion: $fileName")
        presentationTimeUs = 0L

        val saveDir = getPublicStorageDir()
        val outputFile = File(saveDir, fileName)

        try {
            // Initialize MediaCodec
            val mimeType = MediaFormat.MIMETYPE_AUDIO_AAC
            val format = MediaFormat.createAudioFormat(mimeType, SAMPLE_RATE, CHANNELS).apply {
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 4096) // Set maximum input size
                setInteger(MediaFormat.KEY_AAC_ENCODED_TARGET_LEVEL, 2) // Set AAC encoding target level
                setInteger(MediaFormat.KEY_AAC_DRC_TARGET_REFERENCE_LEVEL, 64) // Set DRC target reference level
            }
            mediaCodec = MediaCodec.createEncoderByType(mimeType).apply {
                configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                start()
            }

            // Initialize MediaMuxer
            mediaMuxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            muxerStarted = false
            trackIndex = -1

            Log.d(TAG, "Conversion initialization successful, output file: ${outputFile.absolutePath}")
            return outputFile
        } catch (e: IOException) {
            Log.e(TAG, "Failed to initialize conversion", e)
            releaseResources()
            return null
        }
    }

    fun feedInput(data: ByteArray) {
        if (!isConverting.get()) return

        try {
            val inputBufferId = mediaCodec?.dequeueInputBuffer(TIMEOUT_US)
            if (inputBufferId != null && inputBufferId >= 0) {
                val inputBuffer = mediaCodec?.getInputBuffer(inputBufferId)
                inputBuffer?.clear()
                inputBuffer?.put(data)
                
                val pts = presentationTimeUs
                // Correct timestamp calculation
                presentationTimeUs += (data.size * 1_000_000L) / (SAMPLE_RATE * CHANNELS * 2)

                mediaCodec?.queueInputBuffer(inputBufferId, 0, data.size, pts, 0)
            }
            drainOutput()
        } catch (e: Exception) {
            Log.e(TAG, "Error processing input data", e)
            releaseResources()
        }
    }

    fun finishConversion() {
        if (!isConverting.get()) return

        try {
            // Signal end of stream
            val inputBufferId = mediaCodec?.dequeueInputBuffer(TIMEOUT_US)
            if (inputBufferId != null && inputBufferId >= 0) {
                mediaCodec?.queueInputBuffer(inputBufferId, 0, 0, presentationTimeUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            }
            drainOutput() // Drain any remaining output
        } catch (e: Exception) {
            Log.e(TAG, "Error finishing conversion", e)
        } finally {
            releaseResources()
            Log.d(TAG, "Conversion completed, resources released.")
        }
    }

    private fun drainOutput() {
        val bufferInfo = MediaCodec.BufferInfo()
        while (true) {
            val outputBufferId = mediaCodec?.dequeueOutputBuffer(bufferInfo, TIMEOUT_US) ?: break
            if (outputBufferId == MediaCodec.INFO_TRY_AGAIN_LATER) {
                break
            } else if (outputBufferId == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                if (!muxerStarted) {
                    val newFormat = mediaCodec?.outputFormat
                    if (newFormat != null) {
                        trackIndex = mediaMuxer?.addTrack(newFormat) ?: -1
                        mediaMuxer?.start()
                        muxerStarted = true
                    }
                }
            } else if (outputBufferId >= 0) {
                val encodedData = mediaCodec?.getOutputBuffer(outputBufferId)
                if (encodedData != null) {
                    if (bufferInfo.size != 0 && muxerStarted) {
                        // Adjust ByteBuffer values to match BufferInfo
                        encodedData.position(bufferInfo.offset)
                        encodedData.limit(bufferInfo.offset + bufferInfo.size)
                        mediaMuxer?.writeSampleData(trackIndex, encodedData, bufferInfo)
                    }
                    mediaCodec?.releaseOutputBuffer(outputBufferId, false)
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        break
                    }
                }
            }
        }
    }

    private fun releaseResources() {
        try {
            mediaCodec?.stop()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop MediaCodec", e)
        }
        try {
            mediaCodec?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release MediaCodec", e)
        }
        mediaCodec = null

        try {
            if (muxerStarted) {
                mediaMuxer?.stop()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop MediaMuxer", e)
        }
        try {
            mediaMuxer?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release MediaMuxer", e)
        }
        mediaMuxer = null
        muxerStarted = false

        isConverting.set(false)
    }
}