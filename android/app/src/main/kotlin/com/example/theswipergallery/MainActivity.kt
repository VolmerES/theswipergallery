package com.example.theswipergallery

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.theswipergallery/delete"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_DELETE_PERMISSION = 0

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "delete") {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            pendingResult = result
                            
                            // On Android 11+ use trash/delete request
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                val uris = listOf(uri)
                                val req = MediaStore.createTrashRequest(contentResolver, uris, true)
                                startIntentSenderForResult(
                                    req.intentSender,
                                    REQUEST_DELETE_PERMISSION,
                                    null,  // fillInIntent
                                    0,     // flagsMask
                                    0,     // flagsValues
                                    0      // extraFlags
                                )
                                // No definimos el resultado aquí, lo haremos en onActivityResult
                            } else {
                                // Fallback: direct delete via ContentResolver
                                val rows = contentResolver.delete(uri, null, null)
                                result.success(rows > 0)
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.error("DELETE_FAILED", e.message, null)
                        }
                    } else {
                        result.error("NULL_URI", "No URI provided", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
    
    // Manejar el resultado de la solicitud de eliminación
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_DELETE_PERMISSION) {
            // Validamos el resultado del intent de eliminación
            val success = resultCode == RESULT_OK
            pendingResult?.success(success)
            pendingResult = null
        }
    }
}