package com.plaud.nicebuild.utils

import android.content.Context
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.File
import java.io.IOException

class AudioPlayer(private val context: Context) {
    private var mediaPlayer: MediaPlayer? = null
    private var currentFile: File? = null
    private var _isPlaying = false
    private var onProgressUpdate: ((Int, Int) -> Unit)? = null
    private var onPlaybackComplete: (() -> Unit)? = null
    private val handler = Handler(Looper.getMainLooper())
    private val progressRunnable = object : Runnable {
        override fun run() {
            mediaPlayer?.let { player ->
                if (_isPlaying) {
                    try {
                        val currentPosition = player.currentPosition
                        val duration = player.duration
                        onProgressUpdate?.invoke(currentPosition, duration)
                        handler.postDelayed(this, 1000)
                    } catch (e: Exception) {
                        Log.e("AudioPlayer", "Error updating progress: ${e.message}")
                        e.printStackTrace()
                        stop()
                    }
                }
            }
        }
    }

    fun play(file: File) {
        try {
            // If already playing, stop first
            stop()
            
            // Check if file exists
            if (!file.exists()) {
                Log.e("AudioPlayer", "File does not exist: ${file.absolutePath}")
                return
            }
            
            // Check file size
            if (file.length() == 0L) {
                Log.e("AudioPlayer", "File is empty: ${file.absolutePath}")
                return
            }
            
            // Create new MediaPlayer
            mediaPlayer = MediaPlayer().apply {
                try {
                    setDataSource(file.absolutePath)
                    prepare()
                    setOnCompletionListener {
                        _isPlaying = false
                        onPlaybackComplete?.invoke()
                    }
                    setOnErrorListener { _, what, extra ->
                        Log.e("AudioPlayer", "MediaPlayer error: what=$what, extra=$extra")
                        stop()
                        true
                    }
                    start()
                } catch (e: Exception) {
                    Log.e("AudioPlayer", "Error initializing MediaPlayer: ${e.message}")
                    e.printStackTrace()
                    release()
                    mediaPlayer = null
                    return@apply
                }
            }
            
            currentFile = file
            _isPlaying = true
            
            // Start progress updates
            handler.post(progressRunnable)
            
        } catch (e: Exception) {
            Log.e("AudioPlayer", "Error playing file: ${e.message}")
            e.printStackTrace()
        }
    }

    fun pause() {
        mediaPlayer?.let { player ->
            if (_isPlaying) {
                try {
                    player.pause()
                    _isPlaying = false
                    handler.removeCallbacks(progressRunnable)
                } catch (e: Exception) {
                    Log.e("AudioPlayer", "Error pausing playback: ${e.message}")
                    e.printStackTrace()
                    stop()
                }
            }
        }
    }

    fun resume() {
        mediaPlayer?.let { player ->
            if (!_isPlaying) {
                try {
                    player.start()
                    _isPlaying = true
                    handler.post(progressRunnable)
                } catch (e: Exception) {
                    Log.e("AudioPlayer", "Error resuming playback: ${e.message}")
                    e.printStackTrace()
                    stop()
                }
            }
        }
    }

    fun stop() {
        try {
            mediaPlayer?.let { player ->
                if (_isPlaying) {
                    player.stop()
                }
                player.release()
            }
        } catch (e: Exception) {
            Log.e("AudioPlayer", "Error stopping playback: ${e.message}")
            e.printStackTrace()
        } finally {
            mediaPlayer = null
            currentFile = null
            _isPlaying = false
            handler.removeCallbacks(progressRunnable)
        }
    }

    fun seekTo(position: Int) {
        mediaPlayer?.let { player ->
            try {
                player.seekTo(position)
            } catch (e: Exception) {
                Log.e("AudioPlayer", "Error seeking: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    fun setOnProgressUpdateListener(listener: (Int, Int) -> Unit) {
        onProgressUpdate = listener
    }

    fun setOnPlaybackCompleteListener(listener: () -> Unit) {
        onPlaybackComplete = listener
    }

    fun isPlaying(): Boolean = _isPlaying

    fun getCurrentFile(): File? = currentFile

    fun getCurrentPosition(): Int = try {
        mediaPlayer?.currentPosition ?: 0
    } catch (e: Exception) {
        Log.e("AudioPlayer", "Error getting current position: ${e.message}")
        0
    }

    fun getDuration(): Int = try {
        mediaPlayer?.duration ?: 0
    } catch (e: Exception) {
        Log.e("AudioPlayer", "Error getting duration: ${e.message}")
        0
    }
} 