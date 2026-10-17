import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Biểu tượng gợi ý cho mục tiêu (key trong kIcons).
const kGoalIcons = [
  'savings', 'devices', 'phone', 'travel', 'beach', 'home', 'car', 'bike', 'gift', 'school', 'health', 'family',
];

/// Ô icon bo tròn theo màu mục tiêu.
class GoalIcon extends StatelessWidget {
  const GoalIcon({super.key, required this.goal, this.size = 44});
  final Goal goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final col = Color(goal.color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: col.op(c.isDark ? 0.2 : 0.14), borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(kIcons[goal.icon] ?? Icons.savings_outlined, color: col, size: size * 0.48),
    );
  }
}

/// Một dòng mục tiêu: icon, tên, %, thanh tiến độ, đã để dành / cần, dòng gợi ý.
class GoalBar extends StatelessWidget {
  const GoalBar({super.key, required this.goal, this.onTap});
  final Goal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = S.of(context);
    final g = goal;
    final col = Color(g.color);
    final per = g.perMonth(DateTime.now());
    final String hint;
    if (g.done) {
      hint = s.doneOn(dm(g.doneAt!));
    } else if (g.reached) {
      hint = s.goalReached;
    } else if (per != null) {
      hint = s.needPerMonth(compact(per));
    } else {
      hint = s.goalLeft(compact(g.remaining));
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            GoalIcon(goal: g),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(g.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Text('${(g.progress * 100).floor()}%',
                          style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: g.progress,
                      minHeight: 10,
                      backgroundColor: c.segment,
                      valueColor: AlwaysStoppedAnimation(col),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.savedOf(compact(g.saved), compact(g.target)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.muted, fontSize: 12.5)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: g.reached && !g.done ? c.income : c.muted,
                                fontSize: 12.5,
                                fontWeight: g.reached && !g.done ? FontWeight.w800 : FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void openGoal(BuildContext context, Goal g) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: g.id)));

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final active = store.goals.where((g) => !g.done).toList();
    final done = store.goals.where((g) => g.done).toList()..sort((a, b) => b.doneAt!.compareTo(a.doneAt!));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _header(context, s.goalsTitle),
            const SizedBox(height: 14),
            Text(s.goalsHint, style: TextStyle(color: c.muted, fontSize: 14, height: 1.4)),
            const SizedBox(height: 14),
            // Tổng đang để dành và số dư khả dụng.
            AppCard(
              child: Row(
                children: [
                  Expanded(child: _total(c, s.goalsActive, store.savedTotal, c.primary)),
                  Container(width: 1, height: 40, color: c.divider),
                  const SizedBox(width: 14),
                  Expanded(child: _total(c, s.availableBalance.toUpperCase(), store.balance, c.text)),
                ],
              ),
            ),
            if (active.isNotEmpty) ...[
              _section(c, s.goalsActive),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Column(
                  children: [
                    for (var i = 0; i < active.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.divider),
                      GoalBar(goal: active[i], onTap: () => openGoal(context, active[i])),
                    ],
                  ],
                ),
              ),
            ],
            if (store.goals.isEmpty) ...[
              const SizedBox(height: 14),
              AppCard(child: EmptyHint(s.noGoals)),
            ],
            const SizedBox(height: 16),
            _dashedButton(c, s.addGoal, () => showGoalEditor(context)),
            if (done.isNotEmpty) ...[
              _section(c, s.goalsDone),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Column(
                  children: [
                    for (var i = 0; i < done.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.divider),
                      GoalBar(goal: done[i], onTap: () => openGoal(context, done[i])),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _total(AppColors c, String label, int v, Color col) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .3)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(vnd(v), style: TextStyle(color: col, fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ],
      );
}

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final g = store.goal(goalId);
    if (g == null) return const Scaffold(body: SizedBox()); // vừa bị xóa
    final col = Color(g.color);
    final entries = g.entries.reversed.toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                CircleBtn(icon: Icons.chevron_left, onTap: () => Navigator.of(context).pop()),
                const Spacer(),
                CircleBtn(icon: Icons.edit_outlined, onTap: () => showGoalEditor(context, existing: g)),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GoalIcon(goal: g, size: 64),
                  const SizedBox(height: 12),
                  Text(g.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(vnd(g.saved), style: TextStyle(color: col, fontSize: 34, fontWeight: FontWeight.w800)),
                  ),
                  Text('/ ${vnd(g.target)}', style: TextStyle(color: c.muted, fontSize: 14)),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: g.progress,
                      minHeight: 12,
                      backgroundColor: c.segment,
                      valueColor: AlwaysStoppedAnimation(col),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_status(s, g),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: g.reached && !g.done ? c.income : c.muted, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            if (!g.done) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _button(c, Icons.add, s.deposit, c.primary, filled: !g.reached,
                        onTap: () => showGoalMoney(context, g, deposit: true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _button(c, Icons.remove, s.withdraw, c.text,
                        onTap: g.saved > 0 ? () => showGoalMoney(context, g, deposit: false) : null),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _button(c, Icons.shopping_bag_outlined, s.useMoney, c.income,
                  filled: g.reached, onTap: g.saved > 0 ? () => useGoalMoney(context, g) : null),
            ],
            if (entries.isNotEmpty) ...[
              _section(c, s.goalHistory),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.divider),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(entries[i].amount > 0 ? Icons.south_west : Icons.north_east,
                                size: 18, color: entries[i].amount > 0 ? c.income : c.muted),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Text(
                                  '${entries[i].amount > 0 ? s.deposit : s.withdraw} · ${dayLabel(entries[i].date)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(vnd(entries[i].amount, sign: true),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: entries[i].amount > 0 ? c.income : c.text)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _status(S s, Goal g) {
    if (g.done) return s.doneOn(dm(g.doneAt!));
    if (g.reached) return s.goalReached;
    final parts = [s.goalLeft(vnd(g.remaining))];
    if (g.deadline != null) {
      parts.add('${s.goalDeadline} ${dm(g.deadline!)}${g.deadline!.year != DateTime.now().year ? ', ${g.deadline!.year}' : ''}');
      final per = g.perMonth(DateTime.now());
      if (per != null) parts.add(s.needPerMonth(compact(per)));
    }
    return parts.join(' · ');
  }

  Widget _button(AppColors c, IconData icon, String label, Color col, {bool filled = false, VoidCallback? onTap}) {
    final enabled = onTap != null;
    final fg = filled ? Colors.white : col;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: filled ? col : col.op(c.isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Bottom sheet ----

Future<T?> _sheet<T>(BuildContext context, Widget Function(BuildContext ctx, StateSetter setS) build) {
  final c = AppColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(child: SingleChildScrollView(child: build(ctx, setS))),
      ),
    ),
  );
}

InputDecoration _field(AppColors c, String hint, {String? suffix}) => InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: c.chip,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );

ButtonStyle _primary(AppColors c) => ElevatedButton.styleFrom(
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
      elevation: 0,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    );

int _money(String text) => int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Thêm / sửa mục tiêu (tên, số tiền cần, hạn, biểu tượng, màu; xóa nếu đang sửa).
Future<void> showGoalEditor(BuildContext context, {Goal? existing}) {
  final store = StoreScope.read(context);
  final s = S.current;
  final nameCtl = TextEditingController(text: existing?.name ?? '');
  final targetCtl = TextEditingController(text: existing == null ? '' : groupDigits(existing.target));
  var icon = existing?.icon ?? kGoalIcons.first;
  var color = existing?.color ?? 0xFF16A06A;
  DateTime? deadline = existing?.deadline;

  return _sheet<void>(context, (ctx, setS) {
    final c = AppColors.of(ctx);
    final canSave = nameCtl.text.trim().isNotEmpty && _money(targetCtl.text) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(existing == null ? s.newGoal : s.editGoal, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(
          controller: nameCtl,
          autofocus: existing == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(c, s.goalName),
          onChanged: (_) => setS(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: targetCtl,
          keyboardType: TextInputType.number,
          inputFormatters: [MoneyFormatter()],
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text),
          decoration: _field(c, s.goalTarget, suffix: 'đ'),
          onChanged: (_) => setS(() {}),
        ),
        const SizedBox(height: 12),
        // Hạn (không bắt buộc).
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: ctx,
              initialDate: deadline ?? DateTime(now.year, now.month + 6, now.day),
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: DateTime(now.year + 30),
            );
            if (d != null) setS(() => deadline = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.event_outlined, color: c.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      deadline == null ? s.noDeadline : '${s.goalDeadline}: ${dm(deadline!)}, ${deadline!.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: deadline == null ? c.muted : c.text, fontWeight: FontWeight.w600)),
                ),
                if (deadline != null)
                  GestureDetector(
                    onTap: () => setS(() => deadline = null),
                    child: Icon(Icons.close, color: c.muted, size: 20),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(s.icon, style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final k in kGoalIcons)
              GestureDetector(
                onTap: () => setS(() => icon = k),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: icon == k ? Color(color).op(0.2) : c.chip,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: icon == k ? Color(color) : Colors.transparent, width: 2),
                  ),
                  child: Icon(kIcons[k] ?? Icons.savings_outlined, color: icon == k ? Color(color) : c.muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(s.color, style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final col in kPalette)
              GestureDetector(
                onTap: () => setS(() => color = col),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(col),
                    shape: BoxShape.circle,
                    border: Border.all(color: color == col ? c.text : Colors.transparent, width: 3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            if (existing != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (dctx) => AlertDialog(
                        title: Text(s.deleteGoalQ),
                        content: Text(s.deleteGoalHint),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(s.cancel)),
                          TextButton(onPressed: () => Navigator.pop(dctx, true), child: Text(s.delete)),
                        ],
                      ),
                    );
                    if (ok != true || !ctx.mounted) return;
                    Navigator.pop(ctx);
                    // Sửa chỉ mở từ màn chi tiết: đóng luôn màn đó rồi mới xóa.
                    if (context.mounted) Navigator.of(context).pop();
                    store.deleteGoal(existing.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.expense,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text(s.delete, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canSave
                    ? () {
                        store.upsertGoal(Goal(
                          id: existing?.id ?? 'g${DateTime.now().microsecondsSinceEpoch}',
                          name: nameCtl.text.trim(),
                          icon: icon,
                          color: color,
                          target: _money(targetCtl.text),
                          deadline: deadline,
                          entries: existing?.entries,
                          doneAt: existing?.doneAt,
                          spentTxId: existing?.spentTxId,
                        ));
                        Navigator.pop(ctx);
                      }
                    : null,
                style: _primary(c),
                child: Text(s.save, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  });
}

/// Nạp tiền vào ([deposit]) hoặc rút tiền ra khỏi mục tiêu.
Future<void> showGoalMoney(BuildContext context, Goal g, {required bool deposit}) {
  final store = StoreScope.read(context);
  final s = S.current;
  final ctl = TextEditingController();
  // Gợi ý nhanh: số còn thiếu, số cần mỗi tháng (khi nạp); toàn bộ (khi rút).
  final per = g.perMonth(DateTime.now());
  final quick = deposit
      ? <int>{if (per != null && per < g.remaining) per, if (g.remaining > 0) g.remaining}.toList()
      : <int>[g.saved];

  return _sheet<void>(context, (ctx, setS) {
    final c = AppColors.of(ctx);
    final v = _money(ctl.text);
    final max = deposit ? null : g.saved;
    final ok = v > 0 && (max == null || v <= max);
    final over = deposit && v > store.balance;
    void save() {
      if (!ok) return;
      store.moveToGoal(g.id, deposit ? v : -v);
      Navigator.pop(ctx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(deposit ? s.depositTitle : s.withdrawTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted)),
        const SizedBox(height: 14),
        TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [MoneyFormatter()],
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.text),
          decoration: _field(c, '0', suffix: 'đ'),
          onChanged: (_) => setS(() {}),
          onSubmitted: (_) => save(),
        ),
        const SizedBox(height: 8),
        Text(
          over ? s.overAvailable : (deposit ? s.availableNow(vnd(store.balance)) : s.savedNow(vnd(g.saved))),
          style: TextStyle(color: over ? const Color(0xFFB45309) : c.muted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        if (quick.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in quick)
                ActionChip(
                  label: Text(vnd(q)),
                  backgroundColor: c.chip,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => setS(() => ctl.text = groupDigits(q)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: ok ? save : null,
          style: _primary(c),
          child: Text(deposit ? s.deposit : s.withdraw, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ],
    );
  });
}

/// Dùng tiền: chọn danh mục chi, số đã để dành thành một khoản chi, mục tiêu hoàn thành.
Future<void> useGoalMoney(BuildContext context, Goal g) {
  final store = StoreScope.read(context);
  final s = S.current;
  return _sheet<void>(context, (ctx, setS) {
    final c = AppColors.of(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.useMoneyTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(s.useMoneyHint(vnd(g.saved)), style: TextStyle(color: c.muted, height: 1.4)),
        const SizedBox(height: 14),
        for (final cat in store.catsOf(TxType.expense))
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              store.spendGoal(g.id, cat.id);
              Navigator.pop(ctx);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CatIcon(category: cat),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(s.catName(cat),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  Icon(Icons.chevron_right, color: c.muted),
                ],
              ),
            ),
          ),
      ],
    );
  });
}

Widget _header(BuildContext context, String title) => Row(
      children: [
        CircleBtn(icon: Icons.chevron_left, onTap: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 46),
      ],
    );

Widget _section(AppColors c, String t) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 10),
      child: Text(t, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800, letterSpacing: .5)),
    );

Widget _dashedButton(AppColors c, String label, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.muted.op(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: c.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: 17)),
            ),
          ],
        ),
      ),
    );
