import 'package:flutter/material.dart';

import '../backup.dart';
import '../export.dart';
import '../format.dart';
import '../l10n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'budget.dart';
import 'categories.dart';
import 'recurring.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final isDark = store.themeMode == ThemeMode.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(s.tabSettings, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ),
        _section(c, s.appearance),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: _themeOption(context, c, s.light, false, !isDark, store)),
              const SizedBox(width: 12),
              Expanded(child: _themeOption(context, c, s.dark, true, isDark, store)),
            ],
          ),
        ),
        _section(c, s.language),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Segmented(
            labels: const ['Tiếng Việt', 'English'],
            index: store.lang == AppLang.vi ? 0 : 1,
            height: 40,
            onChanged: (i) => store.setLang(i == 0 ? AppLang.vi : AppLang.en),
          ),
        ),
        _section(c, s.general),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _row(c, Icons.attach_money, const Color(0xFF16A06A), s.currency,
                  trailing: Text('VND (đ)', style: TextStyle(color: c.muted, fontSize: 16))),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.grid_view_rounded, const Color(0xFF8B5CF6), s.manageCategories,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${store.categories.length}', style: TextStyle(color: c.muted, fontSize: 16)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: c.muted),
                  ])),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.savings_outlined, const Color(0xFFF59E0B), s.budgetTitle,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen())),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${store.budgets.length}', style: TextStyle(color: c.muted, fontSize: 16)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: c.muted),
                  ])),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.repeat, const Color(0xFF14B8A6), s.recurringTitle,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const RecurringScreen())),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${store.recurrings.length}', style: TextStyle(color: c.muted, fontSize: 16)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: c.muted),
                  ])),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.notifications_none, const Color(0xFF3B82F6), s.reminder,
                  sub: store.reminder ? s.reminderOn(store.reminderHour, store.reminderMinute) : s.off,
                  onTap: store.reminder ? () => _pickTime(context, store) : null,
                  trailing: Switch(
                    value: store.reminder,
                    onChanged: (v) => _toggleReminder(context, store, v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: c.income,
                  )),
            ],
          ),
        ),
        _section(c, s.data),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Builder để lấy vị trí của chính dòng này làm điểm neo bảng chia sẻ.
              Builder(
                builder: (rowCtx) => _row(c, Icons.cloud_upload_outlined, const Color(0xFF16A06A), s.backup,
                    sub: store.lastBackup == null ? s.neverBackedUp : s.lastBackupAt(_when(store.lastBackup!)),
                    onTap: () => _backup(rowCtx, store),
                    trailing: Icon(Icons.chevron_right, color: c.muted)),
              ),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.settings_backup_restore, const Color(0xFF3B82F6), s.restore,
                  sub: s.restoreSub,
                  onTap: () => _restore(context, store),
                  trailing: Icon(Icons.chevron_right, color: c.muted)),
              Divider(height: 1, color: c.divider),
              Builder(
                builder: (rowCtx) => _row(c, Icons.download_outlined, c.muted, s.exportCsv,
                    sub: s.csvSub,
                    onTap: () => _export(rowCtx, store),
                    trailing: Icon(Icons.chevron_right, color: c.muted)),
              ),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.delete_outline, c.expense, s.clearAll,
                  sub: s.cannotUndoShort,
                  titleColor: c.expense,
                  onTap: () => _confirmClear(context, store)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(child: Text(s.version, style: TextStyle(color: c.muted))),
      ],
    );
  }

  Widget _section(AppColors c, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 0, 10),
        child: Text(t, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800, letterSpacing: .5)),
      );

  Widget _themeOption(BuildContext context, AppColors c, String label, bool dark, bool selected, AppStore store) {
    final prevBg = dark ? const Color(0xFF0D1412) : Colors.white;
    final bar1 = dark ? const Color(0xFF5FD8AE) : const Color(0xFF0B5D4B);
    final bar2 = dark ? const Color(0xFF243029) : const Color(0xFFE9EDEB);
    return GestureDetector(
      onTap: () => store.setTheme(dark ? ThemeMode.dark : ThemeMode.light),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0xFF1F2A27) : const Color(0xFFF0F3F2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? c.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Container(
              height: 76,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: prevBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 54,
                      height: 10,
                      decoration: BoxDecoration(color: bar1, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(
                      height: 10,
                      decoration: BoxDecoration(color: bar2, borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _row(AppColors c, IconData icon, Color col, String title,
      {String? sub, Widget? trailing, VoidCallback? onTap, Color? titleColor}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: col.op(c.isDark ? 0.2 : 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: col, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: titleColor ?? c.text)),
                  if (sub != null) Text(sub, style: TextStyle(color: c.muted, fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReminder(BuildContext context, AppStore store, bool v) async {
    final ok = await store.setReminder(v);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.noPermission)));
    }
  }

  Future<void> _pickTime(BuildContext context, AppStore store) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: store.reminderHour, minute: store.reminderMinute),
      helpText: S.current.reminderTime,
    );
    if (t != null) await store.setReminderTime(t.hour, t.minute);
  }

  /// iOS 26 và iPad bắt buộc có vị trí neo cho bảng chia sẻ, thiếu sẽ báo lỗi.
  Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  String _when(DateTime d) => '${dm(d)}, ${d.year} · ${hm(d)}';

  void _snack(BuildContext context, String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      action: action,
      persist: false, // có nút Hoàn tác vẫn tự ẩn
      duration: Duration(seconds: action == null ? 4 : 8),
    ));
  }

  Future<void> _backup(BuildContext context, AppStore store) async {
    try {
      final saved = await shareBackup(store, origin: _originOf(context));
      if (!saved) return;
      store.markBackedUp();
      if (context.mounted) _snack(context, S.current.backupDone);
    } catch (e) {
      debugPrint('Sao lưu lỗi: $e');
      if (context.mounted) _snack(context, S.current.backupFailed);
    }
  }

  Future<void> _restore(BuildContext context, AppStore store) async {
    final s = S.current;
    final Backup? b;
    try {
      b = await pickBackup();
    } catch (e) {
      debugPrint('Đọc bản sao lưu lỗi: $e');
      if (context.mounted) _snack(context, s.invalidBackup);
      return;
    }
    if (b == null || !context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.restoreQ),
        content: Text(s.restoreBody(_when(b!.exportedAt), b.txs.length, b.categories.length, store.txs.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.restoreAction)),
        ],
      ),
    );
    if (ok != true) return;

    final before = store.toBackup(); // giữ lại để hoàn tác
    await store.restore(b);
    if (context.mounted) {
      _snack(context, S.current.restored(b.txs.length),
          action: SnackBarAction(label: S.current.undo, onPressed: () => store.restore(before)));
    }
  }

  Future<void> _export(BuildContext context, AppStore store) async {
    if (store.txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.current.nothingToExport)),
      );
      return;
    }
    try {
      await shareCsv(store, origin: _originOf(context));
    } catch (e) {
      debugPrint('Xuất CSV lỗi: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.current.exportFailed)),
        );
      }
    }
  }

  Future<void> _confirmClear(BuildContext context, AppStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.current.clearAllQ),
        content: Text(S.current.clearAllBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.current.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.current.deleteAll)),
        ],
      ),
    );
    if (ok == true) await store.clearAll();
  }
}
