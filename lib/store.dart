import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';
import 'models.dart';
import 'reminder.dart';

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  final SharedPreferences _prefs;

  List<Category> categories = [];
  List<Tx> txs = [];
  ThemeMode themeMode = ThemeMode.light;
  bool reminder = false;
  int reminderHour = 21;
  int reminderMinute = 0;

  static Future<AppStore> load() async {
    final s = AppStore._(await SharedPreferences.getInstance());
    final cats = s._prefs.getString('categories');
    final list = s._prefs.getString('txs');
    s.categories = cats == null
        ? defaultCategories()
        : (jsonDecode(cats) as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
    s.txs = list == null
        ? []
        : (jsonDecode(list) as List)
            .map((e) => Tx.fromJson(e as Map<String, dynamic>))
            .toList();
    s.themeMode = (s._prefs.getString('theme') == 'dark')
        ? ThemeMode.dark
        : ThemeMode.light;
    s.reminder = s._prefs.getBool('reminder') ?? false;
    s.reminderHour = s._prefs.getInt('reminderHour') ?? 21;
    s.reminderMinute = s._prefs.getInt('reminderMinute') ?? 0;
    s._sort();
    return s;
  }

  static List<Category> defaultCategories() => [
        Category(id: 'food', name: 'Ăn uống', icon: 'food', color: 0xFFF59E0B, type: TxType.expense),
        Category(id: 'move', name: 'Di chuyển', icon: 'move', color: 0xFF8B5CF6, type: TxType.expense),
        Category(id: 'coffee', name: 'Cà phê', icon: 'coffee', color: 0xFFB45309, type: TxType.expense),
        Category(id: 'work', name: 'Công tác phí', icon: 'work', color: 0xFF3B82F6, type: TxType.expense),
        Category(id: 'health', name: 'Sức khỏe', icon: 'health', color: 0xFFEF5350, type: TxType.expense),
        Category(id: 'other_e', name: 'Khác', icon: 'more', color: 0xFF9097A8, type: TxType.expense),
        Category(id: 'salary', name: 'Lương', icon: 'wallet', color: 0xFF16A06A, type: TxType.income),
        Category(id: 'debt', name: 'Được trả nợ', icon: 'debt', color: 0xFF0EA5E9, type: TxType.income),
        Category(id: 'other_i', name: 'Khác', icon: 'more', color: 0xFF9097A8, type: TxType.income),
      ];

  void _sort() => txs.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _save() async {
    await _prefs.setString(
        'categories', jsonEncode(categories.map((e) => e.toJson()).toList()));
    await _prefs.setString('txs', jsonEncode(txs.map((e) => e.toJson()).toList()));
    await _prefs.setString('theme', themeMode == ThemeMode.dark ? 'dark' : 'light');
    await _prefs.setBool('reminder', reminder);
    await _prefs.setInt('reminderHour', reminderHour);
    await _prefs.setInt('reminderMinute', reminderMinute);
  }

  void _commit() {
    _sort();
    notifyListeners();
    _save();
  }

  // ---- Truy vấn ----
  Category? cat(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Tx? tx(String id) {
    for (final t in txs) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Category> catsOf(TxType t) => categories.where((c) => c.type == t).toList();

  int total(TxType t, {DateTime? from, DateTime? to}) => txs
      .where((x) => x.type == t && _in(x.date, from, to))
      .fold(0, (s, x) => s + x.amount);

  int get balance => total(TxType.income) - total(TxType.expense);

  /// Tổng theo danh mục, giảm dần.
  List<MapEntry<Category, int>> byCategory(TxType t, {DateTime? from, DateTime? to}) {
    final m = <String, int>{};
    for (final x in txs) {
      if (x.type == t && _in(x.date, from, to)) {
        m[x.categoryId] = (m[x.categoryId] ?? 0) + x.amount;
      }
    }
    final out = <MapEntry<Category, int>>[];
    m.forEach((id, v) {
      final c = cat(id);
      if (c != null) out.add(MapEntry(c, v));
    });
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  int countIn(String categoryId) => txs.where((x) => x.categoryId == categoryId).length;

  bool _in(DateTime d, DateTime? from, DateTime? to) =>
      (from == null || !d.isBefore(from)) && (to == null || d.isBefore(to));

  // ---- Giao dịch ----
  void addTx(Tx t) {
    txs.add(t);
    _commit();
  }

  void updateTx(Tx t) {
    final i = txs.indexWhere((x) => x.id == t.id);
    if (i >= 0) txs[i] = t;
    _commit();
  }

  void deleteTx(String id) {
    txs.removeWhere((x) => x.id == id);
    _commit();
  }

  // ---- Danh mục ----
  void upsertCategory(Category c) {
    final i = categories.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      categories[i] = c;
    } else {
      categories.add(c);
    }
    _commit();
  }

  void deleteCategory(String id) {
    categories.removeWhere((x) => x.id == id);
    _commit();
  }

  // ---- Cài đặt ----
  void setTheme(ThemeMode m) {
    themeMode = m;
    _commit();
  }

  /// Bật/tắt nhắc. Trả về false nếu người dùng không cấp quyền thông báo.
  Future<bool> setReminder(bool v) async {
    if (v) {
      final ok = await Reminder.requestPermission();
      if (!ok) {
        reminder = false;
        _commit();
        return false;
      }
      await Reminder.schedule(reminderHour, reminderMinute);
    } else {
      await Reminder.cancel();
    }
    reminder = v;
    _commit();
    return true;
  }

  Future<void> setReminderTime(int h, int m) async {
    reminderHour = h;
    reminderMinute = m;
    if (reminder) await Reminder.schedule(h, m);
    _commit();
  }

  /// Gọi lúc mở app để đảm bảo lịch nhắc còn hiệu lực.
  Future<void> syncReminder() async {
    if (reminder) {
      await Reminder.schedule(reminderHour, reminderMinute);
    }
  }

  Future<void> clearAll() async {
    txs = [];
    categories = defaultCategories();
    reminder = false;
    await Reminder.cancel();
    _commit();
  }

  String exportCsv() {
    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    String when(DateTime d) =>
        '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    final b = StringBuffer('Ngày giờ,Loại,Danh mục,Số tiền (đ),Ghi chú\n');
    for (final t in txs) {
      b.writeln([
        when(t.date),
        t.type == TxType.expense ? 'Chi' : 'Thu',
        esc(cat(t.categoryId)?.name ?? ''),
        t.signed,
        esc(t.note),
      ].join(','));
    }
    return b.toString();
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
