import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:so_thu_chi/backup.dart';
import 'package:so_thu_chi/l10n.dart';
import 'package:so_thu_chi/models.dart';
import 'package:so_thu_chi/store.dart';

void main() {
  test('Sao lưu rồi khôi phục giữ nguyên dữ liệu', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    store.addTx(Tx(id: 'a', amount: 50000, type: TxType.expense, categoryId: 'food', note: 'phở "bò"', date: DateTime(2026, 10, 1, 8, 30)));
    store.addTx(Tx(id: 'b', amount: 9000000, type: TxType.income, categoryId: 'salary', date: DateTime(2026, 10, 5)));
    store.upsertCategory(Category(id: 'c1', name: 'Gym', icon: 'sport', color: 0xFF14B8A6, type: TxType.expense));
    store.setTheme(ThemeMode.dark);
    await store.setReminderTime(20, 15);

    final text = store.toBackup().encode();

    // Máy "mới": dữ liệu trống, tiếng Anh, giao diện sáng.
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    final fresh = await AppStore.load();
    expect(fresh.txs, isEmpty);
    await fresh.restore(Backup.parse(text));

    expect(fresh.txs.map((t) => t.id), ['b', 'a']);
    expect(fresh.tx('a')!.note, 'phở "bò"');
    expect(fresh.tx('a')!.date, DateTime(2026, 10, 1, 8, 30));
    expect(fresh.tx('b')!.amount, 9000000);
    expect(fresh.cat('c1')!.name, 'Gym');
    expect(fresh.categories.length, store.categories.length);
    expect(fresh.themeMode, ThemeMode.dark);
    expect(fresh.lang, AppLang.vi);
    expect((fresh.reminderHour, fresh.reminderMinute), (20, 15));
    expect(fresh.reminder, isFalse); // bật nhắc phải xin quyền lại trên máy mới

    // Dữ liệu được ghi xuống bộ nhớ, mở lại app vẫn còn.
    final reopened = await AppStore.load();
    expect(reopened.txs.length, 2);
  });

  test('Từ chối file không phải bản sao lưu', () {
    for (final bad in [
      'xin chào',
      '{}',
      '[1,2,3]',
      '{"format":"khac","version":1}',
      '{"format":"so_thu_chi_backup","version":99,"categories":[],"txs":[]}',
      '{"format":"so_thu_chi_backup","version":1,"exportedAt":"2026-10-07","categories":[],"txs":[]}',
      '{"format":"so_thu_chi_backup","version":1,"exportedAt":"2026-10-07","categories":[{"id":1}],"txs":[]}',
    ]) {
      expect(() => Backup.parse(bad), throwsFormatException, reason: bad);
    }
  });

  test('Đánh dấu thời điểm sao lưu được lưu lại', () async {
    SharedPreferences.setMockInitialValues({'lang': 'vi'});
    final store = await AppStore.load();
    expect(store.lastBackup, isNull);
    store.markBackedUp();
    await Future<void>.delayed(Duration.zero);
    final reopened = await AppStore.load();
    expect(reopened.lastBackup, isNotNull);
  });
}
