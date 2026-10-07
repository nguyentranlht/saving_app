import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/l10n.dart';
import 'package:so_thu_chi/main.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/screens/add_transaction.dart';
import 'package:so_thu_chi/screens/categories.dart';
import 'package:so_thu_chi/screens/detail.dart';
import 'package:so_thu_chi/store.dart';

/// Dựng các màn hình ở cỡ iPhone nhỏ với chữ hệ thống phóng to; lỗi tràn chữ
/// (RenderFlex overflowed) sẽ làm test fail.
void main() {
  for (final lang in AppLang.values) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final width in [375.0, 320.0]) {
        testWidgets('Không tràn chữ: ${lang.name}, chữ x$scale, rộng $width', (tester) async {
          tester.view.physicalSize = Size(width * 3, 812 * 3);
          tester.view.devicePixelRatio = 3;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          SharedPreferences.setMockInitialValues({'lang': lang.name});
          final store = await AppStore.load();
          final now = DateTime.now();
          store.addTx(Tx(id: '1', amount: 123456789, type: TxType.expense, categoryId: 'work',
              note: 'Một ghi chú khá dài để kiểm tra việc cắt chữ', date: now));
          store.addTx(Tx(id: '2', amount: 987654321, type: TxType.income, categoryId: 'debt', date: now));
          store.upsertCategory(Category(id: 'x', name: 'Danh mục có tên rất dài để thử', icon: 'food',
              color: 0xFF3B82F6, type: TxType.expense));

          await tester.pumpWidget(SoThuChiApp(store: store));
          await tester.pumpAndSettle();
          final s = S.current;

          for (final tab in [s.tabHistory, s.tabStats, s.tabSettings, s.tabOverview]) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
          }
          final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
          for (final page in <Widget>[
            const AddTransactionScreen(),
            const AddTransactionScreen(initialType: TxType.income),
            const DetailScreen(txId: '1'),
            const CategoriesScreen(),
          ]) {
            nav.push(MaterialPageRoute(builder: (_) => page));
            await tester.pumpAndSettle();
            nav.pop();
            await tester.pumpAndSettle();
          }
          // Sheet sửa danh mục
          nav.push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(find.text(s.addCategory), 200, scrollable: find.byType(Scrollable).last);
          await tester.tap(find.text(s.addCategory));
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
