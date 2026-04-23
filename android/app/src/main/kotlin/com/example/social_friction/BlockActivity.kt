package com.example.social_friction

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity

class BlockActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Catch the package name sent by the Accessibility Service
        val blockedPackage = intent.getStringExtra("blocked_package")
        var appName = "This app"

        // 2. Translate the raw package name (e.g., com.instagram.android) into the real App Name
        if (blockedPackage != null) {
            try {
                val pm: PackageManager = packageManager
                val appInfo = pm.getApplicationInfo(blockedPackage, 0)
                appName = pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                // Fallback to the package name just in case the OS hides the label
                appName = blockedPackage
            }
        }

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

        // 3. Inject the specific app name into the message
        val message = TextView(this).apply {
            text = "$appName is blocked to reduce distractions."
            textSize = 15f
            setTextColor(Color.parseColor("#B0BEC5"))
            gravity = Gravity.CENTER
        }

        root.addView(title)
        root.addView(message)

        setContentView(root)

        // 4. Modern Android back-button handling
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                // Instantly boot the user back to the home screen if they try to swipe back
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
            }
        })
    }
}