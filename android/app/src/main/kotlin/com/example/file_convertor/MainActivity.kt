package com.example.file_convertor

import android.app.usage.StorageStatsManager
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.os.storage.StorageManager
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

// FlutterFragmentActivity is required by local_auth (biometric prompt).
class MainActivity : FlutterFragmentActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "file_convertor/storage",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCapacity" -> executor.execute {
                    val data = try {
                        capacity()
                    } catch (e: Exception) {
                        mainHandler.post { result.error("capacity_failed", e.message, null) }
                        return@execute
                    }
                    mainHandler.post { result.success(data) }
                }
                "getMediaUsage" -> executor.execute {
                    val data = try {
                        mapOf(
                            "images" to mediaUsage(MediaStore.Images.Media.EXTERNAL_CONTENT_URI),
                            "videos" to mediaUsage(MediaStore.Video.Media.EXTERNAL_CONTENT_URI),
                            "audio" to mediaUsage(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI),
                        )
                    } catch (e: Exception) {
                        mainHandler.post { result.error("media_failed", e.message, null) }
                        return@execute
                    }
                    mainHandler.post { result.success(data) }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Device capacity as shown in system Settings (falls back to StatFs). */
    private fun capacity(): Map<String, Long> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val stats = getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
            val uuid = StorageManager.UUID_DEFAULT
            return mapOf(
                "totalBytes" to stats.getTotalBytes(uuid),
                "freeBytes" to stats.getFreeBytes(uuid),
            )
        }
        val stat = StatFs(Environment.getDataDirectory().path)
        return mapOf("totalBytes" to stat.totalBytes, "freeBytes" to stat.availableBytes)
    }

    /** Total size and count of media the app is permitted to see. */
    private fun mediaUsage(uri: Uri): Map<String, Long> {
        var bytes = 0L
        var count = 0L
        contentResolver.query(
            uri,
            arrayOf(MediaStore.MediaColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            while (cursor.moveToNext()) {
                bytes += cursor.getLong(sizeColumn)
                count++
            }
        }
        return mapOf("bytes" to bytes, "count" to count)
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
