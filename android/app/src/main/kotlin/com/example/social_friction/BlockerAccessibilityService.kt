package com.example.social_friction

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class BlockerAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)

        // Mark accessibility service as enabled so Flutter knows
        prefs.edit().putBoolean("flutter.accessibility_service_enabled", true).apply()

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Skip our own app
        if (packageName == applicationContext.packageName) return

        // Get the list of blocked packages saved by Flutter
        val blockedRaw = prefs.getString("flutter.native_blocked_packages", null)
        Log.d("SocialFriction", "App opened: $packageName. Raw rules: $blockedRaw")
        if (blockedRaw == null) return

        // Flutter saves StringSet as a JSON-like string list. Parse it:
        val blockedList = parseFlutterStringList(blockedRaw)

        if (blockedList.contains(packageName)) {
            Log.d("SocialFriction", "Blocking app: $packageName")
            launchBlockOverlay(packageName)
        }
    }

    private fun parseFlutterStringList(raw: String): List<String> {
        return try {
            raw.trim()
                .removePrefix("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu") // Handle old flutter prefix
                .removePrefix("[")
                .removeSuffix("]")
                .split(",")
                .map { it.trim().removeSurrounding("\"") }
                .filter { it.isNotEmpty() }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun launchBlockOverlay(packageName: String) {
        val intent = Intent(this, BlockOverlayActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("blocked_package", packageName)
            putExtra("show_block_overlay", true)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {
        prefs.edit().putBoolean("flutter.accessibility_service_enabled", false).apply()
    }

    override fun onDestroy() {
        super.onDestroy()
        prefs.edit().putBoolean("flutter.accessibility_service_enabled", false).apply()
    }
}
