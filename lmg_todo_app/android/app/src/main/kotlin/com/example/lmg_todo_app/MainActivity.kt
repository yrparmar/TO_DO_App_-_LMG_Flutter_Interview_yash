package com.example.lmg_todo_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (_: Throwable) {
            // No-op if auto-registration is already in place
        }
    }
}
