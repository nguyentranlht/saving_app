import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum StatsMode { week, month, year }

/// Khoảng [from, to) của kỳ thống kê; [offset] = số kỳ lùi về trước (0 = kỳ hiện tại).
(DateTime, DateTime) statsRange(StatsMode m, int offset, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (m) {
    case StatsMode.week:
      final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1) - 7 * offset);
      return (monday, DateTime(monday.year, monday.month, monday.day + 7));
    case StatsMode.month:
      return (DateTime(now.year, now.month - offset), DateTime(now.year, now.month - offset + 1));
    case StatsMode.year:
      return (DateTime(now.year - offset), DateTime(now.year - offset + 1));
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsMode _mode = StatsMode.week;
  int _offset = 0;
  TxType _type = TxType.expense; // danh sách theo danh mục đang xem chi hay thu

  void _setMode(StatsMode m) => setState(() {
        _mode = m;
        _offset = 0;
      });

  /// Chuyển sang xem một tháng cụ thể (từ biểu đồ / bảng của chế độ Năm).
  void _openMonth(DateTime month) {
    final now = DateTime.now();
    setState(() {
      _mode = StatsMode.month;
      _offset = (now.year - month.year) * 12 + now.month - month.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final now = DateTime.now();
    final (from, to) = statsRange(_mode, _offset, now);
    final (prevFrom, prevTo) = statsRange(_mode, _offset + 1, now);
    // Kỳ hiện tại chưa hết: so với cùng thời điểm của kỳ trước cho công bằng.
    final ongoing = now.isBefore(to);
    final prevCut = ongoing ? prevFrom.add(now.difference(from)) : prevTo;

    final spent = store.total(TxType.expense, from: from, to: to);
    final earned = store.total(TxType.income, from: from, to: to);
    final prevSpent = store.total(TxType.expense, from: prevFrom, to: prevCut);
    final prevEarned = store.total(TxType.income, from: prevFrom, to: prevCut);
    final isExpense = _type == TxType.expense;
    final main = isExpense ? spent : earned; // tổng của loại đang xem ở danh sách theo danh mục

    // Cột biểu đồ
    final labels = <String>[];
    final buckets = <(DateTime, DateTime)>[];
    switch (_mode) {
      case StatsMode.week:
        for (var i = 0; i < 7; i++) {
          final d0 = DateTime(from.year, from.month, from.day + i);
          buckets.add((d0, DateTime(d0.year, d0.month, d0.day + 1)));
          labels.add(s.weekdays[i]);
        }
      case StatsMode.month:
        // Các khối 7 ngày: 1–7, 8–14, 15–21, 22–28, 29–cuối tháng.
        final last = DateTime(from.year, from.month + 1, 0).day;
        for (var d = 1; d <= last; d += 7) {
          final end = d + 6 > last ? last : d + 6;
          buckets.add((DateTime(from.year, from.month, d), DateTime(from.year, from.month, end + 1)));
          labels.add(d == end ? '$d' : '$d–$end');
        }
      case StatsMode.year:
        for (var m = 1; m <= 12; m++) {
          buckets.add((DateTime(from.year, m), DateTime(from.year, m + 1)));
          labels.add(s.monthShort(m));
        }
    }
    final inc = [for (final (a, b) in buckets) store.total(TxType.income, from: a, to: b)];
    final exp = [for (final (a, b) in buckets) store.total(TxType.expense, from: a, to: b)];
    final maxV = [...inc, ...exp].fold<int>(0, (m, v) => v > m ? v : m);
    // Cột của hôm nay / tháng này được in đậm.
    final current = [for (final (a, b) in buckets) !now.isBefore(a) && now.isBefore(b)];

    final top = store.byCategory(_type, from: from, to: to).take(5).toList();
    final prevByCat = {
      for (final e in store.byCategory(_type, from: prevFrom, to: prevCut)) e.key.id: e.value,
    };

    final other = store.cat('other_e');
    final otherShare = (isExpense && other != null && spent > 0)
        ? (top.where((e) => e.key.id == other.id).fold<int>(0, (a, e) => a + e.value) / spent)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: Text(s.tabStats, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
            SizedBox(
              width: 210,
              child: Segmented(
                labels: [s.week, s.month, s.year],
                index: _mode.index,
                height: 34,
                onChanged: (i) => _setMode(StatsMode.values[i]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _periodSwitcher(c, s, from, to),
        const SizedBox(height: 12),

        // Tổng kỳ: đã thu | đã chi cạnh nhau, mỗi bên kèm % so với kỳ trước; dưới là ròng.
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _total(c, s.earned, earned, prevEarned, c.income, upIsGood: true)),
                    VerticalDivider(width: 24, thickness: 1, color: c.divider),
                    Expanded(child: _total(c, s.spent, spent, prevSpent, c.expense, upIsGood: false)),
                  ],
                ),
              ),
              if (prevSpent > 0 || prevEarned > 0) ...[
                const SizedBox(height: 10),
                Text(s.comparedTo(_mode.index, samePoint: ongoing),
                    style: TextStyle(color: c.muted, fontSize: 12.5)),
              ],
              const SizedBox(height: 14),
              Divider(height: 1, color: c.divider),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(s.net, style: TextStyle(color: c.muted, fontSize: 15)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(vnd(earned - spent, sign: true),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Biểu đồ thu – chi
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
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _mode == StatsMode.year ? () => _openMonth(buckets[i].$1) : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _bar(inc[i], maxV, c.income, labels.length),
                                    SizedBox(width: labels.length > 7 ? 2 : 4),
                                    _bar(exp[i], maxV, c.expense, labels.length),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(labels[i],
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: current[i] ? c.text : c.muted,
                                        fontSize: 12,
                                        fontWeight: current[i] ? FontWeight.w800 : FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(_mode == StatsMode.year ? s.monthByMonthHint : s.unitNote,
                  style: TextStyle(color: c.muted, fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Chi / thu nhiều nhất theo danh mục (kèm so với kỳ trước)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(isExpense ? s.topSpending : s.topIncome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 150,
                    child: Segmented(
                      labels: [s.expenseShort, s.incomeShort],
                      index: isExpense ? 0 : 1,
                      activeColors: [c.expense, c.income],
                      height: 32,
                      onChanged: (i) => setState(() => _type = i == 0 ? TxType.expense : TxType.income),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (top.isEmpty) EmptyHint(isExpense ? s.noExpenseInPeriod : s.noIncomeInPeriod),
              for (final e in top) ...[
                Row(children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: Color(e.key.color), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(s.catName(e.key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                  const SizedBox(width: 8),
                  _delta(c, s, e.value, prevByCat[e.key.id], upIsGood: !isExpense),
                  const SizedBox(width: 10),
                  Text(compact(e.value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: e.value / main,
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

        // Năm: bảng so sánh từng tháng
        if (_mode == StatsMode.year) ...[
          const SizedBox(height: 14),
          _monthTable(c, s, store, buckets, inc, exp, now),
        ],

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
                      Text(s.otherTip(s.catName(other)), style: TextStyle(color: c.muted, height: 1.4)),
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

  String _periodLabel(S s, DateTime from, DateTime to) => switch (_mode) {
        StatsMode.week => s.weekRange(from, DateTime(to.year, to.month, to.day - 1)),
        StatsMode.month => s.monthYear(from),
        StatsMode.year => '${from.year}',
      };

  Widget _periodSwitcher(AppColors c, S s, DateTime from, DateTime to) {
    Widget arrow(IconData icon, VoidCallback? onTap) =>
        IconButton(onPressed: onTap, icon: Icon(icon), color: c.text, disabledColor: c.muted.op(0.35));
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      radius: 20,
      child: Row(
        children: [
          arrow(Icons.chevron_left, () => setState(() => _offset++)),
          Expanded(
            child: GestureDetector(
              // Chạm vào tên kỳ để quay về kỳ hiện tại.
              onTap: _offset == 0 ? null : () => setState(() => _offset = 0),
              child: Column(
                children: [
                  Text(_periodLabel(s, from, to),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (_offset > 0)
                    Text(s.backToNow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          arrow(Icons.chevron_right, _offset == 0 ? null : () => setState(() => _offset--)),
        ],
      ),
    );
  }

  /// Một cột của thẻ tổng: nhãn, số tiền, % so với kỳ trước.
  /// [upIsGood]: khoản thu tăng là tốt (xanh); khoản chi tăng là xấu (đỏ).
  Widget _total(AppColors c, String label, int now, int before, Color color, {required bool upIsGood}) {
    Widget? pill;
    if (before > 0) {
      final pct = ((now - before) / before * 100).round();
      final up = pct > 0;
      final col = pct == 0 ? c.muted : (up == upIsGood ? c.income : c.expense);
      pill = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: col.op(0.14), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (pct != 0) Icon(up ? Icons.north_east : Icons.south_east, size: 13, color: col),
          if (pct != 0) const SizedBox(width: 4),
          Text('${pct.abs()}%', style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 14)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(vnd(now), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        ),
        if (pill != null) ...[const SizedBox(height: 6), pill],
      ],
    );
  }

  /// "↑ 20%" / "↓ 15%" / "Mới" so với kỳ trước. Khoản chi: tăng là đỏ; khoản thu ([upIsGood]): tăng là xanh.
  Widget _delta(AppColors c, S s, int now, int? before, {bool upIsGood = false}) {
    if (before == null || before == 0) {
      return Text(now == 0 ? '' : s.newVsPrev,
          style: TextStyle(color: c.muted, fontSize: 12.5, fontWeight: FontWeight.w700));
    }
    final pct = ((now - before) / before * 100).round();
    if (pct == 0) return Text('0%', style: TextStyle(color: c.muted, fontSize: 12.5));
    final up = pct > 0;
    return Text('${up ? '↑' : '↓'} ${pct.abs()}%',
        style: TextStyle(
            color: up == upIsGood ? c.income : c.expense, fontSize: 12.5, fontWeight: FontWeight.w700));
  }

  /// Bảng các tháng trong năm: chi, thu, ròng và chênh lệch chi so với tháng liền trước.
  Widget _monthTable(AppColors c, S s, AppStore store, List<(DateTime, DateTime)> months, List<int> inc,
      List<int> exp, DateTime now) {
    // Tháng mới nhất trước, bỏ các tháng chưa tới.
    final rows = [
      for (var i = 0; i < months.length; i++)
        if (!months[i].$1.isAfter(now)) i,
    ].reversed.toList();
    // Tháng 1 so với tháng 12 năm trước.
    final decBefore = store.total(TxType.expense, from: DateTime(months.first.$1.year - 1, 12), to: months.first.$1);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.monthByMonth, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          for (final i in rows) ...[
            Divider(height: 1, color: c.divider),
            InkWell(
              onTap: () => _openMonth(months[i].$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(s.monthShort(months[i].$1.month),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(vnd(-exp[i]),
                                style: TextStyle(color: c.expense, fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                          Text('${s.incomeShort} ${compact(inc[i])} · ${s.net} ${compact(inc[i] - exp[i])}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _delta(c, s, exp[i], i > 0 ? exp[i - 1] : decBefore),
                    Icon(Icons.chevron_right, color: c.muted, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot(Color col, String t) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]);

  /// Cột hẹp hơn khi có nhiều cột (12 tháng).
  Widget _bar(int v, int max, Color col, int count) {
    final h = (max == 0 || v == 0) ? 4.0 : (v / max * 150).clamp(6.0, 150.0);
    final w = count > 7 ? 7.0 : 12.0;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: v == 0 ? col.op(0.25) : col,
        borderRadius: BorderRadius.circular(w / 2),
      ),
    );
  }
}
