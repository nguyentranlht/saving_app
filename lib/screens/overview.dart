import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key, required this.onGoTab});
  final ValueChanged<int> onGoTab;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  TxType _type = TxType.expense;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final n = DateTime.now();
    return _month.year == n.year && _month.month == n.month;
  }

  void _shiftMonth(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    // Số dư là cộng dồn từ trước đến nay; các số còn lại tính theo tháng đang chọn.
    final balance = store.balance;
    final from = _month;
    final to = DateTime(_month.year, _month.month + 1);
    final income = store.total(TxType.income, from: from, to: to);
    final expense = store.total(TxType.expense, from: from, to: to);
    final monthCount = store.txs.where((t) => !t.date.isBefore(from) && t.date.isBefore(to)).length;
    final entries = store.byCategory(_type, from: from, to: to);
    final totalType = _type == TxType.expense ? expense : income;
    final recent = store.txs.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting(), style: TextStyle(color: c.muted, fontSize: 14)),
                  Text(s.yourBook, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            CircleBtn(
              icon: c.isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              onTap: () => store.setTheme(c.isDark ? ThemeMode.light : ThemeMode.dark),
            ),
            const SizedBox(width: 10),
            CircleBtn(icon: Icons.settings, onTap: () => widget.onGoTab(3)),
          ],
        ),
        const SizedBox(height: 16),

        // Chọn tháng
        // Được tới tháng sau nếu chưa phải tháng hiện tại hoặc có giao dịch ghi trước cho tương lai.
        _monthSwitcher(c, s, canNext: !_isCurrentMonth || (store.txs.isNotEmpty && !store.txs.first.date.isBefore(to))),
        const SizedBox(height: 12),

        // Thẻ số dư
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.heroStart, c.heroEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(s.balance,
                        overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(s.txCount(monthCount),
                        overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(vnd(balance),
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              if (expense > income)
                _pill(Icons.warning_amber_rounded, s.spendingOver, const Color(0xFFFFD54F), const Color(0x33FFC107)),
              if (expense <= income && monthCount > 0)
                _pill(Icons.check_circle_outline, s.incomeOver, const Color(0xFFB9F6CA), const Color(0x2269F0AE)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _stat(Icons.south_west, s.monthIncome, income)),
                  const SizedBox(width: 12),
                  Expanded(child: _stat(Icons.north_east, s.monthExpense, expense)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Hành động nhanh
        Row(
          children: [
            _action(Icons.north_east, s.addExpense, c.expense, const Color(0xFFFFE3E1), const Color(0xFF3A2220),
                () => openAdd(context, type: TxType.expense)),
            _action(Icons.south_west, s.addIncome, c.income, const Color(0xFFDDF3E8), const Color(0xFF16302A),
                () => openAdd(context, type: TxType.income)),
            _action(Icons.bar_chart_rounded, s.tabStats, const Color(0xFF3B82F6), const Color(0xFFE0EAFD),
                const Color(0xFF1B2744), () => widget.onGoTab(2)),
            _action(Icons.schedule, s.tabHistory, const Color(0xFF8B5CF6), const Color(0xFFEAE3FB),
                const Color(0xFF2B2146), () => widget.onGoTab(1)),
          ],
        ),
        const SizedBox(height: 18),

        // Theo danh mục
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(s.byCategory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  SizedBox(
                    width: 170,
                    child: Segmented(
                      labels: [s.expenseShort, s.incomeShort],
                      index: _type == TxType.expense ? 0 : 1,
                      activeColors: [c.expense, c.income],
                      height: 32,
                      onChanged: (i) => setState(() => _type = i == 0 ? TxType.expense : TxType.income),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DonutChart(
                slices: [for (final e in entries) MapEntry(Color(e.key.color), e.value)],
                centerTop: _type == TxType.expense ? s.totalExpense : s.totalIncome,
                centerBottom: compact(totalType),
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty) EmptyHint(s.noData),
              for (final e in entries) _catRow(c, s, e, totalType),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Gần đây
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(s.recent, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  GestureDetector(
                    onTap: () => widget.onGoTab(1),
                    child: Text(s.seeAll, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              if (recent.isEmpty) EmptyHint(s.noTxYet),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(dayLabel(recent.first.date), style: TextStyle(color: c.muted, fontSize: 13)),
                for (var i = 0; i < recent.length; i++) ...[
                  Divider(height: 1, color: c.divider),
                  TxTile(tx: recent[i]),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _monthSwitcher(AppColors c, S s, {required bool canNext}) {
    Widget arrow(IconData icon, VoidCallback? onTap) => IconButton(
          onPressed: onTap,
          icon: Icon(icon),
          color: c.text,
          disabledColor: c.muted.op(0.35),
        );
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      radius: 20,
      child: Row(
        children: [
          arrow(Icons.chevron_left, () => _shiftMonth(-1)),
          Expanded(
            child: GestureDetector(
              // Chạm vào tên tháng để quay về tháng hiện tại.
              onTap: _isCurrentMonth
                  ? null
                  : () => setState(() => _month = DateTime(DateTime.now().year, DateTime.now().month)),
              child: Column(
                children: [
                  Text(s.monthYear(_month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (!_isCurrentMonth)
                    Text(s.backToThisMonth,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          arrow(Icons.chevron_right, canNext ? () => _shiftMonth(1) : null),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color fg, Color bg) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
        ),
      );

  Widget _stat(IconData icon, String label, int v) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child:
                  Text(vnd(v), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  Widget _action(IconData icon, String label, Color fg, Color bgLight, Color bgDark, VoidCallback onTap) {
    final c = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: c.isDark ? bgDark : bgLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: fg, size: 24),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catRow(AppColors c, S s, MapEntry<Category, int> e, int total) {
    final pct = total == 0 ? 0.0 : e.value / total * 100;
    final pctText = s.pctOfTotal(pct < 1 ? 0 : pct.round());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          CatIcon(category: e.key),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.catName(e.key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(pctText, style: TextStyle(color: c.muted, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(compact(e.value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
