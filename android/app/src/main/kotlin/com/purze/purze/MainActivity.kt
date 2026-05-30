package com.purze.purze

import android.database.Cursor
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "purze/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSmsInbox") {
                val since = call.argument<Long>("since")
                try {
                    val uriSms = Uri.parse("content://sms/inbox")
                    val projection = arrayOf("_id", "address", "body", "date")
                    val sort = "date DESC"
                    val cursor: Cursor? = contentResolver.query(uriSms, projection, null, null, sort)
                    val list = ArrayList<HashMap<String, Any?>>()
                    cursor?.use {
                        while (it.moveToNext()) {
                            val id = it.getString(it.getColumnIndexOrThrow("_id"))
                            val address = it.getString(it.getColumnIndexOrThrow("address"))
                            val body = it.getString(it.getColumnIndexOrThrow("body"))
                            val date = it.getLong(it.getColumnIndexOrThrow("date"))
                            if (since != null && date <= since) continue
                            val map = HashMap<String, Any?>()
                            map["id"] = id
                            map["address"] = address
                            map["body"] = body
                            map["date"] = date
                            list.add(map)
                        }
                    }
                    result.success(list)
                } catch (e: Exception) {
                    result.error("sms_error", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}

