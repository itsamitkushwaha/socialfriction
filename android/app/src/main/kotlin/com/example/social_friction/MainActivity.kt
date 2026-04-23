package com.example.social_friction

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "social_friction/blocker")
            .setMethodCallHandler { call, result ->
                if (call.method == "updateRules") {
                    try {
                        val rules = call.arguments as List<Map<String, Any>>
                        saveRules(rules)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else if (call.method == "openAccessibilitySettings") {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                } else if (call.method == "isAccessibilityServiceEnabled") {
                    result.success(isAccessibilityServiceEnabled())
                } else if (call.method == "checkOverlayPermission") {
                    result.success(android.provider.Settings.canDrawOverlays(this))
                } else if (call.method == "requestOverlayPermission") {
                    try {
                        val intent = Intent(
                            android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveRules(rules: List<Map<String, Any>>) {
        val prefs = getSharedPreferences("block_rules", Context.MODE_PRIVATE)
        // IMPORTANT: Do NOT use JSONArray(rules).toString() — it shallow-serializes
        // Map objects via toString(), producing "{key=value}" garbage instead of JSON.
        // We must build the JSONArray manually to produce valid JSON that the service can parse.
        val jsonArray = org.json.JSONArray()
        for (rule in rules) {
            val obj = org.json.JSONObject()
            for ((key, value) in rule) {
                when (value) {
                    is Boolean -> obj.put(key, value)
                    is Int -> obj.put(key, value)
                    is Long -> obj.put(key, value)
                    is Double -> obj.put(key, value)
                    is String -> obj.put(key, value)
                    null -> obj.put(key, org.json.JSONObject.NULL)
                    else -> obj.put(key, value.toString())
                }
            }
            jsonArray.put(obj)
        }
        prefs.edit().putString("rules", jsonArray.toString()).apply()
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        var accessibilityEnabled = 0
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                this.contentResolver,
                android.provider.Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            // Ignore
        }
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                this.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                // More permissive match to handle variations in flattening across OEMs
                return settingValue.contains(packageName) && settingValue.contains("AppBlockAccessibilityService")
            }
        }
        return false
    }
}
