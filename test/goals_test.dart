import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/backup.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/screens/goals.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  Goal laptop() => Goal(id: 'g1', name: 'Laptop', icon: 'devices', color: 0xFF16A06A, target: 20000000);

  test('Tách tiền vào mục tiêu: trừ khỏi số dư khả dụng, không tính là thu / chi', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    store.addTx(Tx(id: 'luong', amount: 15000000, type: TxType.income, categoryId: 'salary', date: DateTime.now()));
    store.upsertGoal(laptop());

    store.moveToGoal('g1', 5000000);
    expect(store.goal('g1')!.saved, 5000000);
    expect(store.savedTotal, 5000000);
    expect(store.totalBalance, 15000000);
    expect(store.balance, 10000000); // khả dụng
    expect(store.total(TxType.expense), 0); // không phải khoản chi

    // Rút ra: trả về số dư; rút quá số đã để dành thì chỉ rút hết.
    store.moveToGoal('g1', -2000000);
    expect(store.balance, 12000000);
    store.moveToGoal('g1', -99000000);
    expect(store.goal('g1')!.saved, 0);
    expect(store.balance, 15000000);

    // Lưu lại sau khi mở lại app.
    store.moveToGoal('g1', 3000000);
    await Future<void>.delayed(Duration.zero);
    final reopened = await AppStore.load();
    expect(reopened.goal('g1')!.saved, 3000000);
    expect(reopened.balance, 12000000);
  });

  test('Dùng tiền: thành một khoản chi, mục tiêu hoàn thành, số dư không bị trừ hai lần', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    store.addTx(Tx(id: 'luong', amount: 30000000, type: TxType.income, categoryId: 'salary', date: DateTime.now()));
    store.upsertGoal(laptop());
    store.moveToGoal('g1', 20000000);
    expect(store.goal('g1')!.reached, isTrue);
    expect(store.balance, 10000000);

    final t = store.spendGoal('g1', 'work')!;
    expect(t.amount, 20000000);
    expect(t.type, TxType.expense);
    expect(t.categoryId, 'work');
    expect(t.note, 'Laptop');
    final g = store.goal('g1')!;
    expect(g.done, isTrue);
    expect(g.spentTxId, t.id);
    expect(store.savedTotal, 0); // mục tiêu đã xong không còn giữ tiền
    expect(store.balance, 10000000); // 30tr − 20tr chi

    // Đã xong thì không nạp thêm hay dùng lại được.
    store.moveToGoal('g1', 1000000);
    expect(store.goal('g1')!.saved, 20000000);
    expect(store.spendGoal('g1', 'work'), isNull);
  });

  test('Xóa mục tiêu trả tiền về số dư; cần bao nhiêu mỗi tháng để kịp hạn', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    store.upsertGoal(laptop());
    store.moveToGoal('g1', 4000000);
    expect(store.balance, -4000000);
    store.deleteGoal('g1');
    expect(store.balance, 0);

    final g = Goal(id: 'x', name: 'Du lịch', icon: 'travel', color: 0, target: 12000000,
        deadline: DateTime(2027, 3, 1), entries: [GoalEntry(amount: 2000000, date: DateTime(2026, 10, 1))]);
    expect(g.perMonth(DateTime(2026, 10, 17)), 2000000); // còn 10tr, 5 tháng: 10, 11, 12, 1, 2
    expect(g.perMonth(DateTime(2027, 5, 1)), 10000000); // quá hạn: cần đủ ngay
    g.deadline = null;
    expect(g.perMonth(DateTime(2026, 10, 17)), isNull);
  });

  test('Sao lưu / khôi phục giữ cả mục tiêu', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    store.upsertGoal(laptop()..deadline = DateTime(2027, 1, 1));
    store.moveToGoal('g1', 1500000);
    final text = store.toBackup().encode();

    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final fresh = await AppStore.load();
    await fresh.restore(Backup.parse(text));
    final g = fresh.goal('g1')!;
    expect(g.name, 'Laptop');
    expect(g.saved, 1500000);
    expect(g.deadline, DateTime(2027, 1, 1));
  });

  testWidgets('Tạo mục tiêu, nạp tiền, rồi dùng tiền từ màn Mục tiêu', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    store.addTx(Tx(id: 'luong', amount: 15000000, type: TxType.income, categoryId: 'salary', date: DateTime.now()));
    await tester.pumpWidget(SoThuChiApp(store: store));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm mục tiêu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Laptop');
    await tester.enterText(find.byType(TextField).at(1), '10000000');
    await tester.ensureVisible(find.text('Lưu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.goals.single.target, 10000000);

    await tester.tap(find.text('Laptop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nạp tiền'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10000000');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Nạp tiền'));
    await tester.pumpAndSettle();
    expect(store.goals.single.saved, 10000000);
    expect(store.balance, 5000000);
    expect(find.text('Đã đủ tiền'), findsOneWidget);

    await tester.tap(find.text('Dùng tiền'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công tác phí'));
    await tester.pumpAndSettle();
    expect(store.goals.single.done, isTrue);
    expect(store.txs.where((t) => t.type == TxType.expense).single.amount, 10000000);
    expect(store.balance, 5000000);
  });
}
