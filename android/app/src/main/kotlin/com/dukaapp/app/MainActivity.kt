package com.dukaapps.app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.dukaapp/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val fileName = call.argument<String>("fileName") ?: ""
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null || fileName.isEmpty()) {
                        result.error("INVALID_ARGS", "fileName and bytes required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val savedPath = saveToDownloads(fileName, bytes)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveToDownloads(fileName: String, bytes: ByteArray): String {
        val nameWithoutExt = fileName.substringBeforeLast(".")
        val ext = fileName.substringAfterLast(".")
        var uniqueName = fileName

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver

            val projection = arrayOf(MediaStore.Downloads.DISPLAY_NAME)
            val selection = "${MediaStore.Downloads.DISPLAY_NAME} LIKE ? AND ${MediaStore.Downloads.RELATIVE_PATH} = ?"
            val selectionArgs = arrayOf("${nameWithoutExt}%.${ext}", "${Environment.DIRECTORY_DOWNLOADS}/")
            val cursor = resolver.query(MediaStore.Downloads.EXTERNAL_CONTENT_URI, projection, selection, selectionArgs, null)

            val existingNames = mutableSetOf<String>()
            cursor?.use {
                while (it.moveToNext()) {
                    val name = it.getString(0)
                    if (name != null) existingNames.add(name)
                }
            }

            if (existingNames.contains(uniqueName)) {
                var counter = 2
                while (existingNames.contains("${nameWithoutExt}($counter).$ext")) {
                    counter++
                }
                uniqueName = "${nameWithoutExt}($counter).$ext"
            }

            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, uniqueName)
                put(MediaStore.Downloads.MIME_TYPE, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw Exception("Failed to create MediaStore entry")

            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
            }

            return uri.toString()
        } else {
            @Suppress("DEPRECATION")
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!dir.exists()) dir.mkdirs()
            var counter = 1
            var file = File(dir, uniqueName)
            while (file.exists()) {
                counter++
                uniqueName = "${nameWithoutExt}($counter).$ext"
                file = File(dir, uniqueName)
            }
            FileOutputStream(file).use { it.write(bytes) }
            return file.absolutePath
        }
    }
}
