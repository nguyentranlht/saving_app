import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/backup.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/screens/budget.dart';
import 'package:so_thu_chi/store.dart';

Future<AppStore> emptyStore() async {
  SharedPreferences.setMockInitialValues({'lang': 'vi'});
  return AppStore.load();
}

Tx spend(String id, int amount, DateTime d, {String cat = 'food', TxType type = TxType.expense}) =>
    Tx(id: id, amount: amount, type: type, categoryId: cat, date: d);

void main() {
  test('Đã chi chỉ tính khoản chi trong đúng tháng và đúng danh mục', () async {
    final store = await emptyStore();
    store.addTx(spend('a', 1000000, DateTime(2026, 10, 1)));
    store.addTx(spend('b', 500000, DateTime(2026, 10, 31, 23, 59)));
    store.addTx(spend('c', 700000, DateTime(2026, 9, 30))); // tháng trước
    store.addTx(spend('d', 200000, DateTime(2026, 10, 5), cat: 'coffee'));
    store.addTx(spend('e', 9000000, DateTime(2026, 10, 5), cat: 'salary', type: TxType.income));
    expect(store.spentIn('food', DateTime(2026, 10, 15)), 1500000);
    expect(store.spentIn(AppStore.totalBudgetKey, DateTime(2026, 10, 15)), 1700000);
    expect(store.spentIn('food', DateTime(2026, 9, 1)), 700000);
  });

  test('Cảnh báo từ 80% và khi vượt, ưu tiên danh mục rồi mới tới tổng', () async {
    final store = await emptyStore();
    final m = DateTime(2026, 10);
    store.setBudget('food', 3000000);
    store.addTx(spend('a', 2000000, DateTime(2026, 10, 2)));
    expect(budgetWarning(store, 'food', m), isNull); // 67%

    store.addTx(spend('b', 500000, DateTime(2026, 10, 3)));
    expect(budgetWarning(store, 'food', m), (text: 'Ăn uống đã dùng 83% ngân sách tháng', over: false));

    store.addTx(spend('c', 700000, DateTime(2026, 10, 4)));
    expect(budgetWarning(store, 'food', m), (text: 'Ăn uống đã vượt ngân sách tháng 200k', over: true));

    // Danh mục không có hạn mức -> xét hạn mức tổng.
    store.setBudget(AppStore.totalBudgetKey, 4000000);
    store.addTx(spend('d', 300000, DateTime(2026, 10, 5), cat: 'coffee'));
    expect(budgetWarning(store, 'coffee', m)!.text, 'Tổng chi tiêu đã dùng 88% ngân sách tháng');
  });

  test('Bỏ hạn mức, xóa danh mục, lưu và sao lưu', () async {
    final store = await emptyStore();
    store.setBudget('food', 3000000);
    store.setBudget('coffee', 500000);
    store.setBudget('coffee', null);
    expect(store.budgets, {'food': 3000000});

    await Future<void>.delayed(Duration.zero);
    expect((await AppStore.load()).budgets, {'food': 3000000});

    final b = Backup.parse(store.toBackup().encode());
    expect(b.budgets, {'food': 3000000});

    store.upsertCategory(Category(id: 'gym', name: 'Gym', icon: 'sport', color: 0xFF14B8A6, type: TxType.expense));
    store.setBudget('gym', 1);
    store.deleteCategory('gym');
    expect(store.budgets.containsKey('gym'), isFalse);
  });

  testWidgets('Đặt hạn mức rồi ghi khoản chi thì hiện cảnh báo', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = await emptyStore();
    await tester.pumpWidget(SoThuChiApp(store: store));

    // Từ thẻ gợi ý ở Tổng quan -> màn Ngân sách -> đặt 100k cho Ăn uống.
    await tester.tap(find.text('Ngân sách'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '100000');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.budgets['food'], 100000);
    expect(find.text('Còn 100k'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    // Ghi 90k Ăn uống -> 90% -> cảnh báo.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '90000');
    await tester.pump();
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pump();
    expect(find.text('Ăn uống đã dùng 90% ngân sách tháng'), findsWidgets); // lúc chuyển màn có thể vẽ ở cả 2 màn
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Ngân sách tháng'), findsOneWidget); // thẻ ở Tổng quan
  });
}
