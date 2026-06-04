package com.example.weather_note_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WeatherWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val themeIndex = widgetData.getInt("widget_theme", 0)
        val bgDrawable = when (themeIndex) {
            1 -> R.drawable.widget_glass_bg_midnight
            2 -> R.drawable.widget_glass_bg_emerald
            3 -> R.drawable.widget_glass_bg_rose
            4 -> R.drawable.widget_glass_bg_amber
            else -> R.drawable.widget_glass_bg_frost
        }
        val accentColor = when (themeIndex) {
            1 -> Color.parseColor("#6B8AFF")
            2 -> Color.parseColor("#4ADE80")
            3 -> Color.parseColor("#F472B6")
            4 -> Color.parseColor("#FBBF24")
            else -> Color.parseColor("#4f6ef7")
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.weather_widget_layout).apply {
                setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

                val city = widgetData.getString("widget_city", "City")
                val temp = widgetData.getString("widget_temp", "--\u00B0")
                val emoji = widgetData.getString("widget_emoji", "\u2601\uFE0F")
                val note = widgetData.getString("widget_note", "No plans for today")

                setTextViewText(R.id.widget_city, city)
                setTextViewText(R.id.widget_temp, temp)
                setTextViewText(R.id.widget_emoji, emoji)
                setTextViewText(R.id.widget_note, note)

                setTextColor(R.id.widget_temp, accentColor)

                for (i in 0 until 6) {
                    val time = widgetData.getString("widget_fc_${i}_time", "")
                    val t = widgetData.getString("widget_fc_${i}_temp", "")
                    val e = widgetData.getString("widget_fc_${i}_emoji", "")

                    val timeId = context.resources.getIdentifier("widget_fc_${i}_time", "id", context.packageName)
                    val tempId = context.resources.getIdentifier("widget_fc_${i}_temp", "id", context.packageName)
                    val emojiId = context.resources.getIdentifier("widget_fc_${i}_emoji", "id", context.packageName)

                    if (timeId != 0) setTextViewText(timeId, time)
                    if (tempId != 0) setTextViewText(tempId, t)
                    if (emojiId != 0) setTextViewText(emojiId, e)
                    if (tempId != 0) setTextColor(tempId, accentColor)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
