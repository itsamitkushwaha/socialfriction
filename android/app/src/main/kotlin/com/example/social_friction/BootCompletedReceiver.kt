package com.example.social_friction

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receiver for BOOT_COMPLETED.
 *
 * Accessibility services are managed by Android and will be restored by the
 * system if enabled by the user. This receiver exists to log restart events
 * and can be extended for future boot-time initialization if required.
 */
class BootCompletedReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SocialFriction"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed; accessibility blocking service will resume if enabled")
        }
    }
}
