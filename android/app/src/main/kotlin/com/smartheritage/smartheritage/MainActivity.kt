package com.smartheritage.smartheritage

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Cho Dart biết đã có khoá Google Maps chưa (lib/services/maps_config.dart),
        // để màn bản đồ báo thiếu khoá thay vì hiện một bản đồ trắng.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smartheritage/maps")
            .setMethodCallHandler { call, result ->
                if (call.method == "isConfigured") {
                    val info = packageManager.getApplicationInfo(
                        packageName,
                        PackageManager.GET_META_DATA,
                    )
                    val key = info.metaData?.getString("com.google.android.geo.API_KEY")
                    result.success(!key.isNullOrBlank())
                } else {
                    result.notImplemented()
                }
            }
    }
}
