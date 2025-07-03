package com.plaud.nicebuild.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.fragment.app.DialogFragment
import com.plaud.nicebuild.R
import io.noties.markwon.Markwon

class SummaryDialogFragment : DialogFragment() {

    private var summaryContent: String? = null

    override fun getTheme(): Int {
        return R.style.RoundedCornersDialog
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            summaryContent = it.getString(ARG_SUMMARY_CONTENT)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        return inflater.inflate(R.layout.dialog_view_summary, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val tvSummaryContent: TextView = view.findViewById(R.id.tv_summary_content)
        val btnClose: ImageButton = view.findViewById(R.id.btn_close)
        
        // Create a Markwon instance
        val markwon = Markwon.create(requireContext())

        // Set the Markdown text to the TextView
        markwon.setMarkdown(tvSummaryContent, this.summaryContent ?: "")

        btnClose.setOnClickListener {
            dismiss()
        }
    }

    companion object {
        const val TAG = "SummaryDialogFragment"
        private const val ARG_SUMMARY_CONTENT = "summary_content"

        fun newInstance(summaryContent: String): SummaryDialogFragment {
            val fragment = SummaryDialogFragment()
            val args = Bundle()
            args.putString(ARG_SUMMARY_CONTENT, summaryContent)
            fragment.arguments = args
            return fragment
        }
    }
} 