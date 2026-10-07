import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/format.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/store.dart';

/// Hàng chờ giống hệt dạng AddExpenseIntent (Swift) ghi vào UserDefaults.
String pending(List<Map<String, String>> items) => jsonEncode(items);

void main() {
  test('Đọc số tiền từ Phím tắt', () {
    expect(parseAmount('₫125.000'), 125000);
    expect(parseAmount('125.000 ₫'), 125000);
    expect(parseAmount('125,000 ₫'), 125000);
    expect(parseAmount('1.250.000đ'), 1250000);
    expect(parseAmount('45000'), 45000);
    expect(parseAmount('VND 45,000'), 45000);
    expect(parseAmount('\$12.50'), 13); // tiền có phần lẻ -> làm tròn
    expect(parseAmount('12,4'), 12);
    expect(parseAmount(''), 0);
    expect(parseAmount('abc'), 0);
  });

  test('Nhập hàng chờ, đoán danh mục theo nơi đã chi', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    store.addTx(Tx(id: 'old', amount: 59000, type: TxType.expense, categoryId: 'coffee', note: 'Highlands Coffee',
        date: DateTime(2026, 9, 1)));
    store.setAutoCategory('food');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingTxs', pending([
      {'amount': '₫65.000', 'merchant': 'HIGHLANDS COFFEE', 'card': 'VCB', 'date': '2026-10-07T02:15:00Z'},
      {'amount': '₫230.000', 'merchant': 'Circle K', 'card': 'VCB', 'date': '2026-10-07T03:00:00Z'},
      {'amount': '0', 'merchant': 'Lỗi', 'card': '', 'date': '2026-10-07T03:00:00Z'}, // bỏ qua
    ]));

    expect(await store.importPending(), 2);
    final hl = store.txs.firstWhere((t) => t.amount == 65000);
    expect(hl.categoryId, 'coffee'); // học theo lần trước (không phân biệt hoa thường / dấu)
    expect(hl.note, 'HIGHLANDS COFFEE');
    expect(hl.date, DateTime.utc(2026, 10, 7, 2, 15).toLocal());
    expect(store.txs.firstWhere((t) => t.amount == 230000).categoryId, 'food'); // nơi mới -> mặc định

    // Đã nhập thì xóa hàng chờ, chạy lại không ghi trùng.
    expect(prefs.getString('pendingTxs'), isNull);
    expect(await store.importPending(), 0);
  });

  test('Menu Sổ thu chi: dùng đúng danh mục đã chọn, chọn danh mục thu thì ghi là khoản thu', () async {
    SharedPreferences.setMockInitialValues({
      'lang': 'vi',
      'pendingTxs': pending([
        {'amount': '45000', 'categoryId': 'coffee', 'type': 'expense', 'note': 'bạc xỉu', 'date': '2026-10-07T01:00:00Z'},
        {'amount': '15000000', 'categoryId': 'salary', 'type': 'income', 'note': '', 'date': '2026-10-07T02:00:00Z'},
        {'amount': '20000', 'categoryId': 'da_xoa', 'type': 'expense', 'note': '', 'date': '2026-10-07T03:00:00Z'},
      ]),
    });
    final store = await AppStore.load();
    store.setAutoCategory('food');
    expect(await store.importPending(), 3);
    final coffee = store.txs.firstWhere((t) => t.amount == 45000);
    expect((coffee.categoryId, coffee.type, coffee.note), ('coffee', TxType.expense, 'bạc xỉu'));
    final salary = store.txs.firstWhere((t) => t.amount == 15000000);
    expect((salary.categoryId, salary.type), ('salary', TxType.income));
    // Danh mục đã bị xóa trong app -> dùng danh mục mặc định.
    expect(store.txs.firstWhere((t) => t.amount == 20000).categoryId, 'food');
  });

  test('Hàng chờ hỏng không làm hỏng app', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi', 'pendingTxs': 'không phải json'});
    final store = await AppStore.load();
    expect(await store.importPending(), 0);
  });

  testWidgets('Mở app thì tự ghi và báo', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lang': 'vi',
      'pendingTxs': pending([
        {'amount': '₫45.000', 'merchant': 'Grab', 'card': '', 'date': DateTime.now().toUtc().toIso8601String()},
      ]),
    });
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.pump();
    await tester.pump();
    expect(find.text('Đã ghi 1 giao dịch từ Phím tắt'), findsOneWidget);
    expect(store.txs.single.amount, 45000);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Menu "Xem thống kê chi tiêu" mở đúng tab Thống kê', (tester) async {
    SharedPreferences.setMockInitialValues({'lang': 'vi', 'openTab': 2});
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Đã chi'), findsOneWidget); // thẻ tổng của màn Thống kê
    expect((await SharedPreferences.getInstance()).getInt('openTab'), isNull); // chỉ mở một lần
  });
}
