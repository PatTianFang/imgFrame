package com.imgframe.img_frame

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "img_frame/export"
        ).setMethodCallHandler { call, result ->
            if (call.method != "savePng") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fileName = call.argument<String>("fileName")
            val sourcePath = call.argument<String>("sourcePath")
            val bytes = call.argument<ByteArray>("bytes")
            if (fileName.isNullOrBlank() || (sourcePath.isNullOrBlank() && bytes == null)) {
                result.error("invalid_args", "Missing fileName and source data", null)
                return@setMethodCallHandler
            }

            Thread {
                try {
                    val savedPath = if (!sourcePath.isNullOrBlank()) {
                        savePngFromFile(fileName, File(sourcePath))
                    } else {
                        savePngFromBytes(fileName, bytes!!)
                    }
                    runOnUiThread { result.success(savedPath) }
                } catch (error: Exception) {
                    runOnUiThread {
                        result.error("save_failed", error.message, null)
                    }
                }
            }.start()
        }
    }

    private fun normalizedPngName(fileName: String): String {
        return if (fileName.endsWith(".png", ignoreCase = true)) {
            fileName
        } else {
            "$fileName.png"
        }
    }

    private fun savePngFromBytes(fileName: String, bytes: ByteArray): String {
        val tempFile = File.createTempFile("img_frame_export_", ".png", cacheDir)
        return try {
            FileOutputStream(tempFile).use { output ->
                output.write(bytes)
                output.flush()
            }
            savePngFromFile(fileName, tempFile)
        } finally {
            tempFile.delete()
        }
    }

    private fun savePngFromFile(fileName: String, sourceFile: File): String {
        if (!sourceFile.exists()) {
            throw IOException("Export source file does not exist")
        }

        val safeName = normalizedPngName(fileName)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            savePngWithMediaStore(safeName, sourceFile)
        } else {
            savePngToPublicPictures(safeName, sourceFile)
        }
    }

    private fun savePngWithMediaStore(fileName: String, sourceFile: File): String {
        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/imgFrame"
            )
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }

        val collection = MediaStore.Images.Media.getContentUri(
            MediaStore.VOLUME_EXTERNAL_PRIMARY
        )
        val uri = resolver.insert(collection, values)
            ?: throw IOException("Unable to create MediaStore entry")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(sourceFile).use { input ->
                    input.copyTo(output)
                }
                output.flush()
            } ?: throw IOException("Unable to open output stream")

            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    private fun savePngToPublicPictures(fileName: String, sourceFile: File): String {
        val directory = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            "imgFrame"
        )
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Unable to create Pictures/imgFrame")
        }

        val target = File(directory, fileName)
        FileInputStream(sourceFile).use { input ->
            FileOutputStream(target).use { output ->
                input.copyTo(output)
                output.flush()
            }
        }
        MediaScannerConnection.scanFile(
            this,
            arrayOf(target.absolutePath),
            arrayOf("image/png"),
            null
        )
        return target.absolutePath
    }
}
