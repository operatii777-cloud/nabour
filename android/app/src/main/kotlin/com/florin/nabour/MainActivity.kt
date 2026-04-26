package com.florin.nabour

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import java.util.UUID

/**
 * BLE Bump — advertising GATT peripheral + BLE scanning.
 *
 * Dart contract (ble_bump_service.dart):
 *  - MethodChannel "com.nabour/ble_bump" : start({serviceUuid, payload}) / stop()
 *  - EventChannel "com.nabour/ble_bump_events" : emits Map{"uid": String, "rssi": Int}
 *
 * Service UUID: 6E61626F-7572-4275-6D70-000000000001
 * Payload: first 20 bytes of the local user UID (UTF-8)
 */
class MainActivity : FlutterActivity() {

    private var bleAdvertiser: BluetoothLeAdvertiser? = null
    private var bleScanner: BluetoothLeScanner? = null
    private var advertiseCallback: AdvertiseCallback? = null
    private var scanCallback: ScanCallback? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ── EventChannel: stream peer-detection events to Dart ──────────────
        EventChannel(messenger, "com.nabour/ble_bump_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )

        // ── MethodChannel: start / stop BLE advertising + scanning ──────────
        MethodChannel(messenger, "com.nabour/ble_bump").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val serviceUuidStr = call.argument<String>("serviceUuid")
                    val payload = call.argument<ByteArray>("payload")
                    if (serviceUuidStr == null || payload == null) {
                        result.error("INVALID_ARGS", "serviceUuid and payload are required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val serviceUuid = ParcelUuid(UUID.fromString(serviceUuidStr))
                        startBle(serviceUuid, payload)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("BLE_START_FAILED", e.message, null)
                    }
                }
                "stop" -> {
                    stopBle()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── BLE helpers ──────────────────────────────────────────────────────────

    private fun bluetoothAdapter(): BluetoothAdapter? =
        (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    private fun startBle(serviceUuid: ParcelUuid, payload: ByteArray) {
        val adapter = bluetoothAdapter() ?: return
        if (!adapter.isEnabled) return

        // Advertise own UID so nearby peers can discover this device
        val advertiseSettings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_LOW)
            .setConnectable(false)
            .setTimeout(0) // advertise indefinitely until stopBle()
            .build()

        val advertiseData = AdvertiseData.Builder()
            .addServiceUuid(serviceUuid)
            .addServiceData(serviceUuid, payload)
            .setIncludeDeviceName(false)
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartFailure(errorCode: Int) {
                // Advertising failed (e.g. no BLE peripheral support) — scan-only mode
            }
        }

        bleAdvertiser = adapter.bluetoothLeAdvertiser
        bleAdvertiser?.startAdvertising(advertiseSettings, advertiseData, advertiseCallback)

        // Scan for other devices advertising the same service UUID
        val scanFilter = ScanFilter.Builder()
            .setServiceUuid(serviceUuid)
            .build()

        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val serviceData = result.scanRecord?.getServiceData(serviceUuid) ?: return
                val peerUid = String(serviceData, Charsets.UTF_8).trimEnd('\u0000')
                if (peerUid.isNotEmpty()) {
                    eventSink?.success(mapOf("uid" to peerUid, "rssi" to result.rssi))
                }
            }
        }

        bleScanner = adapter.bluetoothLeScanner
        bleScanner?.startScan(listOf(scanFilter), scanSettings, scanCallback)
    }

    private fun stopBle() {
        advertiseCallback?.let { bleAdvertiser?.stopAdvertising(it) }
        scanCallback?.let { bleScanner?.stopScan(it) }
        bleAdvertiser = null
        bleScanner = null
        advertiseCallback = null
        scanCallback = null
    }

    override fun onDestroy() {
        stopBle()
        super.onDestroy()
    }
}
