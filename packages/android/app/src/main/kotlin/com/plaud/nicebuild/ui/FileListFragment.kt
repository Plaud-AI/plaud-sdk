package com.plaud.nicebuild.ui

import android.Manifest
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageButton
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.appbar.MaterialToolbar
import com.plaud.nicebuild.R
import com.plaud.nicebuild.adapter.FileAdapter
import com.plaud.nicebuild.ble.BleCore
import com.plaud.nicebuild.data.WorkflowCacheManager
import com.plaud.nicebuild.utils.FileHelper
import com.plaud.nicebuild.utils.OpusPlayer
import com.plaud.nicebuild.viewmodel.MainViewModel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import sdk.NiceBuildSdk
import sdk.network.RetrofitClient
import sdk.network.manager.S3UploadManager
import sdk.network.model.SummarizeTaskResult
import sdk.network.model.Task
import sdk.network.model.TranscribeResult
import sdk.penblesdk.entity.BleFile
import java.io.FileOutputStream
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume

class FileListFragment : Fragment(), OpusPlayer.PlayerStateListener {

    private val TAG = "FileListFragment"
    private lateinit var fileAdapter: FileAdapter
    private lateinit var rvFileList: RecyclerView
    private var deviceAddress: String? = null

    private val mainViewModel: MainViewModel by lazy {
        ViewModelProvider(requireActivity()).get(MainViewModel::class.java)
    }
    private val bleManager: BleCore by lazy {
        BleCore.getInstance(requireContext())
    }

    // Audio Player components
    private lateinit var opusPlayer: OpusPlayer
    private lateinit var s3UploadManager: S3UploadManager
    private lateinit var playerContainer: View
    private lateinit var tvPlayerFileName: TextView
    private lateinit var tvPlayerCurrentTime: TextView
    private lateinit var tvPlayerTotalTime: TextView
    private lateinit var playerSeekBar: SeekBar
    private lateinit var btnPlayPause: ImageButton
    private lateinit var btnClosePlayer: ImageButton
    private lateinit var selectionActionsContainer: View
    private lateinit var btnSelectAll: Button
    private lateinit var btnDeleteSelection: Button
    private lateinit var btnUploadSelection: Button
    private lateinit var tvFileCount: TextView
    private lateinit var btnSelect: Button
    
    private var isSelectionMode = false
    private var isPlayerPlaying = false
    private var isDownloading = false

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        return inflater.inflate(R.layout.fragment_file_list, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        opusPlayer = OpusPlayer(this)
        s3UploadManager = S3UploadManager(NiceBuildSdk.apiService)

        val toolbar = view.findViewById<MaterialToolbar>(R.id.toolbar)
        toolbar.setNavigationOnClickListener {
            findNavController().navigateUp()
        }

        // Initialize new header views
        tvFileCount = view.findViewById(R.id.tv_file_count)
        btnSelect = view.findViewById(R.id.btn_select)
        btnSelect.setOnClickListener {
            setSelectionMode(!isSelectionMode)
        }

        // Initialize Player views
        playerContainer = view.findViewById(R.id.player_control_include)
        tvPlayerFileName = view.findViewById(R.id.tv_player_file_name)
        tvPlayerCurrentTime = view.findViewById(R.id.tv_player_current_time)
        tvPlayerTotalTime = view.findViewById(R.id.tv_player_total_time)
        playerSeekBar = view.findViewById(R.id.player_seek_bar)
        btnPlayPause = view.findViewById(R.id.btn_player_play_pause)
        btnClosePlayer = view.findViewById(R.id.btn_close_player)

        // Initialize Selection views
        selectionActionsContainer = view.findViewById(R.id.selection_actions_container)
        btnSelectAll = view.findViewById(R.id.btn_select_all)
        btnDeleteSelection = view.findViewById(R.id.btn_delete_selection)
        btnUploadSelection = view.findViewById(R.id.btn_upload_selection)

        rvFileList = view.findViewById(R.id.rv_file_list)
        setupFileList()
        observeViewModel()
        setupPlayerControls()
        setupSelectionControls()
        updatePlayerUiToDefault()

        // Initial fetch
        bleManager.getFileList(0) { fileList ->
             if (fileList != null) {
                 mainViewModel.updateFileList(fileList.toMutableList())
             }
        }
    }

    private fun setupFileList() {
        fileAdapter = FileAdapter(requireContext()).apply {
            onItemClick = { file, _ ->
                handlePlayClick(file)
            }
            onDownloadClick = { file, position ->
                downloadFile(file, position)
            }
            onUploadClick = { file, position ->
                startUpload(file, position)
            }
            onDeleteLocalClick = { file, position ->
                deleteLocalFile(file, position)
            }
            onSelectionChanged = {
                updateDeleteButtonState()
            }
            onSubmitClickListener = { fileId ->
                mainViewModel.submit(fileId) { workflowId, success, message ->
                    if (success && workflowId != null) {
                        // Save the workflowId and update UI
                        context?.let {
                            WorkflowCacheManager.saveWorkflowId(it, fileId, workflowId)
                            val index = fileAdapter.getFiles().indexOfFirst { f ->
                                WorkflowCacheManager.getWorkflowInfo(it, f)?.fileId == fileId
                            }
                            if (index != -1) {
                                fileAdapter.notifyItemChanged(index)
                            }
                        }
                        
                        Toast.makeText(requireContext(), "Submit request sent. Checking status...", Toast.LENGTH_SHORT).show()
                        mainViewModel.getWorkflowStatus(workflowId)
                    } else {
                        Toast.makeText(requireContext(), "Submit failed: $message", Toast.LENGTH_SHORT).show()
                    }
                }
            }
            onCheckStatusClickListener = { workflowId ->
                Toast.makeText(requireContext(), "Re-checking status...", Toast.LENGTH_SHORT).show()
                mainViewModel.getWorkflowStatus(workflowId)
            }
            onViewSummaryClicked = { summary ->
                SummaryDialogFragment.newInstance(summary).show(childFragmentManager, SummaryDialogFragment.TAG)
            }
        }
        rvFileList.layoutManager = LinearLayoutManager(requireContext())
        rvFileList.adapter = fileAdapter
    }

    private fun observeViewModel() {
        mainViewModel.fileList.observe(viewLifecycleOwner) { files ->
            // Before updating the adapter, check for cached summaries
            context?.let { ctx ->
                files.forEach { bleFile ->
                    val workflowInfo = WorkflowCacheManager.getWorkflowInfo(ctx, bleFile)
                    workflowInfo?.workflowId?.let { workflowId ->
                        val cachedSummary = WorkflowCacheManager.getSummary(ctx, workflowId)
                        if (cachedSummary != null) {
                            bleFile.summaryMarkdown = cachedSummary
                        }
                    }
                }
            }

            fileAdapter.updateFiles(files)
            tvFileCount.text =
                getString(R.string.fragment_device_feature_files_count, files.size)
            updateSelectionTitle()
        }

        mainViewModel.workflowStatus.observe(viewLifecycleOwner) { statusResponse ->
            if (statusResponse != null) {
                // The ViewModel now handles polling and getting the result automatically.
                // We just observe and show the status.
                // The final result will be observed in `workflowResult`.
                when {
                    statusResponse.status.equals("TIMEOUT", ignoreCase = true) -> {
                        Toast.makeText(requireContext(), "Polling timed out after 60 seconds.", Toast.LENGTH_LONG).show()
                    }
                    statusResponse.status.equals("PROGRESS", ignoreCase = true) ||
                    statusResponse.status.equals("PENDING", ignoreCase = true) -> {
                        Toast.makeText(requireContext(), "Workflow Status: ${statusResponse.status}", Toast.LENGTH_SHORT).show()
                    }
                    // SUCCESS is handled by the workflowResult observer
                    statusResponse.status.equals("SUCCESS", ignoreCase = true) -> {
                         Toast.makeText(requireContext(), "Workflow succeeded. Result is available.", Toast.LENGTH_SHORT).show()
                    }
                    else -> { // Handles FAILED or other terminal states
                        Toast.makeText(requireContext(), "Workflow finished with status: ${statusResponse.status}", Toast.LENGTH_LONG).show()
                    }
                }
            } else {
                // This case might be hit if the initial get a null response.
                Toast.makeText(requireContext(), "Failed to get workflow status (network error).", Toast.LENGTH_SHORT).show()
            }
        }

        mainViewModel.workflowResult.observe(viewLifecycleOwner) { resultResponse ->
            if (resultResponse == null) {
                Toast.makeText(requireContext(), "Failed to get workflow result.", Toast.LENGTH_SHORT).show()
                return@observe
            }

            // Correctly find the summary task and extract markdown
            val summaryTask = resultResponse.tasks.find { it.taskType == "ai_summarize" }
            if (summaryTask != null && summaryTask.result is SummarizeTaskResult) {
                val summaryResult = (summaryTask.result as SummarizeTaskResult).result
                val markdown = summaryResult.markdown

                if (markdown.isNullOrBlank()) {
                    Toast.makeText(requireContext(), "Workflow finished, but the summary is empty.", Toast.LENGTH_LONG).show()
                    return@observe
                }

                // Persist the summary
                context?.let { WorkflowCacheManager.saveSummary(it, resultResponse.id, markdown) }

                // Find the BleFile associated with this workflow and update it
                val fileIndex = fileAdapter.getFiles().indexOfFirst {
                    val workflowInfo = WorkflowCacheManager.getWorkflowInfo(requireContext(), it)
                    workflowInfo?.workflowId == resultResponse.id
                }

                if (fileIndex != -1) {
                    val bleFile = fileAdapter.getFiles()[fileIndex]
                    bleFile.summaryMarkdown = markdown
                    fileAdapter.notifyItemChanged(fileIndex)
                    Toast.makeText(requireContext(), "Summary loaded and cached!", Toast.LENGTH_SHORT).show()

                    // Optionally, show the summary dialog immediately
                    SummaryDialogFragment.newInstance(markdown).show(childFragmentManager, SummaryDialogFragment.TAG)
                } else {
                    Log.w(TAG, "Could not find matching file in adapter for workflowId: ${resultResponse.id}")
                }
            } else {
                Toast.makeText(requireContext(), "Summary not found in workflow result.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun handlePlayClick(file: BleFile) {
        if (isSelectionMode) return

        val localFile = FileHelper.getOpusFile(file)
        if (localFile.exists()) {
            playerContainer.visibility = View.VISIBLE
            tvPlayerFileName.text = localFile.name
            opusPlayer.play(localFile)
        } else {
            Toast.makeText(requireContext(), getString(R.string.toast_file_not_downloaded), Toast.LENGTH_SHORT).show()
        }
    }

    private fun setupPlayerControls() {
        btnPlayPause.setOnClickListener {
            if (isPlayerPlaying) {
                opusPlayer.pause()
            } else {
                opusPlayer.resume()
            }
        }

        btnClosePlayer.setOnClickListener {
            opusPlayer.stop()
            updatePlayerUiToDefault()
            playerContainer.visibility = View.GONE
        }

        playerSeekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    opusPlayer.seekTo(progress)
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })

        // Player controls setup
        playerContainer.setOnClickListener { /* Prevents clicks from passing through */ }
    }
    
    private fun updatePlayerUiToDefault() {
        tvPlayerFileName.text = ""
        tvPlayerCurrentTime.text = formatDuration(0)
        tvPlayerTotalTime.text = formatDuration(0)
        playerSeekBar.progress = 0
        btnPlayPause.setImageResource(R.drawable.ic_play)
    }

    private fun formatDuration(milliseconds: Int): String {
        val minutes = TimeUnit.MILLISECONDS.toMinutes(milliseconds.toLong())
        val seconds = TimeUnit.MILLISECONDS.toSeconds(milliseconds.toLong()) - TimeUnit.MINUTES.toSeconds(minutes)
        return String.format("%02d:%02d", minutes, seconds)
    }

    private fun downloadFile(file: BleFile, position: Int) {
        if (isDownloading) {
            Toast.makeText(requireContext(), getString(R.string.toast_another_download_in_progress), Toast.LENGTH_SHORT).show()
            return
        }
        isDownloading = true

        lifecycleScope.launch {
            try {
                fileAdapter.setDownloading(position, true)
                var lastUpdateTime = 0L
                var lastUpdateBytes = 0L

                val outputFile = FileHelper.getOpusFile(file)
                val outputStream = FileOutputStream(outputFile)

                bleManager.syncBleFile(
                    sessionId = file.sessionId,
                    onOpusData = { type, start, data ->
                        if (type == 1) { // 1 for data, 0 for start
                            outputStream.write(data)
                            val totalBytes = outputFile.length()
                            val progress = (totalBytes * 100 / file.fileSize).toInt()

                            val currentTime = System.currentTimeMillis()
                            if (currentTime - lastUpdateTime >= 500) { // Update every 0.5s
                                val bytesSinceLastUpdate = totalBytes - lastUpdateBytes
                                val speedKbps = (bytesSinceLastUpdate / 1024f) / ((currentTime - lastUpdateTime) / 1000f)
                                requireActivity().runOnUiThread {
                                    fileAdapter.updateDownloadStatus(position, progress, speedKbps)
                                }
                                lastUpdateTime = currentTime
                                lastUpdateBytes = totalBytes
                            }
                        }
                    },
                    onPCMData = { _, _, _ -> }, // Not used here
                    onFinish = {
                        outputStream.close()
                        requireActivity().runOnUiThread {
                            Toast.makeText(requireContext(), getString(R.string.toast_download_complete), Toast.LENGTH_SHORT).show()
                            isDownloading = false
                            fileAdapter.setDownloading(position, false)
                            fileAdapter.notifyItemChanged(position)
                        }
                    }
                )
            } catch (e: Exception) {
                isDownloading = false
                fileAdapter.setDownloading(position, false)
                Log.e(TAG, "Download failed", e)
                Toast.makeText(requireContext(), getString(R.string.toast_download_failed, e.message), Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun setSelectionMode(enable: Boolean) {
        isSelectionMode = enable
        fileAdapter.setSelectionMode(enable)
        selectionActionsContainer.visibility = if (enable) View.VISIBLE else View.GONE
        if (!enable) {
            fileAdapter.clearSelections()
        }

        if (enable && playerContainer.visibility == View.VISIBLE) {
            opusPlayer.stop()
            updatePlayerUiToDefault()
        }

        updateSelectionTitle()

        // Update selection button text
        if (enable) {
            btnSelect.text = getString(R.string.action_cancel)
            updateSelectionTitle()
        } else {
            btnSelect.text = getString(R.string.action_select)
            updateSelectionTitle() // Resets to file count
        }
    }

    private fun updateSelectionTitle() {
        if (isSelectionMode) {
            tvFileCount.text = getString(R.string.selected_files_count, fileAdapter.selectedItems.size)
        } else {
            mainViewModel.fileList.value?.let {
                tvFileCount.text = getString(R.string.fragment_device_feature_files_count, it.size)
            }
        }
    }
    
    private fun updateDeleteButtonState() {
        btnDeleteSelection.isEnabled = fileAdapter.selectedItems.isNotEmpty()
        btnUploadSelection.isEnabled = fileAdapter.selectedItems.isNotEmpty()
        updateSelectionTitle()
    }

    private fun setupSelectionControls() {
        btnSelectAll.setOnClickListener {
            fileAdapter.selectAll()
            updateDeleteButtonState()
        }

        btnDeleteSelection.setOnClickListener {
            val selectedFiles = fileAdapter.selectedItems.toList() // Create a copy
            if (selectedFiles.isNotEmpty()) {
                AlertDialog.Builder(requireContext())
                    .setTitle(getString(R.string.dialog_title_delete_files))
                    .setMessage(getString(R.string.dialog_message_delete_files, selectedFiles.size))
                    .setPositiveButton(getString(R.string.action_delete)) { _, _ ->
                        deleteDeviceFiles(selectedFiles)
                    }
                    .setNegativeButton(getString(R.string.action_cancel), null)
                    .show()
            }
        }

        btnUploadSelection.setOnClickListener {
            val selectedFiles = fileAdapter.selectedItems.toList()
            if (selectedFiles.isNotEmpty()) {
                uploadFiles(selectedFiles)
            }
        }
    }
    
    private fun deleteDeviceFile(file: BleFile) {
        bleManager.deleteFile(file.sessionId) { rsp ->
            activity?.runOnUiThread {
                if (rsp != null && rsp.status == 0) {
                    Toast.makeText(requireContext(), getString(R.string.toast_delete_successful), Toast.LENGTH_SHORT).show()
                    val opusFile = FileHelper.getOpusFile(file)
                    if (opusFile.exists()) {
                        opusFile.delete()
                    }
                    // Refresh the whole list to be safe
                    bleManager.getFileList(0) { fileList ->
                         if (fileList != null) {
                             mainViewModel.updateFileList(fileList.toMutableList())
                         }
                    }
                } else {
                    Toast.makeText(requireContext(), getString(R.string.toast_delete_failed), Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun deleteDeviceFiles(files: List<BleFile>) {
        lifecycleScope.launch {
            var successCount = 0
            files.forEach { file ->
                val deleted = suspendCancellableCoroutine<Boolean> { continuation ->
                    bleManager.deleteFile(file.sessionId) { rsp ->
                        if (continuation.isActive) {
                            val success = rsp != null && rsp.status == 0
                            continuation.resume(success)
                        }
                    }
                }
                if (deleted) {
                    val opusFile = FileHelper.getOpusFile(file)
                    if (opusFile.exists()) {
                        opusFile.delete()
                    }
                    successCount++
                }
            }

            Toast.makeText(
                requireContext(),
                getString(R.string.toast_files_deleted, successCount),
                Toast.LENGTH_SHORT
            ).show()

            setSelectionMode(false)
            bleManager.getFileList(0) { fileList ->
                 if (fileList != null) {
                     mainViewModel.updateFileList(fileList.toMutableList())
                 } else {
                    Toast.makeText(
                        requireContext(),
                        getString(R.string.toast_get_file_list_failed),
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    private fun startUpload(file: BleFile, position: Int) {
        val opusFile = FileHelper.getOpusFile(file)
        if (!opusFile.exists()) {
            Toast.makeText(requireContext(), R.string.toast_file_not_found_for_upload, Toast.LENGTH_SHORT).show()
            return
        }

        fileAdapter.setUploading(position, true)

        mainViewModel.uploadFile(opusFile, file,
            onProgress = { progress ->
                activity?.runOnUiThread {
                    fileAdapter.updateUploadProgress(position, (progress * 100).toInt())
                }
            },
            onResult = { success, errorMessage, fileId ->
                activity?.runOnUiThread {
                    fileAdapter.setUploading(position, false)
                    if (success && fileId != null) {
                        Toast.makeText(requireContext(), R.string.toast_upload_successful, Toast.LENGTH_SHORT).show()
                        fileAdapter.setUploadSuccess(file.sessionId, fileId)
                    } else {
                        Toast.makeText(requireContext(), "${getString(R.string.toast_upload_failed)}: $errorMessage", Toast.LENGTH_LONG).show()
                    }
                }
            }
        )
    }

    private fun uploadFiles(files: List<BleFile>) {
        lifecycleScope.launch {
            val totalFiles = files.size
            var uploadedCount = 0

            Toast.makeText(requireContext(), getString(R.string.toast_batch_upload_started), Toast.LENGTH_SHORT).show()
            setSelectionMode(false)

            files.forEach { file ->
                val opusFile = FileHelper.getOpusFile(file)
                if (opusFile.exists()) {
                    val position = mainViewModel.fileList.value?.indexOf(file) ?: -1
                    if (position != -1) {
                         activity?.runOnUiThread { fileAdapter.setUploading(position, true) }
                    }

                    try {
                        mainViewModel.uploadFile(opusFile, file,
                            onProgress = { progress ->
                                if (position != -1) {
                                    activity?.runOnUiThread { fileAdapter.updateUploadProgress(position, (progress * 100).toInt()) }
                                }
                            },
                            onResult = { success, _, fileId ->
                                if (position != -1) {
                                    activity?.runOnUiThread { fileAdapter.setUploading(position, false) }
                                }
                                if(success && fileId != null) {
                                    fileAdapter.setUploadSuccess(file.sessionId, fileId)
                                    uploadedCount++
                                }
                            }
                        )
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to upload ${opusFile.name}", e)
                    }
                }
            }

            activity?.runOnUiThread {
                Toast.makeText(requireContext(), getString(R.string.toast_batch_upload_completed, uploadedCount, totalFiles), Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun deleteLocalFile(file: BleFile, position: Int) {
        val localFile = FileHelper.getOpusFile(file)
        if (localFile.exists()) {
            if (localFile.delete()) {
                fileAdapter.notifyItemChanged(position)
                Toast.makeText(requireContext(), getString(R.string.toast_local_file_deleted), Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(requireContext(), getString(R.string.toast_failed_to_delete_local_file), Toast.LENGTH_SHORT).show()
            }
        }
    }

    // OpusPlayer.PlayerStateListener implementation
    override fun onProgress(currentPosition: Int, totalDuration: Int) {
        activity?.runOnUiThread {
            playerSeekBar.progress = currentPosition
            tvPlayerCurrentTime.text = formatDuration(currentPosition)
        }
    }

    override fun onCompleted() {
        activity?.runOnUiThread {
            updatePlayerUiToDefault()
        }
    }

    override fun onError(message: String) {
        activity?.runOnUiThread {
            Toast.makeText(requireContext(), "Player Error: $message", Toast.LENGTH_LONG).show()
            updatePlayerUiToDefault()
        }
    }

    override fun onPrepared(duration: Int) {
        activity?.runOnUiThread {
            playerSeekBar.max = duration
            tvPlayerTotalTime.text = formatDuration(duration)
            playerSeekBar.isEnabled = true
            isPlayerPlaying = true
            btnPlayPause.setImageResource(R.drawable.ic_pause)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        opusPlayer.stop()
    }
}