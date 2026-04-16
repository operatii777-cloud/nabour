package com.florin.nabour

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Înregistrează canalele așteptate de [BleBumpService] (Dart).
 * Implementarea BLE completă (advertising/scan) poate fi adăugată ulterior; fără
 * acest handler Flutter raportează MissingPluginException pe dispozitive reale.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "com.nabour/ble_bump").setMethodCallHandler { call, result ->
            when (call.method) {
                "start", "stop" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "com.nabour/ble_bump_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Stub: fără evenimente BLE; Bump folosește fallback GPS în restul app-ului.
                }

                override fun onCancel(arguments: Any?) {}
            },
        )
    }
}
