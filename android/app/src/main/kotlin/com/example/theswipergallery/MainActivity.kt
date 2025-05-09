package com.example.theswipergallery

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.theswipergallery/delete"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_DELETE_PERMISSION = 2023

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "delete" -> {
                    val uriString = call.argument<String>("uri")
                    val moveToTrash = call.argument<Boolean>("moveToTrash") ?: true

                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            val uris = listOf(uri)

                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                if (moveToTrash) {
                                    MediaStore.createTrashRequest(contentResolver, uris, true)
                                } else {
                                    MediaStore.createDeleteRequest(contentResolver, uris)
                                }
                            } else {
                                contentResolver.delete(uri, null, null)
                                result.success(true)
                                return@setMethodCallHandler
                            }

                            pendingResult = result
                            startIntentSenderForResult(intent.intentSender, REQUEST_DELETE_PERMISSION, null, 0, 0, 0)
                        } catch (e: Exception) {
                            result.error("DELETE_FAILED", e.message, null)
                        }
                    } else {
                        result.error("NULL_URI", "No URI provided", null)
                    }
                }

                "deleteMultiple" -> {
                    val uriStrings = call.argument<List<String>>("uris")
                    val moveToTrash = call.argument<Boolean>("moveToTrash") ?: true

                    if (uriStrings != null) {
                        val uris = uriStrings.map { Uri.parse(it) }

                        try {
                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                if (moveToTrash) {
                                    MediaStore.createTrashRequest(contentResolver, uris, true)
                                } else {
                                    MediaStore.createDeleteRequest(contentResolver, uris)
                                }
                            } else {
                                uris.forEach { contentResolver.delete(it, null, null) }
                                result.success(true)
                                return@setMethodCallHandler
                            }

                            pendingResult = result
                            startIntentSenderForResult(intent.intentSender, REQUEST_DELETE_PERMISSION, null, 0, 0, 0)
                        } catch (e: Exception) {
                            result.error("DELETE_MULTIPLE_FAILED", e.message, null)
                        }
                    } else {
                        result.error("NULL_URIS", "No URIs provided", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_DELETE_PERMISSION) {
            val success = resultCode == RESULT_OK
            pendingResult?.success(success)
            pendingResult = null
        }
    }
}
