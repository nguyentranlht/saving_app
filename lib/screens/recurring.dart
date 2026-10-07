import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_transaction.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  void _open(BuildContext context, {Recurring? rule}) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddTransactionScreen(editingRule: rule, initialFreq: Freq.monthly),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    // Đang chạy trước, sắp đến hạn trước.
    final rules = [...store.recurrings]..sort((a, b) {
        if (a.active != b.active) return a.active ? -1 : 1;
        return a.next.compareTo(b.next);
      });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                CircleBtn(icon: Icons.chevron_left, onTap: () => Navigator.of(context).pop()),
                Expanded(
                  child: Center(
                    child: Text(s.recurringTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
                CircleBtn(icon: Icons.add, bg: c.primary, fg: c.onPrimary, onTap: () => _open(context)),
              ],
            ),
            const SizedBox(height: 14),
            Text(s.recurringHint, style: TextStyle(color: c.muted, fontSize: 14, height: 1.4)),
            const SizedBox(height: 14),
            if (rules.isEmpty)
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(Icons.repeat, size: 40, color: c.muted),
                      const SizedBox(height: 10),
                      Text(s.recurringEmpty,
                          textAlign: TextAlign.center, style: TextStyle(color: c.muted, height: 1.4)),
                    ],
                  ),
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                radius: 28,
                child: Column(
                  children: [
                    for (var i = 0; i < rules.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.divider),
                      _tile(context, c, s, store, rules[i]),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _open(context),
              child: Container(
                height: 66,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      child: Text(s.addRecurring,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: 17)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppColors c, S s, AppStore store, Recurring r) {
    final cat = store.cat(r.categoryId);
    final title = r.note.isEmpty ? s.catName(cat) : r.note;
    final amount = r.type == TxType.expense ? -r.amount : r.amount;
    return InkWell(
      onTap: () => _open(context, rule: r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Opacity(
          opacity: r.active ? 1 : 0.55,
          child: Row(
            children: [
              CatIcon(category: cat),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(s.freqDetail(r.freq, r.anchor),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12.5)),
                    Text(r.active ? s.nextOn(r.next) : s.paused,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: r.active ? c.primary : c.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(vnd(amount, sign: true),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: r.type == TxType.expense ? c.expense : c.income)),
                    ),
                    Switch(
                      value: r.active,
                      onChanged: (v) => store.setRecurringActive(r, v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: c.income,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
