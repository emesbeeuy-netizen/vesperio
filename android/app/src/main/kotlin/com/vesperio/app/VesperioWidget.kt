package com.vesperio.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class VesperioWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val KEY_SOUND = "widgetCurrentSound"
        private const val KEY_PLAYING = "widgetIsPlaying"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val soundName = prefs.getString(KEY_SOUND, "Tap to play") ?: "Tap to play"
            val isPlaying = prefs.getBoolean(KEY_PLAYING, false)

            val views = RemoteViews(context.packageName, R.layout.vesperio_widget)
            views.setTextViewText(R.id.widget_sound_name, soundName)
            views.setTextViewText(
                R.id.widget_status,
                if (isPlaying) "Now playing" else "Not playing"
            )
            views.setImageViewResource(
                R.id.widget_play_button,
                if (isPlaying) android.R.drawable.ic_media_pause
                else android.R.drawable.ic_media_play
            )

            // Tap anywhere → open the app
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_play_button, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
