package com.plaud.nicebuild.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.google.android.material.switchmaterial.SwitchMaterial
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.plaud.nicebuild.R
import com.plaud.nicebuild.ble.BleCore
import androidx.navigation.fragment.findNavController
import com.plaud.nicebuild.adapter.WifiListAdapter
import android.util.Log
import androidx.lifecycle.ViewModelProvider
import com.plaud.nicebuild.viewmodel.MainViewModel
import android.content.Context
import android.net.wifi.WifiManager
import android.widget.ImageButton
import com.google.android.material.button.MaterialButton
import androidx.lifecycle.Observer
import com.google.android.material.appbar.MaterialToolbar

class DeviceWifiCloudFragment : Fragment() {
    private lateinit var wifiCloudSwitch: SwitchMaterial
    private lateinit var wifiListView: RecyclerView
    private lateinit var configWifiButton: MaterialButton
    private lateinit var wifiListAdapter: WifiListAdapter
    private lateinit var bleManager: BleCore
    private val mainViewModel: MainViewModel by lazy {
        ViewModelProvider(requireActivity()).get(MainViewModel::class.java)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        bleManager = BleCore.getInstance(requireContext())
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_device_wifi_cloud, container, false)
        wifiCloudSwitch = view.findViewById(R.id.switch_wifi_cloud)
        wifiListView = view.findViewById(R.id.rv_wifi_list)
        configWifiButton = view.findViewById(R.id.btn_config_wifi)
        
        view.findViewById<MaterialToolbar>(R.id.toolbar).setOnClickListener {
            findNavController().popBackStack()
        }

        wifiListAdapter = WifiListAdapter()
        wifiListView.layoutManager = LinearLayoutManager(requireContext())
        wifiListView.adapter = wifiListAdapter
        Log.d("wifi", mainViewModel.currentDevice.value.toString())
        Log.d("wifi", bleManager.isConnected().toString() )

        observeViewModel()

        return view
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        Log.d("wifi", "DeviceWifiCloudFragment onViewCreated, context=${requireContext()}, BleManager=${bleManager}")
        // Get WiFi cloud sync switch status
        Log.d("wifi", "Calling getAutoSync...")
        bleManager.getAutoSync { enabled, _ ->
            Log.d("wifi", "getAutoSync callback: enabled=$enabled")
            wifiCloudSwitch.isChecked = enabled == true
        }
        wifiCloudSwitch.setOnCheckedChangeListener { _, isChecked ->
            Log.d("wifi", "setAutoSync called: $isChecked")
            bleManager.setAutoSync(isChecked) {
                // No action needed in callback for this logic
            }
        }
        // Configure WiFi button
        configWifiButton.setOnClickListener {
            val ssid = getCurrentWifiSSID(requireContext())
            val bundle = Bundle().apply {
                // In new UI, we always go to setting page to add a new wifi
                putInt("wifiIndex", -1) 
                putString("defaultSsid", ssid)
            }
            findNavController().navigate(R.id.action_deviceWifiCloudFragment_to_deviceWifiSettingFragment, bundle)
        }
        // WiFi list item click
        wifiListAdapter.onItemClick = { wifiInfo ->
            findNavController().navigate(R.id.action_deviceWifiCloudFragment_to_deviceWifiSettingFragment, Bundle().apply {
                putInt("wifiIndex", wifiInfo.getWifiIndex().toInt())
            })
        }
    }

    override fun onResume() {
        super.onResume()
        // Refresh list through ViewModel each time returning to page
        mainViewModel.loadWifiList()
    }
    
    private fun observeViewModel() {
        mainViewModel.wifiList.observe(viewLifecycleOwner, Observer { list ->
            wifiListAdapter.submitList(list)
        })
    }

    // Get current phone WiFi name
    private fun getCurrentWifiSSID(context: Context): String {
        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val wifiInfo = wifiManager.connectionInfo
        val ssid = wifiInfo.ssid
        return if (ssid != null && ssid.startsWith("\"") && ssid.endsWith("\"")) {
            ssid.substring(1, ssid.length - 1)
        } else {
            ssid ?: ""
        }
    }
} 