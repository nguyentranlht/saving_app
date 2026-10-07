import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/screens/categories.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  test('Sắp xếp danh mục chi không làm xáo trộn danh mục thu, và được lưu lại', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    List<String> ids(TxType t) => store.catsOf(t).map((c) => c.id).toList();
    expect(ids(TxType.expense), ['food', 'move', 'coffee', 'work', 'health', 'other_e']);
    final income = ids(TxType.income);

    store.moveCategory(TxType.expense, 3, 0); // Công tác phí lên đầu
    expect(ids(TxType.expense), ['work', 'food', 'move', 'coffee', 'health', 'other_e']);
    store.moveCategory(TxType.expense, 0, 5); // rồi xuống cuối
    expect(ids(TxType.expense), ['food', 'move', 'coffee', 'health', 'other_e', 'work']);
    store.moveCategory(TxType.expense, 0, 99); // chỉ số sai -> bỏ qua
    expect(ids(TxType.income), income);

    await Future<void>.delayed(Duration.zero);
    final reopened = await AppStore.load();
    expect(reopened.catsOf(TxType.expense).map((c) => c.id).toList(),
        ['food', 'move', 'coffee', 'health', 'other_e', 'work']);
  });

  testWidgets('Kéo biểu tượng ≡ để đổi thứ tự', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
    await tester.pumpAndSettle();

    // Kéo "Ăn uống" (dòng đầu) xuống dưới "Di chuyển".
    final handle = find.byIcon(Icons.drag_handle).first;
    final g = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    expect(store.catsOf(TxType.expense).take(2).map((c) => c.id), ['move', 'food']);
  });
}
