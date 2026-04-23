package com.example.social_friction

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONArray
import java.time.LocalTime
import android.app.usage.UsageStatsManager

data class BlockRuleNative(
    val packageName: String,
    val isEnabled: Boolean,
    val blockType: String,
    val scheduleStart: String?,
    val scheduleEnd: String?,
    val dailyLimitMinutes: Int?
) {
    companion object {
        fun fromJson(obj: org.json.JSONObject): BlockRuleNative {
            return BlockRuleNative(
                packageName = obj.optString("packageName"),
                isEnabled = obj.optBoolean("isEnabled", false),
                blockType = obj.optString("blockType", "permanent"),
                scheduleStart = obj.optString("scheduleStart", null).takeIf { it != "null" && it.isNotBlank() },
                scheduleEnd = obj.optString("scheduleEnd", null).takeIf { it != "null" && it.isNotBlank() },
                dailyLimitMinutes = if (obj.has("dailyLimitMinutes") && !obj.isNull("dailyLimitMinutes")) obj.optInt("dailyLimitMinutes") else null
            )
        }
    }
}

class AppBlockAccessibilityService : AccessibilityService() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isOverlayShowing = false
    private var currentBlockedPackage: String? = null
    private val handler = Handler(Looper.getMainLooper())

    // Packages that should NEVER trigger the block overlay — launchers & system UI.
    // These are ignored so navigating home doesn't stall or show a stale overlay.
    private val ignoredPackages = setOf(
        "com.android.systemui",
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        "com.google.android.apps.nexuslauncher",
        "com.mi.android.globallauncher",     // Xiaomi / POCO actual launcher package
        "com.miui.home",                     // Xiaomi MIUI alt launcher
        "com.mi.appfinder",                  // Xiaomi App Finder
        "android.miui.poco.launcher.res",    // POCO launcher
        "com.huawei.android.launcher",       // Huawei
        "com.sec.android.app.launcher",      // Samsung
        "com.oppo.launcher",                 // OPPO
        "com.vivo.launcher",                 // Vivo
        "com.oneplus.launcher",              // OnePlus
        "com.zte.mifavor.launcher",          // ZTE
        "com.transsion.launcher",            // Tecno/Infinix
        "com.bbk.launcher2",                 // Vivo alt
        "com.realme.launcher"                // Realme
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d("BLOCK_ENGINE", "Accessibility Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Only act on true window focus/foreground changes
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        val myPackage = applicationContext.packageName

        // When navigating to our own app, remove any overlay that might be up
        if (packageName == myPackage) {
            if (isOverlayShowing) hideOverlay()
            return
        }

        // Ignore all launchers and system UI — when the user goes home, just remove overlay
        if (ignoredPackages.contains(packageName) || packageName.contains("launcher", ignoreCase = true)) {
            if (isOverlayShowing) hideOverlay()
            return
        }

        Log.d("BLOCK_ENGINE", "Window state changed to: $packageName")

        val rules = loadRules()
        var matchedRule = false

        for (rule in rules) {
            if (rule.packageName == packageName && rule.isEnabled) {
                if (shouldBlock(rule)) {
                    matchedRule = true
                    Log.d("BLOCK_ENGINE", "Matched block rule for: $packageName")

                    if (!isOverlayShowing || currentBlockedPackage != packageName) {
                        // Send the user home first, then — after a short delay — show overlay
                        // so the overlay appears cleanly over the home screen rather than
                        // racing against the app's own drawing.
                        performGlobalAction(GLOBAL_ACTION_HOME)
                        handler.postDelayed({
                            showOverlay(packageName)
                        }, 150)
                    } else {
                        Log.d("BLOCK_ENGINE", "Overlay already showing for $packageName")
                    }
                    break
                }
            }
        }

        // If we switched to an unblocked app, remove the overlay
        if (!matchedRule) {
            if (isOverlayShowing && packageName != currentBlockedPackage) {
                hideOverlay()
            }
        }
    }

    override fun onInterrupt() {
        hideOverlay()
    }

    private fun showOverlay(packageName: String) {
        // If overlay is already showing for the same package, do nothing
        if (isOverlayShowing && currentBlockedPackage == packageName) return

        // Clean up any previous overlay before adding a new one
        if (isOverlayShowing) {
            hideOverlay()
        }

        currentBlockedPackage = packageName

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR,
            PixelFormat.TRANSLUCENT
        )

        // Build the overlay UI programmatically to avoid theme/inflation issues
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0A1628"))
            setPadding(72, 72, 72, 72)
        }

        val title = TextView(this).apply {
            text = "Stay Focused"
            textSize = 28f
            setTextColor(Color.parseColor("#F5A623"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }

        val appName = packageName.split(".").lastOrNull()?.replaceFirstChar { it.uppercase() } ?: packageName
        val message = TextView(this).apply {
            text = "$appName is blocked to help you stay focused."
            textSize = 15f
            setTextColor(Color.parseColor("#B0BEC5"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }

        val homeButton = Button(this).apply {
            text = "Go Home"
            setBackgroundColor(Color.parseColor("#1E3A5F"))
            setTextColor(Color.WHITE)
            setOnClickListener {
                performGlobalAction(GLOBAL_ACTION_HOME)
                hideOverlay()
            }
        }

        root.addView(title)
        root.addView(message)
        root.addView(homeButton)

        overlayView = root

        try {
            windowManager?.addView(overlayView, layoutParams)
            isOverlayShowing = true
            Log.d("BLOCK_ENGINE", "Overlay shown for $packageName")
        } catch (e: Exception) {
            Log.e("BLOCK_ENGINE", "Failed to add overlay view", e)
            isOverlayShowing = false
            overlayView = null
            currentBlockedPackage = null
        }
    }

    private fun hideOverlay() {
        if (!isOverlayShowing && overlayView == null) return

        val viewToRemove = overlayView
        isOverlayShowing = false
        overlayView = null
        currentBlockedPackage = null

        if (viewToRemove != null) {
            try {
                windowManager?.removeView(viewToRemove)
                Log.d("BLOCK_ENGINE", "Overlay removed")
            } catch (e: Exception) {
                Log.e("BLOCK_ENGINE", "Failed to remove overlay view: ${e.message}")
            }
        }
    }

    private fun loadRules(): List<BlockRuleNative> {
        val prefs = getSharedPreferences("block_rules", MODE_PRIVATE)
        val json = prefs.getString("rules", "[]") ?: "[]"
        val rules = mutableListOf<BlockRuleNative>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                rules.add(BlockRuleNative.fromJson(obj))
            }
            Log.d("BLOCK_ENGINE", "Loaded ${rules.size} rules from prefs")
        } catch (e: Exception) {
            Log.e("BLOCK_ENGINE", "Failed to load rules: ${e.message}. Raw JSON: $json")
        }
        return rules
    }

    private fun shouldBlock(rule: BlockRuleNative): Boolean {
        if (rule.blockType == "permanent")
            return true

        if (rule.blockType == "schedule" && rule.scheduleStart != null && rule.scheduleEnd != null) {
            try {
                val now = LocalTime.now()
                val start = LocalTime.parse(rule.scheduleStart)
                val end = LocalTime.parse(rule.scheduleEnd)
                return if (start.isBefore(end)) {
                    now.isAfter(start) && now.isBefore(end)
                } else {
                    now.isAfter(start) || now.isBefore(end) // Overnight
                }
            } catch (e: Exception) {
                Log.e("BLOCK_ENGINE", "Failed to parse schedule", e)
            }
        }

        if (rule.blockType == "dailyLimit" && rule.dailyLimitMinutes != null) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            val start = end - 24 * 60 * 60 * 1000
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                start,
                end
            )
            val usageStat = stats?.find { it.packageName == rule.packageName }
            val usageMins = (usageStat?.totalTimeInForeground ?: 0) / (1000 * 60)
            if (usageMins >= rule.dailyLimitMinutes) {
                return true
            }
        }

        return false
    }
}