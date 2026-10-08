package com.nguyentran.tingting

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget màn hình chính, giống thẻ số dư ở Tổng quan: số dư, nhãn thu/chi, hai ô thu / chi tháng này (mũi tên + số tiền).
 * Số liệu do app ghi sẵn (đã định dạng) qua package home_widget, xem lib/home_widget_sync.dart.
 */
class TingTingWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    fun s(key: String, fallback: String) = widgetData.getString(key, null) ?: fallback
    val trend = s("tt_trend", "")

    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.ting_ting_widget)
      v.setTextViewText(R.id.tt_balance_label, s("tt_balance_label", "Số dư hiện tại"))
      v.setTextViewText(R.id.tt_balance, s("tt_balance", "0đ"))
      v.setTextViewText(R.id.tt_income, s("tt_income", "0đ"))
      v.setTextViewText(R.id.tt_spent, s("tt_spent", "0đ"))

      // Góc phải: nhãn "Chi đang nhiều hơn thu" / "Thu đang nhiều hơn chi", chưa có giao dịch thì hiện số giao dịch.
      when (trend) {
        "over" -> {
          v.setTextViewText(R.id.tt_badge, "⚠ ${s("tt_trend_text", "")}")
          v.setTextColor(R.id.tt_badge, context.getColor(R.color.tt_trend_over))
          v.setInt(R.id.tt_badge, "setBackgroundResource", R.drawable.ting_ting_widget_trend_over)
        }
        "ok" -> {
          v.setTextViewText(R.id.tt_badge, "✓ ${s("tt_trend_text", "")}")
          v.setTextColor(R.id.tt_badge, context.getColor(R.color.tt_trend_ok))
          v.setInt(R.id.tt_badge, "setBackgroundResource", R.drawable.ting_ting_widget_trend_ok)
        }
        else -> {
          v.setTextViewText(R.id.tt_badge, s("tt_count", ""))
          v.setTextColor(R.id.tt_badge, context.getColor(R.color.tt_white_70))
          v.setInt(R.id.tt_badge, "setBackgroundResource", 0)
        }
      }

      // Chạm vào widget để mở app.
      v.setOnClickPendingIntent(R.id.tt_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}
