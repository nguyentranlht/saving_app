import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/format.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  test('Tính biểu thức số tiền', () {
    expect(evalAmount('45000+30000+12000'), 87000);
    expect(evalAmount('600000÷4'), 150000);
    expect(evalAmount('50000+30000×2'), 110000); // nhân trước
    expect(evalAmount('100000−25000−5000'), 70000);
    expect(evalAmount('100000÷3'), 33333); // làm tròn tới đồng
    expect(evalAmount('200000÷3'), 66667);
    expect(evalAmount('45000+'), 45000); // phép tính thừa ở cuối
    expect(evalAmount('×45000'), 45000); // phép tính thừa ở đầu
    expect(evalAmount('10000−50000'), -40000);
    expect(evalAmount('5000÷0'), isNull);
    expect(evalAmount(''), isNull);
  });

  Future<void> openCalc(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.tap(find.byIcon(Icons.add).first); // nút + giữa thanh dưới
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String keys) async {
    for (final k in keys.split(' ')) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
  }

  testWidgets('Bấm 45.000 + 30.000 rồi Dùng thì điền 75.000 vào ô số tiền', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await openCalc(tester);

    await press(tester, '4 5 000 + 3 0 000');
    expect(find.text('45.000 + 30.000'), findsOneWidget);
    expect(find.text('= 75.000đ'), findsOneWidget);

    await press(tester, 'Dùng');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '75.000'), findsOneWidget);
  });

  testWidgets('Kết quả không dương thì không cho dùng', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await openCalc(tester);
    await press(tester, '5 − 9 Dùng');
    expect(find.text('Kết quả phải lớn hơn 0'), findsOneWidget);
    expect(find.text('Máy tính'), findsOneWidget); // vẫn đang mở
  });

  testWidgets('Máy tính không tràn chữ trên màn hẹp, chữ to', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openCalc(tester);
    await press(tester, '9 9 9 000 000 × 9 9 9 000');
    expect(tester.takeException(), isNull);
  });
}
