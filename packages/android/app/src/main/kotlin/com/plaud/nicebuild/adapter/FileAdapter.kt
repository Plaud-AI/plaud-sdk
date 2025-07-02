package com.plaud.nicebuild.adapter

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CheckBox
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.plaud.nicebuild.R
import com.plaud.nicebuild.data.WorkflowCacheManager
import com.plaud.nicebuild.utils.FileHelper
import sdk.penblesdk.entity.BleFile
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class DownloadStatus(val progress: Int, val speedKbps: Float)

// Private data class to represent a potential action for a file.
private data class FileAction(val textResId: Int, val clickListener: () -> Unit)

class FileAdapter(private val context: Context) : RecyclerView.Adapter<FileAdapter.ViewHolder>() {
    private var files: List<BleFile> = emptyList()
    var onItemClick: ((BleFile, Int) -> Unit)? = null
    var onDownloadClick: ((BleFile, Int) -> Unit)? = null
    var onUploadClick: ((BleFile, Int) -> Unit)? = null
    var onDeleteLocalClick: ((BleFile, Int) -> Unit)? = null
    var onSelectionChanged: (() -> Unit)? = null
    var onSubmitClickListener: ((String) -> Unit)? = null
    var onCheckStatusClickListener: ((String) -> Unit)? = null
    var onViewSummaryClicked: ((String) -> Unit)? = null


    private val downloadStatus = mutableMapOf<Int, Boolean>()
    private val downloadInfoMap = mutableMapOf<Int, DownloadStatus>()
    private val uploadStatus = mutableMapOf<Int, Boolean>()
    private val uploadProgressMap = mutableMapOf<Int, Int>()
    private var isSelectionMode = false
    val selectedItems = mutableSetOf<BleFile>()

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_file, parent, false)
        return ViewHolder(view)
    }

    private fun localFileExists(file: BleFile): Boolean {
        val opusFile = FileHelper.getOpusFile(file)
        return opusFile.exists() && opusFile.length() > 0
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val file = files[position]
        holder.bind(file)
    }

    override fun getItemCount() = files.size

    fun updateFiles(newFiles: List<BleFile>) {
        this.files = newFiles
        notifyDataSetChanged()
    }

    fun getFiles(): List<BleFile> = files

    fun setDownloading(position: Int, isDownloading: Boolean) {
        downloadStatus[position] = isDownloading
        if (!isDownloading) downloadInfoMap.remove(position)
        notifyItemChanged(position)
    }

    fun updateDownloadStatus(position: Int, progress: Int, speedKbps: Float) {
        downloadInfoMap[position] = DownloadStatus(progress, speedKbps)
        notifyItemChanged(position)
    }

    fun setUploading(position: Int, isUploading: Boolean) {
        uploadStatus[position] = isUploading
        if (!isUploading) uploadProgressMap.remove(position)
        notifyItemChanged(position)
    }

    fun updateUploadProgress(position: Int, progress: Int) {
        uploadProgressMap[position] = progress
        notifyItemChanged(position)
    }

    fun setUploadSuccess(sessionId: Long, fileId: String) {
        val index = files.indexOfFirst { it.sessionId == sessionId }
        if (index != -1) {
            val file = files[index]
            WorkflowCacheManager.saveFileId(context, file, fileId)
            notifyItemChanged(index)
        }
    }

    fun setSelectionMode(enable: Boolean) {
        isSelectionMode = enable
        if (!enable) selectedItems.clear()
        notifyDataSetChanged()
    }

    fun selectAll() {
        if (selectedItems.size == files.size) {
            selectedItems.clear()
        } else {
            selectedItems.addAll(files)
        }
        notifyDataSetChanged()
        onSelectionChanged?.invoke()
    }

    fun clearSelections() {
        selectedItems.clear()
        notifyDataSetChanged()
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val fileName: TextView = itemView.findViewById(R.id.tv_file_name)
        private val fileSize: TextView = itemView.findViewById(R.id.tv_file_size)
        private val btnDownload: ImageButton = itemView.findViewById(R.id.btn_download)
        private val btnUpload: ImageButton = itemView.findViewById(R.id.btn_upload)
        private val btnDeleteLocal: ImageButton = itemView.findViewById(R.id.btn_delete_local)
        private val tvDownloadStatus: TextView = itemView.findViewById(R.id.tv_download_status)
        private val uploadProgressBar: ProgressBar = itemView.findViewById(R.id.progress_bar_upload)
        private val checkbox: CheckBox = itemView.findViewById(R.id.checkbox_select)
        private val textButtonsContainer: LinearLayout = itemView.findViewById(R.id.text_buttons_container)

        // Reference the three generic action buttons
        private val actionButtons = listOf<MaterialButton>(
            itemView.findViewById(R.id.btn_action_1),
            itemView.findViewById(R.id.btn_action_2),
            itemView.findViewById(R.id.btn_action_3)
        )

        fun bind(file: BleFile) {
            val context = itemView.context
            val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
            fileName.text = sdf.format(Date(file.sessionId * 1000L))
            fileSize.text = String.format("%.2f MB", file.fileSize / (1024.0 * 1024.0))

            val isDownloading = downloadStatus[bindingAdapterPosition] ?: false
            val downloadInfo = downloadInfoMap[bindingAdapterPosition]
            val isUploading = uploadStatus[bindingAdapterPosition] ?: false
            val uploadProgress = uploadProgressMap[bindingAdapterPosition]
            val fileExists = localFileExists(file)

            // --- GLOBAL VISIBILITY ---
            checkbox.visibility = if (isSelectionMode) View.VISIBLE else View.GONE
            tvDownloadStatus.visibility = if (isDownloading) View.VISIBLE else View.GONE
            if (isDownloading && downloadInfo != null) {
                tvDownloadStatus.text = "${downloadInfo.progress}% - ${"%.1f".format(downloadInfo.speedKbps)} KB/s"
            }

            // --- ICON BUTTONS LOGIC ---
            val showIconActions = !isSelectionMode && !isDownloading
            itemView.findViewById<View>(R.id.actions_container).visibility = if (showIconActions) View.VISIBLE else View.GONE

            btnDownload.visibility = if (showIconActions && !fileExists) View.VISIBLE else View.GONE
            btnUpload.visibility = if (showIconActions && fileExists && !isUploading) View.VISIBLE else View.GONE
            btnDeleteLocal.visibility = if (showIconActions && fileExists) View.VISIBLE else View.GONE
            uploadProgressBar.visibility = if (showIconActions && isUploading) View.VISIBLE else View.GONE
            if (isUploading) {
                uploadProgressBar.isIndeterminate = (uploadProgress == null)
                uploadProgress?.let { uploadProgressBar.progress = it }
            } else {
                uploadProgressBar.progress = 0
            }


            // --- TEXT BUTTONS LOGIC ---
            // 1. Collect all possible actions for the current state.
            val availableActions = mutableListOf<FileAction>()
            if (showIconActions && fileExists && !isUploading) {
                val workflowInfo = WorkflowCacheManager.getWorkflowInfo(context, file)

                // Action: View Summary
                file.summaryMarkdown?.let { summary ->
                    if (summary.isNotBlank()) {
                        availableActions.add(FileAction(R.string.action_view_summary) { onViewSummaryClicked?.invoke(summary) })
                    }
                }

                // Actions: Submit or Check Status
                if (workflowInfo != null) {
                    val currentWorkflowId = workflowInfo.workflowId
                    if (currentWorkflowId.isNullOrEmpty()) {
                        // Has fileId but no workflowId -> can submit.
                        availableActions.add(FileAction(R.string.action_submit_text) { onSubmitClickListener?.invoke(workflowInfo.fileId) })
                    } else {
                        // Has workflowId -> can check status.
                        availableActions.add(FileAction(R.string.action_check_status_text) { onCheckStatusClickListener?.invoke(currentWorkflowId) })
                    }
                }
            }

            // 2. Map collected actions to the buttons.
            textButtonsContainer.visibility = if (availableActions.isNotEmpty()) View.VISIBLE else View.GONE
            actionButtons.forEachIndexed { index, button ->
                if (index < availableActions.size) {
                    val action = availableActions[index]
                    button.visibility = View.VISIBLE
                    button.text = context.getString(action.textResId)
                    button.setOnClickListener { action.clickListener.invoke() }
                } else {
                    button.visibility = View.INVISIBLE // Use INVISIBLE to keep layout spacing
                }
            }

            // --- GLOBAL CLICKS ---
            itemView.setOnClickListener {
                if (isSelectionMode) {
                    toggleSelection(file)
                } else {
                    if (bindingAdapterPosition != RecyclerView.NO_POSITION) {
                        onItemClick?.invoke(file, bindingAdapterPosition)
                    }
                }
            }
            btnDownload.setOnClickListener {
                if (bindingAdapterPosition != RecyclerView.NO_POSITION) {
                    onDownloadClick?.invoke(file, bindingAdapterPosition)
                }
            }
            btnUpload.setOnClickListener {
                if (bindingAdapterPosition != RecyclerView.NO_POSITION) {
                    onUploadClick?.invoke(file, bindingAdapterPosition)
                }
            }
            btnDeleteLocal.setOnClickListener {
                if (bindingAdapterPosition != RecyclerView.NO_POSITION) {
                    onDeleteLocalClick?.invoke(file, bindingAdapterPosition)
                }
            }
            checkbox.isChecked = selectedItems.contains(file)
            checkbox.setOnClickListener { toggleSelection(file) }
        }

        private fun toggleSelection(file: BleFile) {
            if (selectedItems.contains(file)) {
                selectedItems.remove(file)
            } else {
                selectedItems.add(file)
            }
            if (bindingAdapterPosition != RecyclerView.NO_POSITION) {
                notifyItemChanged(bindingAdapterPosition)
            }
            onSelectionChanged?.invoke()
        }
    }
}