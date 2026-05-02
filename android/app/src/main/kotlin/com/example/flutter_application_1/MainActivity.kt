package com.example.flutter_application_1

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.provider.AlarmClock
import android.provider.ContactsContract
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mobile_agent/native_tools"
    private val PERMISSION_REQUEST_CODE = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Communication Tools
                "make_call" -> makeCall(call.argument("phoneNumber"), result)
                "send_sms" -> sendSms(call.argument("phoneNumber"), call.argument("message"), result)
                "send_email" -> sendEmail(
                    call.argument("recipient"),
                    call.argument("subject"),
                    call.argument("body"),
                    result
                )

                // File Operations
                "read_file" -> readFile(call.argument("path"), result)
                "write_file" -> writeFile(call.argument("path"), call.argument("content"), result)
                "delete_file" -> deleteFile(call.argument("path"), result)
                "list_files" -> listFiles(call.argument("directory"), result)

                // System Tools
                "get_device_info" -> getDeviceInfo(result)
                "set_alarm" -> setAlarm(
                    call.argument("hour"),
                    call.argument("minute"),
                    call.argument("message"),
                    result
                )
                "open_app" -> openApp(call.argument("packageName"), result)
                "get_battery_status" -> getBatteryStatus(result)
                "get_contacts" -> getContacts(result)
                "search_contacts" -> searchContacts(call.argument("query"), result)

                // Permissions
                "request_permissions" -> requestPermissions(call.argument("permissions"), result)
                "check_permission" -> checkPermission(call.argument("permission"), result)

                else -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // COMMUNICATION TOOLS
    // ═══════════════════════════════════════════════════════════

    private fun makeCall(phoneNumber: String?, result: MethodChannel.Result) {
        if (phoneNumber == null) {
            result.error("INVALID_ARGUMENT", "Phone number is required", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "CALL_PHONE permission required", null)
            return
        }

        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phoneNumber")
            }
            startActivity(intent)
            result.success(mapOf(
                "success" to true,
                "message" to "Call initiated to $phoneNumber"
            ))
        } catch (e: Exception) {
            result.error("CALL_FAILED", e.message, null)
        }
    }

    private fun sendSms(phoneNumber: String?, message: String?, result: MethodChannel.Result) {
        if (phoneNumber == null || message == null) {
            result.error("INVALID_ARGUMENT", "Phone number and message are required", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "SEND_SMS permission required", null)
            return
        }

        try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            result.success(mapOf(
                "success" to true,
                "message" to "SMS sent to $phoneNumber"
            ))
        } catch (e: Exception) {
            result.error("SMS_FAILED", e.message, null)
        }
    }

    private fun sendEmail(recipient: String?, subject: String?, body: String?, result: MethodChannel.Result) {
        if (recipient == null) {
            result.error("INVALID_ARGUMENT", "Recipient is required", null)
            return
        }

        try {
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = Uri.parse("mailto:")
                putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                putExtra(Intent.EXTRA_SUBJECT, subject ?: "")
                putExtra(Intent.EXTRA_TEXT, body ?: "")
            }
            startActivity(Intent.createChooser(intent, "Send Email"))
            result.success(mapOf(
                "success" to true,
                "message" to "Email client opened"
            ))
        } catch (e: Exception) {
            result.error("EMAIL_FAILED", e.message, null)
        }
    }

    // ═══════════════════════════════════════════════════════════
    // FILE OPERATIONS
    // ═══════════════════════════════════════════════════════════

    private fun readFile(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("INVALID_ARGUMENT", "File path is required", null)
            return
        }

        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist: $path", null)
                return
            }

            val content = file.readText()
            result.success(mapOf(
                "success" to true,
                "content" to content,
                "size" to file.length()
            ))
        } catch (e: Exception) {
            result.error("READ_FAILED", e.message, null)
        }
    }

    private fun writeFile(path: String?, content: String?, result: MethodChannel.Result) {
        if (path == null || content == null) {
            result.error("INVALID_ARGUMENT", "Path and content are required", null)
            return
        }

        try {
            val file = File(path)
            file.parentFile?.mkdirs()
            file.writeText(content)
            result.success(mapOf(
                "success" to true,
                "message" to "File written successfully",
                "path" to file.absolutePath
            ))
        } catch (e: Exception) {
            result.error("WRITE_FAILED", e.message, null)
        }
    }

    private fun deleteFile(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("INVALID_ARGUMENT", "File path is required", null)
            return
        }

        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist: $path", null)
                return
            }

            val deleted = file.delete()
            result.success(mapOf(
                "success" to deleted,
                "message" to if (deleted) "File deleted" else "Failed to delete file"
            ))
        } catch (e: Exception) {
            result.error("DELETE_FAILED", e.message, null)
        }
    }

    private fun listFiles(directory: String?, result: MethodChannel.Result) {
        val dir = if (directory != null) File(directory)
                  else getExternalFilesDir(null)

        if (dir == null || !dir.exists() || !dir.isDirectory) {
            result.error("INVALID_DIRECTORY", "Directory does not exist or is not a directory", null)
            return
        }

        try {
            val files = dir.listFiles()?.map { file ->
                mapOf(
                    "name" to file.name,
                    "path" to file.absolutePath,
                    "isDirectory" to file.isDirectory,
                    "size" to file.length(),
                    "lastModified" to file.lastModified()
                )
            } ?: emptyList()

            result.success(mapOf(
                "success" to true,
                "files" to files,
                "count" to files.size
            ))
        } catch (e: Exception) {
            result.error("LIST_FAILED", e.message, null)
        }
    }

    // ═══════════════════════════════════════════════════════════
    // SYSTEM TOOLS
    // ═══════════════════════════════════════════════════════════

    private fun getDeviceInfo(result: MethodChannel.Result) {
        try {
            val info = mapOf(
                "manufacturer" to Build.MANUFACTURER,
                "model" to Build.MODEL,
                "device" to Build.DEVICE,
                "brand" to Build.BRAND,
                "androidVersion" to Build.VERSION.RELEASE,
                "sdkVersion" to Build.VERSION.SDK_INT,
                "product" to Build.PRODUCT,
                "hardware" to Build.HARDWARE
            )
            result.success(mapOf(
                "success" to true,
                "deviceInfo" to info
            ))
        } catch (e: Exception) {
            result.error("INFO_FAILED", e.message, null)
        }
    }

    private fun setAlarm(hour: Int?, minute: Int?, message: String?, result: MethodChannel.Result) {
        if (hour == null || minute == null) {
            result.error("INVALID_ARGUMENT", "Hour and minute are required", null)
            return
        }

        try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, hour)
                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                putExtra(AlarmClock.EXTRA_MESSAGE, message ?: "Alarm")
                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
            }
            startActivity(intent)
            result.success(mapOf(
                "success" to true,
                "message" to "Alarm set for $hour:${minute.toString().padStart(2, '0')}"
            ))
        } catch (e: Exception) {
            result.error("ALARM_FAILED", e.message, null)
        }
    }

    private fun openApp(packageName: String?, result: MethodChannel.Result) {
        if (packageName == null) {
            result.error("INVALID_ARGUMENT", "Package name is required", null)
            return
        }

        try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                startActivity(intent)
                result.success(mapOf(
                    "success" to true,
                    "message" to "App launched: $packageName"
                ))
            } else {
                result.error("APP_NOT_FOUND", "App not installed: $packageName", null)
            }
        } catch (e: Exception) {
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun getBatteryStatus(result: MethodChannel.Result) {
        try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            val isCharging = batteryManager.isCharging

            result.success(mapOf(
                "success" to true,
                "level" to batteryLevel,
                "isCharging" to isCharging
            ))
        } catch (e: Exception) {
            result.error("BATTERY_FAILED", e.message, null)
        }
    }

    private fun getContacts(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS)
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_CONTACTS permission required", null)
            return
        }

        try {
            val contacts = mutableListOf<Map<String, String>>()
            val cursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                null, null, null, null
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val name = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME))
                    val number = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER))
                    contacts.add(mapOf("name" to name, "number" to number))
                }
            }

            result.success(mapOf(
                "success" to true,
                "contacts" to contacts,
                "count" to contacts.size
            ))
        } catch (e: Exception) {
            result.error("CONTACTS_FAILED", e.message, null)
        }
    }

    private fun searchContacts(query: String?, result: MethodChannel.Result) {
        if (query == null) {
            result.error("INVALID_ARGUMENT", "Search query is required", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS)
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_CONTACTS permission required", null)
            return
        }

        try {
            val contacts = mutableListOf<Map<String, String>>()
            val cursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                null,
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?",
                arrayOf("%$query%"),
                null
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val name = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME))
                    val number = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER))
                    contacts.add(mapOf("name" to name, "number" to number))
                }
            }

            result.success(mapOf(
                "success" to true,
                "contacts" to contacts,
                "count" to contacts.size,
                "query" to query
            ))
        } catch (e: Exception) {
            result.error("SEARCH_FAILED", e.message, null)
        }
    }

    // ═══════════════════════════════════════════════════════════
    // PERMISSION HANDLING
    // ═══════════════════════════════════════════════════════════

    private fun requestPermissions(permissions: List<String>?, result: MethodChannel.Result) {
        if (permissions == null || permissions.isEmpty()) {
            result.error("INVALID_ARGUMENT", "Permissions list is required", null)
            return
        }

        ActivityCompat.requestPermissions(
            this,
            permissions.toTypedArray(),
            PERMISSION_REQUEST_CODE
        )
        result.success(mapOf("success" to true, "message" to "Permission request sent"))
    }

    private fun checkPermission(permission: String?, result: MethodChannel.Result) {
        if (permission == null) {
            result.error("INVALID_ARGUMENT", "Permission name is required", null)
            return
        }

        val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        result.success(mapOf(
            "granted" to granted,
            "permission" to permission
        ))
    }
}
