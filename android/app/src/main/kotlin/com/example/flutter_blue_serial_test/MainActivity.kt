package com.example.flutter_blue_serial_test

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import java.lang.reflect.Method

class MainActivity: FlutterActivity() {
    private val PERMISSION_REQUEST_CODE = 1
    private val PIN_CODE = "0000"  // 원하는 PIN 코드를 설정하세요

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if (BluetoothDevice.ACTION_PAIRING_REQUEST == action) {
                val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                if (device != null) {
                    try {
                        device.javaClass.getMethod("setPairingConfirmation", Boolean::class.javaPrimitiveType).invoke(device, true)
                        device.javaClass.getMethod("setPin", ByteArray::class.java).invoke(device, PIN_CODE.toByteArray())
                        abortBroadcast()
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    PERMISSION_REQUEST_CODE)
            }
        }

        // 자동 페어링을 위한 BroadcastReceiver 등록
        val filter = IntentFilter(BluetoothDevice.ACTION_PAIRING_REQUEST)
        registerReceiver(receiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        // BroadcastReceiver 해제
        unregisterReceiver(receiver)
    }
}