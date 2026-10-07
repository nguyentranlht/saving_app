import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/backup.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/store.dart';

Recurring rule(Freq f, DateTime anchor, {String id = 'r1', int amount = 5000000}) => Recurring(
    id: id, amount: amount, type: TxType.expense, categoryId: 'other_e', note: 'Tiền nhà', freq: f, anchor: anchor);

Future<AppStore> emptyStore() async {
  SharedPreferences.setMockInitialValues({'lang': 'vi'});
  return AppStore.load();
}

void main() {
  group('Tính các lần lặp', () {
    test('Hằng tháng ngày 31 rơi vào cuối tháng ngắn', () {
      final r = rule(Freq.monthly, DateTime(2026, 1, 31, 9));
      expect([for (var i = 0; i < 4; i++) r.occurrence(i)], [
        DateTime(2026, 1, 31, 9),
        DateTime(2026, 2, 28, 9),
        DateTime(2026, 3, 31, 9),
        DateTime(2026, 4, 30, 9),
      ]);
      expect(r.occurrence(12), DateTime(2027, 1, 31, 9));
    });

    test('Hằng năm 29/2 rơi vào 28/2 năm không nhuận', () {
      final r = rule(Freq.yearly, DateTime(2028, 2, 29));
      expect(r.occurrence(1), DateTime(2029, 2, 28));
      expect(r.occurrence(4), DateTime(2032, 2, 29));
    });

    test('Hằng tuần và hằng ngày', () {
      expect(rule(Freq.weekly, DateTime(2026, 10, 5)).occurrence(4), DateTime(2026, 11, 2));
      expect(rule(Freq.daily, DateTime(2026, 12, 30)).occurrence(3), DateTime(2027, 1, 2));
    });
  });

  group('Tự ghi giao dịch', () {
    test('Ghi bù các lần đã qua, không ghi trùng khi chạy lại', () async {
      final store = await emptyStore();
      final now = DateTime.now();
      // Bắt đầu 3 tháng trước -> 4 lần tính cả tháng này (nếu ngày đã qua).
      final start = DateTime(now.year, now.month - 3, 1, 0, 1);
      store.addRecurring(rule(Freq.monthly, start));
      expect(store.txs.length, 4);
      expect(store.txs.every((t) => t.recurringId == 'r1' && t.amount == 5000000), isTrue);

      expect(store.runRecurring(), 0);
      expect(store.txs.length, 4);
      expect(store.recurring('r1')!.next, DateTime(now.year, now.month + 1, 1, 0, 1));
    });

    test('Ngày bắt đầu ở tương lai thì chưa ghi', () async {
      final store = await emptyStore();
      final n = DateTime.now().add(const Duration(days: 3));
      final later = DateTime(n.year, n.month, n.day, n.hour, n.minute); // lịch tính tới phút
      store.addRecurring(rule(Freq.monthly, later));
      expect(store.txs, isEmpty);
      // Giả lập 3 ngày sau mở app.
      expect(store.runRecurring(later.add(const Duration(minutes: 1))), 1);
      expect(store.txs.single.date, later);
    });

    test('Tạm dừng rồi tiếp tục: không ghi bù lúc dừng', () async {
      final store = await emptyStore();
      final now = DateTime.now();
      store.addRecurring(rule(Freq.daily, DateTime(now.year, now.month, now.day - 2, 0, 1)));
      expect(store.txs.length, 3); // hôm kia, hôm qua, hôm nay
      final r = store.recurring('r1')!;
      store.setRecurringActive(r, false);
      expect(store.runRecurring(now.add(const Duration(days: 5))), 0);
      store.setRecurringActive(r, true);
      expect(r.next.isAfter(now), isTrue);
      expect(store.txs.length, 3);
    });

    test('Sửa lịch không tạo lại các lần đã ghi', () async {
      final store = await emptyStore();
      final now = DateTime.now();
      store.addRecurring(rule(Freq.monthly, DateTime(now.year, now.month - 2, 1, 0, 1)));
      expect(store.txs.length, 3);
      final old = store.recurring('r1')!;
      // Đổi sang ngày 2 của tháng 2 tháng trước: các lần trước lần đã ghi gần nhất bị bỏ qua.
      store.updateRecurring(
        Recurring(
            id: 'r1', amount: 6000000, type: TxType.expense, categoryId: 'other_e', freq: Freq.monthly,
            anchor: DateTime(now.year, now.month - 2, 2, 0, 1), nextIndex: old.nextIndex,
            lastGenerated: old.lastGenerated),
        scheduleChanged: true,
      );
      final made = store.txs.where((t) => t.amount == 6000000).toList();
      // Chỉ có thể là ngày 2 tháng này (nếu đã qua), không có tháng trước.
      expect(made.length, now.day >= 2 ? 1 : 0);
      expect(store.txs.where((t) => t.amount == 5000000).length, 3);
    });

    test('Xóa định kỳ vẫn giữ giao dịch đã ghi', () async {
      final store = await emptyStore();
      final now = DateTime.now();
      store.addRecurring(rule(Freq.monthly, DateTime(now.year, now.month, 1, 0, 0)));
      store.deleteRecurring('r1');
      expect(store.recurrings, isEmpty);
      expect(store.txs.length, 1);
    });

    test('Lưu xuống bộ nhớ và nằm trong bản sao lưu', () async {
      final store = await emptyStore();
      store.addRecurring(rule(Freq.monthly, DateTime.now().add(const Duration(days: 1))));
      await Future<void>.delayed(Duration.zero);
      final reopened = await AppStore.load();
      expect(reopened.recurrings.single.note, 'Tiền nhà');

      final b = Backup.parse(store.toBackup().encode());
      expect(b.recurrings.single.freq, Freq.monthly);
      // Bản sao lưu cũ (v1, chưa có định kỳ) vẫn đọc được.
      final v1 = store.toBackup().encode().replaceFirst('"version": 2', '"version": 1');
      expect(Backup.parse(v1).txs, isEmpty);
    });
  });

  testWidgets('Ghi giao dịch hằng tháng từ màn Ghi giao dịch', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = await emptyStore();
    await tester.pumpWidget(SoThuChiApp(store: store));

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '5000000');
    await tester.ensureVisible(find.text('Lặp lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lặp lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Hằng tháng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bắt đầu:'), findsOneWidget);
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pumpAndSettle();

    expect(store.recurrings.single.freq, Freq.monthly);
    expect(store.txs.single.recurringId, store.recurrings.single.id);
    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Khoản chi · Định kỳ'), findsOneWidget); // nhãn trên giao dịch
  });
}
