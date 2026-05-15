package com.example.weather_note_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WeatherWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.weather_widget_layout).apply {
                val city = widgetData.getString("widget_city", "City")
                val temp = widgetData.getString("widget_temp", "--°")
                val emoji = widgetData.getString("widget_emoji", "🌤️")
                val note = widgetData.getString("widget_note", "No plans for today")

                setTextViewText(R.id.widget_city, city)
                setTextViewText(R.id.widget_temp, temp)
                setTextViewText(R.id.widget_emoji, emoji)
                setTextViewText(R.id.widget_note, note)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
