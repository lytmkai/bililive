package com.xycz.simple_live

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Environment
import android.provider.DocumentsContract
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
                val path = call.argument<String>("path") ?: ""
                if (path.isBlank()) {
                    result.error("INVALID_ARG", "path is null or empty", null)
                    return@setMethodCallHandler
                }
                val file = File(path)
                if (!file.exists() || !file.isDirectory) {
                    result.error("NOT_FOUND", "directory not found", null)
                    return@setMethodCallHandler
                }
                if (!tryOpenViaDocumentsContract(path, result)
                    && !tryOpenViaFileProvider(path, result)) {
                    result.error("OPEN_FAILED", "no app found to open directory", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun tryOpenViaDocumentsContract(path: String, result: MethodChannel.Result): Boolean {
        val extStorage = Environment.getExternalStorageDirectory().absolutePath
        if (!path.startsWith(extStorage)) return false
        val relativePath = path.removePrefix(extStorage).trimStart('/')
        val docUri = DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:$relativePath"
        )
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(docUri, "application/vnd.android.directory")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
            return true
        } catch (_: ActivityNotFoundException) {
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = docUri
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addCategory(Intent.CATEGORY_DEFAULT)
            }
            startActivity(intent)
            result.success(true)
            return true
        } catch (_: ActivityNotFoundException) {
            return false
        }
    }

    private fun tryOpenViaFileProvider(path: String, result: MethodChannel.Result): Boolean {
        val file = File(path)
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileProvider.com.crazecoder.openfile",
            file
        )
        for (mime in listOf("application/vnd.android.directory", "*/*")) {
            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, mime)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                result.success(true)
                return true
            } catch (_: ActivityNotFoundException) {
            }
        }
        return false
    }
}
