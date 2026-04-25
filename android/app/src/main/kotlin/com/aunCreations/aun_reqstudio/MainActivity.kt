package com.aunCreations.aun_reqstudio

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, MethodChannel.MethodCallHandler {
    private var screenshotSink: EventChannel.EventSink? = null
    private var sharedImportSink: EventChannel.EventSink? = null
    private var screenshotObserver: ContentObserver? = null
    private var lastScreenshotEventMs: Long = 0L
    private var screenCaptureCallbackRegistered: Boolean = false
    private var isActivityResumed: Boolean = false
    private var pendingSharedImport: Map<String, String>? = null

    private val screenCaptureCallback = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
        Activity.ScreenCaptureCallback {
            emitScreenshotEvent()
        }
    } else {
        null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.aun.reqstudio/screenshot_events"
        ).setStreamHandler(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.aun.reqstudio/feedback_email"
        ).setMethodCallHandler(this)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.aun.reqstudio/shared_json_import/events"
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sharedImportSink = events
                    dispatchPendingSharedImport()
                }

                override fun onCancel(arguments: Any?) {
                    sharedImportSink = null
                }
            }
        )
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.aun.reqstudio/shared_json_import"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedJson" -> {
                    result.success(pendingSharedImport)
                    pendingSharedImport = null
                }

                else -> result.notImplemented()
            }
        }
        cacheSharedImport(intent)
        dispatchPendingSharedImport()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        screenshotSink = events
        syncScreenshotDetection()
    }

    override fun onCancel(arguments: Any?) {
        screenshotSink = null
        syncScreenshotDetection()
    }

    override fun onResume() {
        super.onResume()
        isActivityResumed = true
        syncScreenshotDetection()
    }

    override fun onPause() {
        isActivityResumed = false
        syncScreenshotDetection()
        super.onPause()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        cacheSharedImport(intent)
        dispatchPendingSharedImport()
    }

    private fun syncScreenshotDetection() {
        val shouldDetectScreenshots = screenshotSink != null && isActivityResumed
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            if (shouldDetectScreenshots && !screenCaptureCallbackRegistered) {
                try {
                    registerScreenCaptureCallback(mainExecutor, screenCaptureCallback!!)
                    screenCaptureCallbackRegistered = true
                } catch (_: IllegalStateException) {
                    // Android 14+ can report an already-registered callback during
                    // rapid listener/lifecycle transitions. Treat that state as active.
                    screenCaptureCallbackRegistered = true
                } catch (_: SecurityException) {
                    // Third-party apps can hit a permission denial here on some
                    // Android 14+ devices/builds. Fall back to the MediaStore
                    // observer path below instead of surfacing a Flutter error.
                    screenCaptureCallbackRegistered = false
                }
            }

            if (!screenCaptureCallbackRegistered) {
                syncLegacyScreenshotObserver(shouldDetectScreenshots)
                return
            }

            if (!shouldDetectScreenshots && screenCaptureCallbackRegistered) {
                try {
                    screenCaptureCallback?.let { unregisterScreenCaptureCallback(it) }
                } catch (_: IllegalStateException) {
                    // If the callback is already gone, just bring our local flag back in sync.
                } finally {
                    screenCaptureCallbackRegistered = false
                }
            }
            return
        }

        syncLegacyScreenshotObserver(shouldDetectScreenshots)
    }

    private fun syncLegacyScreenshotObserver(shouldDetectScreenshots: Boolean) {
        if (shouldDetectScreenshots) {
            if (screenshotObserver != null) return
            screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    if (looksLikeScreenshot(uri)) {
                        emitScreenshotEvent()
                    }
                }
            }
            contentResolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                true,
                screenshotObserver!!
            )
        } else {
            screenshotObserver?.let {
                contentResolver.unregisterContentObserver(it)
            }
            screenshotObserver = null
        }
    }

    private fun looksLikeScreenshot(uri: Uri?): Boolean {
        return try {
            val projection = arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.RELATIVE_PATH,
                MediaStore.Images.Media.DATE_ADDED
            )
            val targetUri = uri ?: MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            contentResolver.query(
                targetUri,
                projection,
                null,
                null,
                "${MediaStore.Images.Media.DATE_ADDED} DESC"
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return false
                }
                val displayName = cursor.getString(1)?.lowercase().orEmpty()
                val relativePath = cursor.getString(2)?.lowercase().orEmpty()
                displayName.contains("screenshot") ||
                    relativePath.contains("screenshot")
            } ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun emitScreenshotEvent() {
        val now = System.currentTimeMillis()
        if (now - lastScreenshotEventMs < 1500) return
        lastScreenshotEventMs = now
        runOnUiThread {
            screenshotSink?.success(
                mapOf(
                    "platform" to "android",
                    "takenAtMs" to now
                )
            )
        }
    }

    private fun cacheSharedImport(intent: Intent?) {
        val payload = extractSharedImportPayload(intent) ?: return
        pendingSharedImport = payload
    }

    private fun dispatchPendingSharedImport() {
        val payload = pendingSharedImport ?: return
        val sink = sharedImportSink ?: return
        runOnUiThread {
            sink.success(payload)
            pendingSharedImport = null
        }
    }

    private fun extractSharedImportPayload(intent: Intent?): Map<String, String>? {
        if (intent == null) return null
        val action = intent.action ?: return null
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_VIEW) {
            return null
        }

        val uri = when (action) {
            Intent.ACTION_SEND -> extractSendUri(intent)
            Intent.ACTION_VIEW -> intent.data
            else -> null
        } ?: return null

        val inferredName = queryDisplayName(uri) ?: "shared.json"
        val mimeType = intent.type ?: contentResolver.getType(uri) ?: "application/octet-stream"
        if (!looksLikeJsonShare(inferredName, mimeType)) {
            return null
        }

        val cachedFile = copySharedFileToCache(uri, inferredName) ?: return null
        return hashMapOf(
            "path" to cachedFile.absolutePath,
            "fileName" to inferredName,
            "mimeType" to mimeType,
            "action" to action
        )
    }

    private fun extractSendUri(intent: Intent): Uri? {
        val streamUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
        if (streamUri != null) return streamUri
        val clipData = intent.clipData
        if (clipData != null && clipData.itemCount > 0) {
            return clipData.getItemAt(0).uri
        }
        return null
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme == "content") {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) {
                        return cursor.getString(index)
                    }
                }
            }
        }
        return uri.lastPathSegment?.substringAfterLast('/')
    }

    private fun looksLikeJsonShare(fileName: String, mimeType: String): Boolean {
        val lowerName = fileName.lowercase()
        val lowerMime = mimeType.lowercase()
        return lowerName.endsWith(".json") ||
            lowerMime == "application/json" ||
            lowerMime == "text/json" ||
            lowerMime.endsWith("+json")
    }

    private fun copySharedFileToCache(uri: Uri, fileName: String): File? {
        return try {
            val targetDir = File(cacheDir, "shared_json_imports").apply {
                mkdirs()
            }
            val safeFileName = sanitizeSharedFileName(fileName)
            val targetFile = File(
                targetDir,
                "${System.currentTimeMillis()}_$safeFileName"
            )
            contentResolver.openInputStream(uri)?.use { input ->
                targetFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            targetFile
        } catch (_: Exception) {
            null
        }
    }

    private fun sanitizeSharedFileName(fileName: String): String {
        val sanitized = fileName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        if (sanitized.lowercase().endsWith(".json")) return sanitized
        return "${sanitized.ifBlank { "shared" }}.json"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "composeEmail" -> composeEmail(call, result)
            else -> result.notImplemented()
        }
    }

    private fun composeEmail(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            result.error("bad_args", "Missing email fields.", null)
            return
        }

        val recipients = (args["to"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
        val subject = args["subject"] as? String ?: ""
        val body = args["body"] as? String ?: ""
        val attachmentPath = args["attachmentPath"] as? String
        val attachmentMimeType = args["attachmentMimeType"] as? String ?: "image/png"
        if (attachmentPath.isNullOrBlank()) {
            result.error("bad_args", "Missing attachment path.", null)
            return
        }

        val attachmentFile = File(attachmentPath)
        if (!attachmentFile.exists()) {
            result.error("attachment_missing", "Could not find the screenshot attachment.", null)
            return
        }

        val attachmentUri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            attachmentFile
        )

        val emailPackages = packageManager.queryIntentActivities(
            Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:")),
            0
        )

        if (emailPackages.isEmpty()) {
            result.error("mail_unavailable", "No email app is installed on this device.", null)
            return
        }

        val targetIntents = emailPackages.map { resolveInfo ->
            Intent(Intent.ACTION_SEND).apply {
                type = attachmentMimeType
                `package` = resolveInfo.activityInfo.packageName
                putExtra(Intent.EXTRA_EMAIL, recipients.toTypedArray())
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
                putExtra(Intent.EXTRA_STREAM, attachmentUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }

        val chooser = Intent.createChooser(
            targetIntents.first(),
            "Send feedback"
        ).apply {
            putExtra(Intent.EXTRA_INITIAL_INTENTS, targetIntents.drop(1).toTypedArray())
        }

        try {
            startActivity(chooser)
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error("mail_unavailable", "No email app is installed on this device.", null)
        }
    }
}
