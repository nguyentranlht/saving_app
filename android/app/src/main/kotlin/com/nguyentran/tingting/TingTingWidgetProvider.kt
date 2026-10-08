package com.nguyentran.tingting

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget màn hình chính: chi tiêu tháng này và số dư.
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
    // home_widget lưu Double dưới dạng bit của Long.
    val ratio = Double.fromBits(widgetData.getLong("tt_budget_ratio", (-1.0).toRawBits()))

    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.ting_ting_widget)
      v.setTextViewText(R.id.tt_month, s("tt_month", ""))
      v.setTextViewText(R.id.tt_spent_label, s("tt_spent_label", "Chi trong tháng"))
      v.setTextViewText(R.id.tt_spent, s("tt_spent", "0đ"))
      v.setTextViewText(R.id.tt_balance, "${s("tt_balance_label", "Số dư hiện tại")}: ${s("tt_balance", "0đ")}")

      // Ngân sách tổng: chỉ hiện khi đã đặt.
      val hasBudget = ratio >= 0
      v.setViewVisibility(R.id.tt_budget_bar, if (hasBudget) View.VISIBLE else View.GONE)
      v.setViewVisibility(R.id.tt_budget, if (hasBudget) View.VISIBLE else View.GONE)
      if (hasBudget) {
        v.setProgressBar(R.id.tt_budget_bar, 100, (ratio.coerceIn(0.0, 1.0) * 100).toInt(), false)
        v.setTextViewText(R.id.tt_budget, s("tt_budget", ""))
      }

      // Chạm vào widget để mở app.
      v.setOnClickPendingIntent(R.id.tt_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}
