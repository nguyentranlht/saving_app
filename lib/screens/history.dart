import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filter = 0; // 0 tất cả, 1 chi, 2 thu
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final q = _q.trim().toLowerCase();

    final list = store.txs.where((t) {
      if (_filter == 1 && t.type != TxType.expense) return false;
      if (_filter == 2 && t.type != TxType.income) return false;
      if (q.isEmpty) return true;
      final name = s.catName(store.cat(t.categoryId)).toLowerCase();
      return name.contains(q) || t.note.toLowerCase().contains(q);
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
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: c.muted),
              hintText: s.searchHint,
              hintStyle: TextStyle(color: c.muted),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
}
