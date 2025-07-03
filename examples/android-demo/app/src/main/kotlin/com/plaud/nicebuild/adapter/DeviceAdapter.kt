package com.plaud.nicebuild.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.plaud.nicebuild.R
import sdk.penblesdk.entity.BleDevice

class DeviceAdapter : RecyclerView.Adapter<DeviceAdapter.ViewHolder>() {

    private val devices = mutableListOf<BleDevice>()
    private var onItemClickListener: ((BleDevice) -> Unit)? = null

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val deviceName: TextView = itemView.findViewById(R.id.tv_device_name)
        val deviceSerial: TextView = itemView.findViewById(R.id.tv_device_serial)
        val signalValue: TextView = itemView.findViewById(R.id.tv_signal_value)
        val connectButton: MaterialButton = itemView.findViewById(R.id.btn_connect)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_device, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val device = devices[position]
        holder.deviceName.text = device.name ?: "Unknown Device"
        holder.deviceSerial.text = device.serialNumber ?: ""
        holder.signalValue.text = "${device.rssi} dBm"

        holder.connectButton.setOnClickListener {
            onItemClickListener?.invoke(device)
        }
    }

    override fun getItemCount() = devices.size

    fun updateDevices(newDevices: List<BleDevice>) {
        devices.clear()
        devices.addAll(newDevices)
        notifyDataSetChanged()
    }

    fun setOnItemClickListener(listener: (BleDevice) -> Unit) {
        onItemClickListener = listener
    }
} 