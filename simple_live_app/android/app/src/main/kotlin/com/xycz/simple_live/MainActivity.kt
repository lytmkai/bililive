package com.xycz.simple_live

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.xycz.simple_live/open_folder"
        ).setMethodCallHandler { call, result ->
            if (call.method == "openFolder") {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("INVALID_ARG", "path is null or empty", null)
                    return@setMethodCallHandler
                }
                val file = File(path)
                if (!file.exists() || !file.isDirectory) {
                    result.error("NOT_FOUND", "directory not found: $path", null)
                    return@setMethodCallHandler
                }
                try {
                    val uri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileProvider.com.crazecoder.openfile",
                        file
                    )
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.directory")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("OPEN_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
