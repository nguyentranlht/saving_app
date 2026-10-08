import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/home_widget_sync.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  test('Số liệu widget: tháng này, số dư cộng dồn, ngân sách tổng', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    final now = DateTime(2026, 10, 15, 12);
    store.addTx(Tx(id: 'a', amount: 3250000, type: TxType.expense, categoryId: 'food', date: DateTime(2026, 10, 2)));
    store.addTx(Tx(id: 'b', amount: 15000000, type: TxType.income, categoryId: 'salary', date: DateTime(2026, 10, 5)));
    store.addTx(Tx(id: 'c', amount: 1000000, type: TxType.expense, categoryId: 'food', date: DateTime(2026, 9, 20)));

    var d = widgetData(store, now);
    expect(d['tt_month'], 'Tháng 10, 2026');
    expect(d['tt_spent'], '3.250.000đ'); // chỉ tháng 10
    expect(d['tt_income'], '+15.000.000đ');
    expect(d['tt_balance'], '10.750.000đ'); // cộng dồn mọi tháng
    expect(d['tt_budget_ratio'], -1.0); // chưa đặt ngân sách tổng
    expect(d['tt_budget'], '');

    store.setBudget(AppStore.totalBudgetKey, 5000000);
    d = widgetData(store, now);
    expect(d['tt_budget_ratio'], 0.65);
    expect(d['tt_budget'], 'Còn 1,8tr');

    store.setBudget(AppStore.totalBudgetKey, 3000000);
    expect(widgetData(store, now)['tt_budget'], 'Vượt 250k');
  });

  test('Không có plugin (khi chạy test) thì bỏ qua, không làm lỗi app', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    await syncHomeWidget(store); // không ném lỗi
  });
}
