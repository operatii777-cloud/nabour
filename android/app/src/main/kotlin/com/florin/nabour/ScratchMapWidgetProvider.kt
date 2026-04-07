package com.florin.nabour

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Numele clasei rămâne [ScratchMapWidgetProvider] astfel încât widget-urile deja plasate pe ecran
 * să continue să funcționeze după update (Android le leagă de componenta provider).
 */
class ScratchMapWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.explorari_widget_layout).apply {
                val tiles = widgetData.getString("explorari_tiles", null)
                    ?: widgetData.getString("scratch_tiles", null)
                    ?: "0"
                val pct = widgetData.getString("explorari_pct", null)
                    ?: widgetData.getString("scratch_pct", null)
                    ?: "0"
                setTextViewText(R.id.widget_title, "Nabour · Explorări")
                setTextViewText(R.id.widget_message, "$tiles zone · $pct%")
                val pending = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
