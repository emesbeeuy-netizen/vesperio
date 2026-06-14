package com.vesperio.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives BOOT_COMPLETED and launches the app's Flutter engine in the
 * background so SmartAlarmService can reschedule pending alarms.
 *
 * Flutter-side rescheduling is triggered from main() via
 * SmartAlarmService().rescheduleAll() after NotificationService.initialize().
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Launch the main activity minimised so Flutter can reschedule alarms.
            val launch = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("reschedule_alarms", true)
            }
            context.startActivity(launch)
        }
    }
}
