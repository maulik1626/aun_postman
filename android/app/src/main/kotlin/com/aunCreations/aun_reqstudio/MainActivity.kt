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
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, MethodChannel.MethodCallHandler {
    private var screenshotSink: EventChannel.EventSink? = null
    private var screenshotObserver: ContentObserver? = null
    private var lastScreenshotEventMs: Long = 0L
    private var screenCaptureCallbackRegistered: Boolean = false

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
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        screenshotSink = events
        startScreenshotDetection()
    }

    override fun onCancel(arguments: Any?) {
        screenshotSink = null
        stopScreenshotDetection()
    }

    override fun onResume() {
        super.onResume()
        if (screenshotSink != null) {
            startScreenshotDetection()
        }
    }

    override fun onPause() {
        stopScreenshotDetection()
        super.onPause()
    }

    private fun startScreenshotDetection() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            if (!screenCaptureCallbackRegistered) {
                registerScreenCaptureCallback(mainExecutor, screenCaptureCallback!!)
                screenCaptureCallbackRegistered = true
            }
            return
        }

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
    }

    private fun stopScreenshotDetection() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            if (screenCaptureCallbackRegistered) {
                screenCaptureCallback?.let { unregisterScreenCaptureCallback(it) }
                screenCaptureCallbackRegistered = false
            }
            return
        }

        screenshotObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        screenshotObserver = null
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
