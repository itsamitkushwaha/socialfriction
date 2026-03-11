package com.example.social_friction

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class BlockOverlayActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val blockedPackage = intent.getStringExtra("blocked_package") ?: "Unknown App"
        
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0D1B2A")) // Navy background
            setPadding(64, 64, 64, 64)
        }

        val title = TextView(this).apply {
            text = "Social Friction"
            textSize = 24f
            setTextColor(Color.parseColor("#F5A623")) // Orange accent
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }

        val message = TextView(this).apply {
            text = "This app is currently blocked."
            textSize = 20f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }

        val packageNameView = TextView(this).apply {
            text = blockedPackage
            textSize = 14f
            setTextColor(Color.parseColor("#7C5CBF")) // Purple primary
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 64)
        }

        val homeButton = Button(this).apply {
            text = "Go Back Home"
            setBackgroundColor(Color.parseColor("#7C5CBF"))
            setTextColor(Color.WHITE)
            setOnClickListener {
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
                finish()
            }
        }

        layout.addView(title)
        layout.addView(message)
        layout.addView(packageNameView)
        layout.addView(homeButton)

        setContentView(layout)
    }

    override fun onBackPressed() {
        // Prevent back button from dismissing the block screen and returning to the blocked app
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }
}
