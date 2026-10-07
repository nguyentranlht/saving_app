import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/l10n.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/screens/history.dart';
import 'package:so_thu_chi/screens/shell.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  testWidgets('App khởi động và hiển thị Shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    expect(find.byType(Shell), findsOneWidget);
  });

  testWidgets('Chuyển ngôn ngữ Việt <-> Anh', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    expect(find.text('Tổng quan'), findsOneWidget);

    await store.setLang(AppLang.en);
    await tester.pump();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Tổng quan'), findsNothing);

    // Danh mục mặc định đổi tên theo ngôn ngữ, danh mục đã đổi tên thì giữ nguyên.
    expect(S.current.catName(store.cat('food')), 'Food & drink');
    store.cat('food')!.name = 'Ăn vặt';
    expect(S.current.catName(store.cat('food')), 'Ăn vặt');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang'), 'en');
  });

  test('Khoảng thời gian của bộ lọc', () {
    final now = DateTime(2026, 10, 7, 15); // thứ Tư
    expect(periodRange(Period.today, now), (DateTime(2026, 10, 7), DateTime(2026, 10, 8)));
    expect(periodRange(Period.week, now), (DateTime(2026, 10, 5), DateTime(2026, 10, 12)));
    expect(periodRange(Period.month, now), (DateTime(2026, 10), DateTime(2026, 11)));
    expect(periodRange(Period.lastMonth, DateTime(2026, 1, 3)), (DateTime(2025, 12), DateTime(2026, 1)));
    final r = DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 3));
    expect(periodRange(Period.custom, now, r), (DateTime(2026, 9, 1), DateTime(2026, 9, 4)));
  });

  testWidgets('Lọc lịch sử theo danh mục', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    final now = DateTime.now();
    store.addTx(Tx(id: 'a', amount: 50000, type: TxType.expense, categoryId: 'food', note: 'phở', date: now));
    store.addTx(Tx(id: 'b', amount: 30000, type: TxType.expense, categoryId: 'coffee', note: 'cafe sữa', date: now));
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('cafe sữa'), findsOneWidget);

    await tester.tap(find.text('Tất cả danh mục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ăn uống').last);
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();

    expect(find.text('1 giao dịch phù hợp'), findsOneWidget);
    expect(find.textContaining('phở'), findsOneWidget);
    expect(find.textContaining('cafe sữa'), findsNothing);

    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cafe sữa'), findsOneWidget);
  });

  testWidgets('Tổng quan tính theo tháng', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    final now = DateTime.now();
    store.addTx(Tx(id: 'a', amount: 100000, type: TxType.expense, categoryId: 'food', date: now));
    store.addTx(Tx(
        id: 'b', amount: 70000, type: TxType.expense, categoryId: 'coffee',
        date: DateTime(now.year, now.month - 1, 15)));
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.pumpAndSettle();

    // Tháng này: chỉ 100k; số dư vẫn tính tất cả (−170k).
    expect(find.text('Tháng ${now.month}, ${now.year}'), findsOneWidget);
    expect(find.text('−170.000đ'), findsOneWidget);
    expect(find.text('−100.000đ'), findsNothing); // tổng chi hiển thị không dấu
    expect(find.text('100.000đ'), findsOneWidget);
    expect(find.text('1 giao dịch'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    final prev = DateTime(now.year, now.month - 1);
    expect(find.text('Tháng ${prev.month}, ${prev.year}'), findsOneWidget);
    expect(find.text('70.000đ'), findsOneWidget);
    expect(find.text('Về tháng này'), findsOneWidget);

    await tester.tap(find.text('Về tháng này'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng ${now.month}, ${now.year}'), findsOneWidget);
  });
}
