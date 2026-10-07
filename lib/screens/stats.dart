import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _mode = 0; // 0 tuần, 1 tháng

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final days = _mode == 0 ? 7 : 30;
    final from = tomorrow.subtract(Duration(days: days));
    final prevFrom = from.subtract(Duration(days: days));
    final spent = store.total(TxType.expense, from: from, to: tomorrow);
    final prev = store.total(TxType.expense, from: prevFrom, to: from);

    // Cột biểu đồ
    final labels = <String>[];
    final inc = <int>[];
    final exp = <int>[];
    if (_mode == 0) {
      // Tuần hiện tại: T2 -> CN
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final names = s.weekdays;
      for (var i = 0; i < 7; i++) {
        final d0 = monday.add(Duration(days: i));
        final d1 = d0.add(const Duration(days: 1));
        labels.add(names[i]);
        inc.add(store.total(TxType.income, from: d0, to: d1));
        exp.add(store.total(TxType.expense, from: d0, to: d1));
      }
    } else {
      // 5 khối × 6 ngày gần nhất
      for (var i = 4; i >= 0; i--) {
        final d1 = tomorrow.subtract(Duration(days: i * 6));
        final d0 = d1.subtract(const Duration(days: 6));
        labels.add(s.dayMonthShort(d0));
        inc.add(store.total(TxType.income, from: d0, to: d1));
        exp.add(store.total(TxType.expense, from: d0, to: d1));
      }
    }
    final maxV = [...inc, ...exp].fold<int>(0, (m, v) => v > m ? v : m);

    final top = store.byCategory(TxType.expense, from: from, to: tomorrow).take(4).toList();
    final topTotal = spent;

    String? deltaText;
    bool down = true;
    if (prev > 0) {
      final pct = ((spent - prev) / prev * 100).round();
      down = pct <= 0;
      deltaText = s.delta(pct, _mode == 0);
    }
    final other = store.cat('other_e');
    final otherShare = (other != null && topTotal > 0)
        ? (top.where((e) => e.key.id == other.id).fold<int>(0, (s, e) => s + e.value) / topTotal)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: Text(s.tabStats, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
            SizedBox(
              width: 180,
              child: Segmented(
                labels: [s.week, s.month],
                index: _mode,
                height: 34,
                onChanged: (i) => setState(() => _mode = i),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.spentLast(days),
                  style: TextStyle(color: c.muted, fontSize: 15)),
              const SizedBox(height: 6),
              Text(compact(spent),
                  style: TextStyle(color: c.expense, fontSize: 40, fontWeight: FontWeight.w800)),
              if (deltaText != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (down ? c.income : c.expense).op(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(down ? Icons.south_east : Icons.north_east,
                        size: 15, color: down ? c.income : c.expense),
                    const SizedBox(width: 6),
                    Text(deltaText,
                        style: TextStyle(
                            color: down ? c.income : c.expense, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(s.incomeAndExpense,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(children: [
                        _dot(c.income, s.incomeShort),
                        const SizedBox(width: 14),
                        _dot(c.expense, s.expenseShort),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _bar(inc[i], maxV, c.income),
                                  const SizedBox(width: 4),
                                  _bar(exp[i], maxV, c.expense),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(labels[i],
                                style: TextStyle(
                                    color: c.muted,
                                    fontSize: 12,
                                    fontWeight: (_mode == 0 && i == (today.weekday - 1))
                                        ? FontWeight.w800
                                        : FontWeight.w500)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(s.unitNote,
                  style: TextStyle(color: c.muted, fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.topSpending, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (top.isEmpty) EmptyHint(s.noExpenseInPeriod),
              for (final e in top) ...[
                Row(children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: Color(e.key.color), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.catName(e.key), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                  Text('${(e.value / topTotal * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: e.value / topTotal,
                    minHeight: 10,
                    backgroundColor: c.segment,
                    valueColor: AlwaysStoppedAnimation(Color(e.key.color)),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        if (otherShare > 0.5) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: c.tipBg, borderRadius: BorderRadius.circular(24)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: c.isDark ? const Color(0xFF111A33) : Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.lightbulb_outline, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.tipTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(s.otherTip(s.catName(other)),
                          style: TextStyle(color: c.muted, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dot(Color col, String t) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]);

  Widget _bar(int v, int max, Color col) {
    final h = (max == 0 || v == 0) ? 4.0 : (v / max * 150).clamp(6.0, 150.0);
    return Container(
      width: 12,
      height: h,
      decoration: BoxDecoration(
        color: v == 0 ? col.op(0.25) : col,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
