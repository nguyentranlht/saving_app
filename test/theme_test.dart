import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/backup.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  test('Cài mới thì theo hệ thống; lựa chọn cũ (sáng / tối) được giữ', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await AppStore.load()).themeMode, ThemeMode.system);
    SharedPreferences.setMockInitialValues({'theme': 'light'});
    expect((await AppStore.load()).themeMode, ThemeMode.light);
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    expect((await AppStore.load()).themeMode, ThemeMode.dark);
  });

  test('Lưu và sao lưu cả lựa chọn "Hệ thống"', () async {
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final store = await AppStore.load();
    store.setTheme(ThemeMode.system);
    await Future<void>.delayed(Duration.zero);
    expect((await AppStore.load()).themeMode, ThemeMode.system);

    final b = Backup.parse(store.toBackup().encode());
    expect(b.theme, 'system');
    store.setTheme(ThemeMode.light);
    await store.restore(b);
    expect(store.themeMode, ThemeMode.system);
  });

  testWidgets('Chọn "Hệ thống" thì giao diện đi theo máy', (tester) async {
    SharedPreferences.setMockInitialValues({'lang': 'vi', 'theme': 'light'});
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final store = await AppStore.load();
    await tester.pumpWidget(SoThuChiApp(store: store));
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Hệ thống'))).brightness, Brightness.light);

    await tester.tap(find.text('Hệ thống'));
    await tester.pumpAndSettle();
    expect(store.themeMode, ThemeMode.system);
    expect(Theme.of(tester.element(find.text('Hệ thống'))).brightness, Brightness.dark); // máy đang để tối
  });
}
