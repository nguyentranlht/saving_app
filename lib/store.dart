import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup.dart';
import 'format.dart';
import 'l10n.dart';
import 'models.dart';
import 'reminder.dart';

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  final SharedPreferences _prefs;

  List<Category> categories = [];
  List<Tx> txs = [];
  List<Recurring> recurrings = [];

  /// Hạn mức chi mỗi tháng: id danh mục -> số tiền. Khóa [totalBudgetKey] = hạn mức tổng.
  Map<String, int> budgets = {};
  static const totalBudgetKey = '*';
  static const budgetWarnAt = 0.8; // cảnh báo khi đã dùng từ 80%
  ThemeMode themeMode = ThemeMode.light;
  AppLang lang = AppLang.vi;
  bool reminder = false;
  int reminderHour = 21;
  int reminderMinute = 0;
  DateTime? lastBackup;
  String autoCategoryId = 'other_e'; // danh mục cho khoản tự ghi ở nơi chưa gặp

  static Future<AppStore> load() async {
    final s = AppStore._(await SharedPreferences.getInstance());
    // Lần đầu mở app: theo ngôn ngữ điện thoại (tiếng Việt nếu không phải tiếng Anh).
    final savedLang = s._prefs.getString('lang') ??
        (WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'en' ? 'en' : 'vi');
    s.lang = AppLang.values.byName(savedLang);
    S.use(s.lang);
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
    final recs = s._prefs.getString('recurrings');
    s.recurrings = recs == null
        ? []
        : (jsonDecode(recs) as List)
            .map((e) => Recurring.fromJson(e as Map<String, dynamic>))
            .toList();
    final bud = s._prefs.getString('budgets');
    s.budgets = bud == null ? {} : (jsonDecode(bud) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    s.themeMode = (s._prefs.getString('theme') == 'dark')
        ? ThemeMode.dark
        : ThemeMode.light;
    s.reminder = s._prefs.getBool('reminder') ?? false;
    s.reminderHour = s._prefs.getInt('reminderHour') ?? 21;
    s.reminderMinute = s._prefs.getInt('reminderMinute') ?? 0;
    s.autoCategoryId = s._prefs.getString('autoCategory') ?? 'other_e';
    final lb = s._prefs.getString('lastBackup');
    s.lastBackup = lb == null ? null : DateTime.tryParse(lb);
    s._sort();
    s.runRecurring();
    return s;
  }

  static List<Category> defaultCategories() {
    final n = S.current.defaultName;
    return [
      Category(id: 'food', name: n('food'), icon: 'food', color: 0xFFF59E0B, type: TxType.expense),
      Category(id: 'move', name: n('move'), icon: 'move', color: 0xFF8B5CF6, type: TxType.expense),
      Category(id: 'coffee', name: n('coffee'), icon: 'coffee', color: 0xFFB45309, type: TxType.expense),
      Category(id: 'work', name: n('work'), icon: 'work', color: 0xFF3B82F6, type: TxType.expense),
      Category(id: 'health', name: n('health'), icon: 'health', color: 0xFFEF5350, type: TxType.expense),
      Category(id: 'other_e', name: n('other_e'), icon: 'more', color: 0xFF9097A8, type: TxType.expense),
      Category(id: 'salary', name: n('salary'), icon: 'wallet', color: 0xFF16A06A, type: TxType.income),
      Category(id: 'debt', name: n('debt'), icon: 'debt', color: 0xFF0EA5E9, type: TxType.income),
      Category(id: 'other_i', name: n('other_i'), icon: 'more', color: 0xFF9097A8, type: TxType.income),
    ];
  }

  void _sort() => txs.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _save() async {
    await _prefs.setString(
        'categories', jsonEncode(categories.map((e) => e.toJson()).toList()));
    await _prefs.setString('txs', jsonEncode(txs.map((e) => e.toJson()).toList()));
    await _prefs.setString('recurrings', jsonEncode(recurrings.map((e) => e.toJson()).toList()));
    await _prefs.setString('budgets', jsonEncode(budgets));
    await _prefs.setString('theme', themeMode == ThemeMode.dark ? 'dark' : 'light');
    await _prefs.setString('lang', lang.name);
    await _prefs.setBool('reminder', reminder);
    await _prefs.setInt('reminderHour', reminderHour);
    await _prefs.setInt('reminderMinute', reminderMinute);
    if (lastBackup != null) await _prefs.setString('lastBackup', lastBackup!.toIso8601String());
    await _prefs.setString('autoCategory', autoCategoryId);
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

  // ---- Giao dịch định kỳ ----
  Recurring? recurring(String id) {
    for (final r in recurrings) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Tạo các giao dịch định kỳ đã đến hạn (gọi lúc mở app / quay lại app).
  /// Trả về số giao dịch đã tạo.
  int runRecurring([DateTime? now]) {
    now ??= DateTime.now();
    final ids = {for (final t in txs) t.id};
    var made = 0;
    for (final r in recurrings) {
      if (!r.active) continue;
      // Giới hạn để không treo app nếu đặt ngày bắt đầu quá xa trong quá khứ.
      while (made < 1000 && !r.next.isAfter(now)) {
        final t = r.makeTx(r.nextIndex);
        if (ids.add(t.id)) txs.add(t);
        r.lastGenerated = t.date;
        r.nextIndex++;
        made++;
      }
    }
    if (made > 0) _commit();
    return made;
  }

  void addRecurring(Recurring r) {
    recurrings.add(r);
    if (runRecurring() == 0) _commit();
  }

  /// Sửa giao dịch định kỳ; chỉ ảnh hưởng các lần sau. Nếu đổi lịch (ngày / tần suất)
  /// thì tính lại lần kế tiếp, bỏ qua những lần trước lần đã tạo gần nhất.
  void updateRecurring(Recurring r, {required bool scheduleChanged}) {
    final i = recurrings.indexWhere((x) => x.id == r.id);
    if (i < 0) return;
    if (scheduleChanged) {
      r.nextIndex = r.lastGenerated == null ? 0 : r.firstIndexAfter(r.lastGenerated!);
    }
    recurrings[i] = r;
    if (runRecurring() == 0) _commit();
  }

  /// Tạm dừng / tiếp tục. Các lần lỡ trong lúc tạm dừng sẽ không được tạo bù.
  void setRecurringActive(Recurring r, bool v) {
    r.active = v;
    if (v) r.nextIndex = r.firstIndexAfter(DateTime.now());
    _commit();
  }

  /// Xóa giao dịch định kỳ; các giao dịch đã ghi trước đó vẫn được giữ.
  void deleteRecurring(String id) {
    recurrings.removeWhere((x) => x.id == id);
    _commit();
  }

  // ---- Tự ghi từ Phím tắt (Apple Pay) ----
  static const _pendingKey = 'pendingTxs';

  void setAutoCategory(String id) {
    autoCategoryId = id;
    _commit();
  }

  /// Danh mục cho khoản chi tại [merchant]: lấy theo lần gần nhất chi ở cùng nơi,
  /// nếu chưa có thì dùng [autoCategoryId].
  String guessCategory(String merchant) {
    final key = searchKey(merchant.trim());
    if (key.isNotEmpty) {
      for (final t in txs) {
        // txs đã sắp xếp mới nhất trước
        if (t.type == TxType.expense && searchKey(t.note.trim()) == key && cat(t.categoryId) != null) {
          return t.categoryId;
        }
      }
    }
    if (cat(autoCategoryId)?.type == TxType.expense) return autoCategoryId;
    return catsOf(TxType.expense).first.id;
  }

  /// Nhập các khoản chi mà hành động "Ghi khoản chi" của Phím tắt đã cất vào hàng chờ.
  /// Trả về số khoản đã ghi.
  Future<int> importPending() async {
    await _prefs.reload(); // hàng chờ được ghi từ phía iOS, ngoài Flutter
    final raw = _prefs.getString(_pendingKey);
    if (raw == null) return 0;
    await _prefs.remove(_pendingKey);
    List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return 0;
    }
    var n = 0;
    final base = DateTime.now().microsecondsSinceEpoch;
    for (final e in list) {
      if (e is! Map) continue;
      final amount = parseAmount('${e['amount'] ?? ''}');
      if (amount <= 0) continue;
      final merchant = '${e['merchant'] ?? ''}'.trim();
      txs.add(Tx(
        id: 'ap${base}_$n',
        amount: amount,
        type: TxType.expense,
        categoryId: guessCategory(merchant),
        note: merchant,
        date: DateTime.tryParse('${e['date']}')?.toLocal() ?? DateTime.now(),
      ));
      n++;
    }
    if (n > 0) _commit();
    return n;
  }

  // ---- Ngân sách ----
  /// Đặt hạn mức tháng cho danh mục (hoặc [totalBudgetKey]); null/0 = bỏ hạn mức.
  void setBudget(String key, int? amount) {
    if (amount == null || amount <= 0) {
      budgets.remove(key);
    } else {
      budgets[key] = amount;
    }
    _commit();
  }

  /// Đã chi trong tháng chứa [month] cho danh mục [key] (hoặc tổng).
  int spentIn(String key, DateTime month) {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);
    return txs
        .where((t) =>
            t.type == TxType.expense &&
            (key == totalBudgetKey || t.categoryId == key) &&
            !t.date.isBefore(from) &&
            t.date.isBefore(to))
        .fold(0, (s, t) => s + t.amount);
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
    budgets.remove(id);
    _commit();
  }

  // ---- Cài đặt ----
  void setTheme(ThemeMode m) {
    themeMode = m;
    _commit();
  }

  Future<void> setLang(AppLang l) async {
    lang = l;
    S.use(l);
    _commit();
    await syncReminder(); // đặt lại để nội dung thông báo theo ngôn ngữ mới
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

  // ---- Sao lưu / khôi phục ----
  Backup toBackup() => Backup(
        categories: categories,
        txs: txs,
        recurrings: recurrings,
        budgets: budgets,
        exportedAt: DateTime.now(),
        theme: themeMode == ThemeMode.dark ? 'dark' : 'light',
        lang: lang.name,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      );

  void markBackedUp() {
    lastBackup = DateTime.now();
    _commit();
  }

  /// Thay toàn bộ dữ liệu bằng bản sao lưu. Giữ nguyên trạng thái bật/tắt nhắc
  /// (vì cần quyền thông báo trên máy này), chỉ lấy giờ nhắc.
  Future<void> restore(Backup b) async {
    categories = [...b.categories];
    txs = [...b.txs];
    recurrings = [for (final r in b.recurrings) Recurring.fromJson(r.toJson())];
    budgets = {...b.budgets};
    if (b.theme != null) themeMode = b.theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    if (b.lang == 'vi' || b.lang == 'en') {
      lang = AppLang.values.byName(b.lang!);
      S.use(lang);
    }
    if (b.reminderHour != null && b.reminderMinute != null) {
      reminderHour = b.reminderHour!;
      reminderMinute = b.reminderMinute!;
    }
    _commit();
    runRecurring(); // tạo các lần đến hạn kể từ lúc sao lưu
    await syncReminder();
  }

  Future<void> clearAll() async {
    txs = [];
    recurrings = [];
    budgets = {};
    categories = defaultCategories();
    reminder = false;
    await Reminder.cancel();
    _commit();
  }

  String exportCsv() {
    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    String when(DateTime d) =>
        '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    final s = S.current;
    final b = StringBuffer('${s.csvHeader}\n');
    for (final t in txs) {
      b.writeln([
        when(t.date),
        t.type == TxType.expense ? s.expenseShort : s.incomeShort,
        esc(s.catName(cat(t.categoryId))),
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

  /// Lấy store mà không đăng ký vẽ lại (dùng trong callback).
  static AppStore read(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
