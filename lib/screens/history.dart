import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum Period { all, today, week, month, lastMonth, custom }

/// Khoảng [from, to) của một mốc thời gian; null = không giới hạn.
(DateTime?, DateTime?) periodRange(Period p, DateTime now, [DateTimeRange? custom]) {
  final today = DateTime(now.year, now.month, now.day);
  return switch (p) {
    Period.all => (null, null),
    Period.today => (today, today.add(const Duration(days: 1))),
    Period.week => (
        today.subtract(Duration(days: today.weekday - 1)),
        today.subtract(Duration(days: today.weekday - 1)).add(const Duration(days: 7)),
      ),
    Period.month => (DateTime(now.year, now.month), DateTime(now.year, now.month + 1)),
    Period.lastMonth => (DateTime(now.year, now.month - 1), DateTime(now.year, now.month)),
    Period.custom => custom == null
        ? (null, null)
        : (custom.start, DateTime(custom.end.year, custom.end.month, custom.end.day + 1)),
  };
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filter = 0; // 0 tất cả, 1 chi, 2 thu
  final _searchCtl = TextEditingController();
  Period _period = Period.all;
  DateTimeRange? _custom;
  final Set<String> _cats = {};

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  bool get _filtering =>
      _filter != 0 || _period != Period.all || _cats.isNotEmpty || _searchCtl.text.trim().isNotEmpty;

  void _clearFilters() => setState(() {
        _filter = 0;
        _period = Period.all;
        _custom = null;
        _cats.clear();
        _searchCtl.clear();
      });

  String _periodLabel(S s, Period p) => switch (p) {
        Period.all => s.allTime,
        Period.today => s.today,
        Period.week => s.thisWeek,
        Period.month => s.thisMonth,
        Period.lastMonth => s.lastMonth,
        Period.custom => _custom == null
            ? s.customRange
            : '${s.dayMonthShort(_custom!.start)} – ${s.dayMonthShort(_custom!.end)}',
      };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final q = searchKey(_searchCtl.text.trim());
    final (from, to) = periodRange(_period, DateTime.now(), _custom);

    final list = store.txs.where((t) {
      if (_filter == 1 && t.type != TxType.expense) return false;
      if (_filter == 2 && t.type != TxType.income) return false;
      if (from != null && t.date.isBefore(from)) return false;
      if (to != null && !t.date.isBefore(to)) return false;
      if (_cats.isNotEmpty && !_cats.contains(t.categoryId)) return false;
      if (q.isEmpty) return true;
      return searchKey(s.catName(store.cat(t.categoryId))).contains(q) || searchKey(t.note).contains(q);
    }).toList();

    // Nhóm theo ngày (txs đã sắp xếp giảm dần).
    final groups = <List<Tx>>[];
    for (final t in list) {
      if (groups.isNotEmpty && sameDay(groups.last.first.date, t.date)) {
        groups.last.add(t);
      } else {
        groups.add([t]);
      }
    }

    final catLabel = switch (_cats.length) {
      0 => s.allCategories,
      1 => s.catName(store.cat(_cats.first)),
      _ => s.categoriesSelected(_cats.length),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(s.tabHistory, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Flexible(
              child: Text(s.txTotal(store.txs.length),
                  textAlign: TextAlign.right, style: TextStyle(color: c.muted, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(18)),
          child: TextField(
            controller: _searchCtl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: c.muted),
              hintText: s.searchHint,
              hintStyle: TextStyle(color: c.muted),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dropdown(c, Icons.calendar_today_outlined, _periodLabel(s, _period), _period != Period.all,
                  () => _pickPeriod(context, s)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dropdown(
                  c, Icons.grid_view_rounded, catLabel, _cats.isNotEmpty, () => _pickCategories(context, store, s)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, l) in [s.all, s.expense, s.income].indexed)
              GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _filter == i ? c.heroStart : c.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _filter == i ? c.heroStart : c.divider),
                  ),
                  child: Text(l,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _filter == i ? Colors.white : c.text)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_filtering) ...[
          _summary(c, s, list),
          const SizedBox(height: 14),
        ],
        if (groups.isEmpty) EmptyHint(s.noTx),
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text(dayLabel(g.first.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text('${s.net} ${vnd(g.fold(0, (s, t) => s + t.signed), sign: true)}',
                        style: TextStyle(color: c.muted, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < g.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: c.divider),
                  TxTile(tx: g[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Nút mở bộ lọc (thời gian / danh mục); tô màu khi đang lọc.
  Widget _dropdown(AppColors c, IconData icon, String label, bool active, VoidCallback onTap) {
    final fg = active ? c.primary : c.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? c.primary.op(c.isDark ? 0.2 : 0.1) : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? c.primary : c.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? c.primary : c.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
            ),
            Icon(Icons.expand_more, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }

  /// Tổng thu / chi / ròng của các giao dịch đang hiển thị.
  Widget _summary(AppColors c, S s, List<Tx> list) {
    final inc = list.where((t) => t.type == TxType.income).fold(0, (a, t) => a + t.amount);
    final exp = list.where((t) => t.type == TxType.expense).fold(0, (a, t) => a + t.amount);
    Widget cell(String label, String v, Color col) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12.5)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.matching(list.length),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              GestureDetector(
                onTap: _clearFilters,
                child: Text(s.clearFilters, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              cell(s.totalIncome, vnd(inc, sign: true), c.income),
              const SizedBox(width: 10),
              cell(s.totalExpense, vnd(-exp), c.expense),
              const SizedBox(width: 10),
              cell(s.net, vnd(inc - exp, sign: true), c.text),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickPeriod(BuildContext context, S s) async {
    final c = AppColors.of(context);
    final picked = await showModalBottomSheet<Period>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in Period.values)
                ListTile(
                  title: Text(p == Period.custom ? s.customRange : _periodLabel(s, p),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: _period == p ? Icon(Icons.check, color: c.primary) : null,
                  onTap: () => Navigator.pop(ctx, p),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    if (picked == Period.custom) {
      final now = DateTime.now();
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: _custom,
      );
      if (r == null) return;
      setState(() {
        _custom = r;
        _period = Period.custom;
      });
    } else {
      setState(() => _period = picked);
    }
  }

  Future<void> _pickCategories(BuildContext context, AppStore store, S s) async {
    final c = AppColors.of(context);
    // Đang lọc Chi/Thu thì chỉ hiện danh mục của loại đó.
    final types = switch (_filter) {
      1 => [TxType.expense],
      2 => [TxType.income],
      _ => [TxType.expense, TxType.income],
    };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        void toggle(String id) {
          setState(() {
            if (!_cats.remove(id)) _cats.add(id);
          });
          setS(() {});
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.category, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                      if (_cats.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(_cats.clear);
                            setS(() {});
                          },
                          child: Text(s.allCategories),
                        ),
                    ],
                  ),
                  for (final t in types) ...[
                    const SizedBox(height: 12),
                    Text(t == TxType.expense ? s.expense : s.income,
                        style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in store.catsOf(t)) _catChip(c, s, cat, _cats.contains(cat.id), toggle),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: Text(s.done, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _catChip(AppColors c, S s, Category cat, bool sel, void Function(String) onTap) {
    final col = Color(cat.color);
    return GestureDetector(
      onTap: () => onTap(cat.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: sel ? col.op(c.isDark ? 0.25 : 0.14) : c.chip,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: sel ? col : Colors.transparent, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CatIcon(category: cat, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(s.catName(cat),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: sel ? col : c.text)),
            ),
            if (sel) ...[
              const SizedBox(width: 6),
              Icon(Icons.check, size: 16, color: col),
            ],
          ],
        ),
      ),
    );
  }
}
