import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/l10n.dart';
import 'package:so_thu_chi/main.dart';
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
}
