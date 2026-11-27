import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/screens/add_transaction.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  testWidgets('Bàn phím số riêng: gõ số, 000, xoá, giữ xoá để xoá hết, Xong để ẩn', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
    await tester.pumpAndSettle();
    expect(find.text('000'), findsNothing); // chưa chọn ô tiền thì chưa có bàn phím

    final field = find.byType(TextField).first;
    String amount() => tester.widget<TextField>(field).controller!.text;
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(find.text('000'), findsOneWidget);

    for (final k in ['0', '4', '5', '000']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    expect(amount(), '45.000'); // số 0 đầu tiên bị bỏ qua
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(amount(), '4.500');
    await tester.longPress(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(amount(), '');

    await tester.tap(find.text('7').last);
    await tester.tap(find.text('000').last);
    await tester.pump();
    expect(amount(), '7.000');
    // Nút Lưu bật lên theo số vừa gõ (onChanged được gọi).
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.text('000'), findsNothing);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
    expect(amount(), '7.000');
  });
}
