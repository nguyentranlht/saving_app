import 'package:flutter/material.dart';

import '../export.dart';
import '../format.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'categories.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final isDark = store.themeMode == ThemeMode.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Cài đặt', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ),
        _section(c, 'GIAO DIỆN'),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: _themeOption(context, c, 'Sáng', false, !isDark, store)),
              const SizedBox(width: 12),
              Expanded(child: _themeOption(context, c, 'Tối', true, isDark, store)),
            ],
          ),
        ),
        _section(c, 'CHUNG'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _row(c, Icons.attach_money, const Color(0xFF16A06A), 'Đơn vị tiền tệ',
                  trailing: Text('VND (đ)', style: TextStyle(color: c.muted, fontSize: 16))),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.grid_view_rounded, const Color(0xFF8B5CF6), 'Quản lý danh mục',
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${store.categories.length}', style: TextStyle(color: c.muted, fontSize: 16)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: c.muted),
                  ])),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.notifications_none, const Color(0xFF3B82F6), 'Nhắc ghi chép',
                  sub: store.reminder
                      ? 'Mỗi ngày lúc ${two(store.reminderHour)}:${two(store.reminderMinute)} · chạm để đổi giờ'
                      : 'Đang tắt',
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
        _section(c, 'DỮ LIỆU'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _row(c, Icons.download_outlined, c.muted, 'Xuất dữ liệu (CSV)',
                  onTap: () => _export(context, store),
                  trailing: Icon(Icons.chevron_right, color: c.muted)),
              Divider(height: 1, color: c.divider),
              _row(c, Icons.delete_outline, c.expense, 'Xóa toàn bộ dữ liệu',
                  sub: 'Không thể hoàn tác',
                  titleColor: c.expense,
                  onTap: () => _confirmClear(context, store)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(child: Text('Sổ thu chi · phiên bản 1.0', style: TextStyle(color: c.muted))),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chưa được cấp quyền thông báo. Hãy bật trong Cài đặt của điện thoại.'),
      ));
    }
  }

  Future<void> _pickTime(BuildContext context, AppStore store) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: store.reminderHour, minute: store.reminderMinute),
      helpText: 'Giờ nhắc ghi chép',
    );
    if (t != null) await store.setReminderTime(t.hour, t.minute);
  }

  Future<void> _export(BuildContext context, AppStore store) async {
    if (store.txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có giao dịch nào để xuất')),
      );
      return;
    }
    try {
      await shareCsv(store);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xuất được dữ liệu')),
        );
      }
    }
  }

  Future<void> _confirmClear(BuildContext context, AppStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu?'),
        content: const Text('Tất cả giao dịch sẽ bị xóa và danh mục trở về mặc định. Không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa hết')),
        ],
      ),
    );
    if (ok == true) await store.clearAll();
  }
}
