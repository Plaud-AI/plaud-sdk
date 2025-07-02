package com.plaud.nicebuild.adapter

import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.plaud.nicebuild.R
import sdk.penblesdk.entity.bean.ble.response.GetWifiInfoRsp

class WifiListAdapter : ListAdapter<GetWifiInfoRsp, WifiListAdapter.WifiViewHolder>(DIFF) {
    var onItemClick: ((GetWifiInfoRsp) -> Unit)? = null
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): WifiViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_wifi_info, parent, false)
        return WifiViewHolder(view)
    }
    override fun onBindViewHolder(holder: WifiViewHolder, position: Int) {
        val item = getItem(position)
        holder.name.text = item.getSSID()
        holder.itemView.setOnClickListener { onItemClick?.invoke(item) }
    }
    class WifiViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val name: TextView = view.findViewById(R.id.tv_wifi_name)
    }
    companion object {
        val DIFF = object : DiffUtil.ItemCallback<GetWifiInfoRsp>() {
            override fun areItemsTheSame(oldItem: GetWifiInfoRsp, newItem: GetWifiInfoRsp) = oldItem.getWifiIndex() == newItem.getWifiIndex()
            @SuppressLint("DiffUtilEquals")
            override fun areContentsTheSame(oldItem: GetWifiInfoRsp, newItem: GetWifiInfoRsp) = oldItem == newItem
        }
    }
} 