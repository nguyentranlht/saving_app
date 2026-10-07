import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/screens/shell.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  testWidgets('App khởi động và hiển thị Shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    expect(find.byType(Shell), findsOneWidget);
  });
}
