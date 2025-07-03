package com.plaud.nicebuild.utils

import android.app.Dialog
import android.content.Context
import android.view.LayoutInflater
import android.view.Window
import android.widget.TextView
import com.plaud.nicebuild.R

object LoadingDialog {

    private var dialog: Dialog? = null

    fun show(context: Context, message: String? = null) {
        if (dialog?.isShowing == true) {
            return
        }
        
        val inflater = LayoutInflater.from(context)
        val view = inflater.inflate(R.layout.dialog_loading, null)
        
        val tvMessage = view.findViewById<TextView>(R.id.tv_loading_message)
        message?.let {
            tvMessage.text = it
        }

        dialog = Dialog(context).apply {
            requestWindowFeature(Window.FEATURE_NO_TITLE)
            setContentView(view)
            setCancelable(false)
            window?.setBackgroundDrawableResource(android.R.color.transparent)
            show()
        }
    }

    fun hide() {
        dialog?.dismiss()
        dialog = null
    }
} 