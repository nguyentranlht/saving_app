import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/screens/stats.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  test('Khoảng thời gian của từng kỳ', () {
    final now = DateTime(2026, 1, 7, 10); // thứ Tư
    expect(statsRange(StatsMode.week, 0, now), (DateTime(2026, 1, 5), DateTime(2026, 1, 12)));
    expect(statsRange(StatsMode.week, 2, now), (DateTime(2025, 12, 22), DateTime(2025, 12, 29)));
    expect(statsRange(StatsMode.month, 0, now), (DateTime(2026, 1), DateTime(2026, 2)));
    expect(statsRange(StatsMode.month, 1, now), (DateTime(2025, 12), DateTime(2026, 1)));
    expect(statsRange(StatsMode.month, 13, now), (DateTime(2024, 12), DateTime(2025, 1)));
    expect(statsRange(StatsMode.year, 1, now), (DateTime(2025), DateTime(2026)));
  });

  testWidgets('Lùi về tháng trước, xem năm và chạm vào một tháng', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 10);
    store.addTx(Tx(id: 'a', amount: 1234000, type: TxType.expense, categoryId: 'food', date: lastMonth));
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.tap(find.text('Thống kê').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tháng').last);
    await tester.pumpAndSettle();
    expect(find.text('Tháng ${now.month}, ${now.year}'), findsOneWidget);
    expect(find.text('1.234.000đ'), findsNothing); // tháng này chưa chi

    await tester.tap(find.byIcon(Icons.chevron_left).last); // .first là nút của Tổng quan (đang ẩn)
    await tester.pumpAndSettle();
    expect(find.text('Tháng ${lastMonth.month}, ${lastMonth.year}'), findsOneWidget);
    expect(find.text('1.234.000đ'), findsOneWidget);
    expect(find.text('Về hiện tại'), findsOneWidget);

    await tester.tap(find.text('Năm'));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}'), findsOneWidget);
    if (lastMonth.year == now.year) {
      // Bảng so sánh các tháng: chạm vào tháng trước -> sang chế độ Tháng của tháng đó.
      // Bảng nằm cuối trang: cuộn xuống cho nó được dựng ra.
      await tester.drag(find.text('Đã chi'), const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('−1.234.000đ').last);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, 2000)); // cuộn lên đầu trang
      await tester.pumpAndSettle();
      expect(find.text('Tháng ${lastMonth.month}, ${lastMonth.year}'), findsOneWidget);
    }
  });

  testWidgets('Thẻ tổng hiện cả thu và chi; danh sách theo danh mục chuyển được Chi / Thu', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    final now = DateTime.now();
    store.addTx(Tx(id: 'i', amount: 15000000, type: TxType.income, categoryId: 'salary', date: now));
    store.addTx(Tx(id: 'e', amount: 50000, type: TxType.expense, categoryId: 'food', date: now));
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.tap(find.text('Thống kê').last);
    await tester.pumpAndSettle();
    // Thẻ tổng hiện cả thu và chi cùng lúc, không cần chuyển.
    expect(find.text('Đã thu'), findsOneWidget);
    expect(find.text('Đã chi'), findsOneWidget);
    expect(find.text('15.000.000đ'), findsOneWidget);
    expect(find.text('50.000đ'), findsOneWidget);
    expect(find.text('+14.950.000đ'), findsOneWidget); // ròng

    // Danh sách theo danh mục: nút nhỏ Chi | Thu.
    await tester.drag(find.text('Đã thu'), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Chi nhiều nhất'), findsOneWidget);
    await tester.tap(find.text('Thu').last);
    await tester.pumpAndSettle();
    expect(find.text('Thu nhiều nhất'), findsOneWidget);
    expect(find.text('Lương'), findsOneWidget);
  });

  testWidgets('Danh sách theo danh mục: chạm "Xem tất cả" để hiện hết, "Thu gọn" để về 5 mục', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    final now = DateTime.now();
    final cats = store.catsOf(TxType.expense).toList(); // 6 danh mục chi mặc định
    for (var i = 0; i < cats.length; i++) {
      store.addTx(Tx(id: 'x$i', amount: (i + 1) * 10000, type: TxType.expense, categoryId: cats[i].id, date: now));
    }
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.tap(find.text('Thống kê').last);
    await tester.pumpAndSettle();
    await tester.drag(find.text('Đã thu'), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Xem tất cả (6)'), findsOneWidget);
    expect(find.text('10.000đ'), findsNothing); // mục nhỏ nhất đang ẩn
    await tester.tap(find.text('Xem tất cả (6)'));
    await tester.pumpAndSettle();
    expect(find.text('Thu gọn'), findsOneWidget);
    await tester.tap(find.text('Thu gọn'));
    await tester.pumpAndSettle();
    expect(find.text('Xem tất cả (6)'), findsOneWidget);
  });
}
