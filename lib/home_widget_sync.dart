import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'format.dart';
import 'l10n.dart';
import 'models.dart';
import 'store.dart';

/// App Group dùng chung giữa app và widget iOS (Android không cần).
const kAppGroupId = 'group.com.nguyentran.tingting';
const _iOSWidget = 'TingTingWidget'; // kind trong ios/TingTingWidget/TingTingWidget.swift
const _androidWidget = 'TingTingWidgetProvider'; // android/app/src/main/kotlin/.../TingTingWidgetProvider.kt

/// Số liệu tháng này cho widget, đã định dạng sẵn để widget chỉ việc hiển thị.
/// Khóa giữ nguyên tên vì widget iOS / Android đọc đúng các khóa này.
Map<String, Object> widgetData(AppStore store, [DateTime? now]) {
  final s = S.current;
  final n = now ?? DateTime.now();
  final spent = store.spentIn(AppStore.totalBudgetKey, n);
  final from = DateTime(n.year, n.month), to = DateTime(n.year, n.month + 1);
  final income = store.total(TxType.income, from: from, to: to);
  final balance = store.balance;
  final limit = store.budgets[AppStore.totalBudgetKey];
  final count = store.txs.where((t) => !t.date.isBefore(from) && t.date.isBefore(to)).length;
  // Giống nhãn trên thẻ số dư ở Tổng quan: chi > thu thì cảnh báo; có giao dịch và thu ≥ chi thì khen.
  final trend = spent > income ? 'over' : (count > 0 ? 'ok' : '');
  return {
    'tt_month': s.monthYear(n),
    'tt_count': s.txCount(count),
    'tt_trend': trend,
    'tt_trend_text': trend == 'over' ? s.spendingOver : (trend == 'ok' ? s.incomeOver : ''),
    'tt_spent_label': s.monthExpense,
    'tt_spent': vnd(spent),
    'tt_income_label': s.monthIncome,
    'tt_income': vnd(income),
    'tt_balance_label': s.balance,
    'tt_balance': vnd(balance),
    // Ngân sách tổng: tỉ lệ đã dùng (-1 = chưa đặt) và dòng mô tả.
    'tt_budget_ratio': limit == null ? -1.0 : spent / limit,
    'tt_budget': limit == null
        ? ''
        : (spent > limit ? s.overAmount(compact(spent - limit)) : s.leftAmount(compact(limit - spent))),
  };
}

bool _ready = false;

/// Ghi số liệu cho widget rồi báo widget vẽ lại. Bỏ qua lỗi (vd. khi chạy test, chưa có plugin).
Future<void> syncHomeWidget(AppStore store) async {
  if (kIsWeb) return;
  try {
    if (!_ready) {
      await HomeWidget.setAppGroupId(kAppGroupId);
      _ready = true;
    }
    for (final e in widgetData(store).entries) {
      await HomeWidget.saveWidgetData(e.key, e.value);
    }
    await HomeWidget.updateWidget(iOSName: _iOSWidget, androidName: _androidWidget);
  } catch (e) {
    debugPrint('Cập nhật widget lỗi: $e');
  }
}

/// Cập nhật widget mỗi khi dữ liệu thay đổi (gom các thay đổi liên tiếp lại thành một lần).
void bindHomeWidget(AppStore store) {
  var pending = false;
  void schedule() {
    if (pending) return;
    pending = true;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      pending = false;
      syncHomeWidget(store);
    });
  }

  store.addListener(schedule);
  schedule();
}
