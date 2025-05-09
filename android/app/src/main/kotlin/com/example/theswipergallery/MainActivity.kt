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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "delete") {
                    val uriString = call.argument<String>("uri")
                    val moveToTrash = call.argument<Boolean>("moveToTrash") ?: false

                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            Log.d("MainActivity", "Acción sobre URI: $uri (moveToTrash=$moveToTrash)")

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                // Android 11+ (API 30+): papelera o eliminación
                                val uris = arrayListOf(uri)
                                val pendingIntent = if (moveToTrash) {
                                    Log.d("MainActivity", "Usando createTrashRequest")
                                    MediaStore.createTrashRequest(contentResolver, uris, true)
                                } else {
                                    Log.d("MainActivity", "Usando createDeleteRequest")
                                    MediaStore.createDeleteRequest(contentResolver, uris)
                                }

                                pendingResult = result
                                startIntentSenderForResult(
                                    pendingIntent.intentSender,
                                    REQUEST_DELETE_PERMISSION,
                                    null,
                                    0,
                                    0,
                                    0
                                )

                            } else {
                                // Android 10 o menor: eliminación directa
                                Log.d("MainActivity", "Borrado directo para Android < 11")
                                val rows = contentResolver.delete(uri, null, null)
                                result.success(rows > 0)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Error al procesar URI: ${e.message}")
                            result.error("DELETE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("NULL_URI", "Falta la URI", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_DELETE_PERMISSION) {
            val success = resultCode == RESULT_OK
            Log.d("MainActivity", "Resultado de confirmación: $success")
            pendingResult?.success(success)
            pendingResult = null
        }
    }
}
