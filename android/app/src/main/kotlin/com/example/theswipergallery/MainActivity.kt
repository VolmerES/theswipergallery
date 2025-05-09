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
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.theswipergallery/delete"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_DELETE_PERMISSION = 2023

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "delete") {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            Log.d("MainActivity", "Attempting to delete: $uriString")
                            val uri = Uri.parse(uriString)
                            pendingResult = result
                            
                            // En Android 10+ (API 29+) debemos usar MediaStore.createDeleteRequest
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                Log.d("MainActivity", "Using MediaStore.createDeleteRequest for Android 11+")
                                val uris = arrayListOf(uri)
                                
                                // IMPORTANTE: usamos createDeleteRequest en lugar de createTrashRequest
                                val req = MediaStore.createDeleteRequest(contentResolver, uris)
                                
                                try {
                                    startIntentSenderForResult(
                                        req.intentSender,
                                        REQUEST_DELETE_PERMISSION,
                                        null,  // fillInIntent
                                        0,     // flagsMask
                                        0,     // flagsValues
                                        0      // extraFlags
                                    )
                                    // El resultado se maneja en onActivityResult
                                } catch (e: Exception) {
                                    Log.e("MainActivity", "Error al iniciar IntentSender: ${e.message}")
                                    result.error("DELETE_FAILED", "Error al iniciar el diálogo de confirmación: ${e.message}", null)
                                }
                            } else {
                                // Para versiones anteriores a Android 10
                                Log.d("MainActivity", "Using ContentResolver.delete for older Android")
                                val rows = contentResolver.delete(uri, null, null)
                                Log.d("MainActivity", "Delete result: $rows rows affected")
                                result.success(rows > 0)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Exception during delete: ${e.message}")
                            e.printStackTrace()
                            result.error("DELETE_FAILED", e.message, null)
                        }
                    } else {
                        Log.e("MainActivity", "Null URI provided")
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
        
        Log.d("MainActivity", "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        
        if (requestCode == REQUEST_DELETE_PERMISSION) {
            // RESULT_OK significa que el usuario confirmó la eliminación
            val success = resultCode == RESULT_OK
            Log.d("MainActivity", "Delete permission result: $success")
            pendingResult?.success(success)
            pendingResult = null
        }
    }
}