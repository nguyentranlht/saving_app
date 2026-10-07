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
      await tester.ensureVisible(find.text('−1.234.000đ').last); // .first là dòng Ròng của thẻ tổng
      await tester.pumpAndSettle();
      await tester.tap(find.text('−1.234.000đ').last);
      await tester.pumpAndSettle();
      expect(find.text('Tháng ${lastMonth.month}, ${lastMonth.year}'), findsOneWidget);
    }
  });
}
