import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _amber = Color(0xFFF59E0B);

/// Màu theo mức đã dùng: xanh < 80%, vàng 80–100%, đỏ khi vượt.
Color budgetColor(AppColors c, double ratio) =>
    ratio > 1 ? c.expense : (ratio >= AppStore.budgetWarnAt ? _amber : c.income);

/// Một dòng ngân sách: icon, tên, đã chi / hạn mức, thanh tiến độ, còn lại / vượt.
class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.category, required this.spent, required this.limit, this.onTap});
  final Category? category; // null = tổng chi tiêu
  final int spent, limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = S.of(context);
    final ratio = limit == 0 ? 0.0 : spent / limit;
    final col = budgetColor(c, ratio);
    final left = limit - spent;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            category == null
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: c.primary.op(c.isDark ? 0.2 : 0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.account_balance_wallet_outlined, color: c.primary, size: 21),
                  )
                : CatIcon(category: category),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(category == null ? s.totalBudget : s.catName(category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Text('${(ratio * 100).round()}%',
                          style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: c.segment,
                      valueColor: AlwaysStoppedAnimation(col),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.spentOf(compact(spent), compact(limit)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.muted, fontSize: 12.5)),
                      ),
                      const SizedBox(width: 8),
                      Text(left >= 0 ? s.leftAmount(compact(left)) : s.overAmount(compact(-left)),
                          style: TextStyle(
                              color: left >= 0 ? c.muted : c.expense,
                              fontSize: 12.5,
                              fontWeight: left >= 0 ? FontWeight.w500 : FontWeight.w800)),
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

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final cats = store.catsOf(TxType.expense);
    double ratio(Category x) => store.spentIn(x.id, now) / store.budgets[x.id]!;
    final withB = cats.where((x) => store.budgets.containsKey(x.id)).toList()
      ..sort((a, b) => ratio(b).compareTo(ratio(a)));
    final withoutB = cats.where((x) => !store.budgets.containsKey(x.id)).toList();
    final total = store.budgets[AppStore.totalBudgetKey];

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
                    child: Text(s.budgetTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 46),
              ],
            ),
            const SizedBox(height: 14),
            Text(s.budgetHint, style: TextStyle(color: c.muted, fontSize: 14, height: 1.4)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(s.monthYear(now), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ),
                Text(s.daysLeft(daysLeft), style: TextStyle(color: c.muted)),
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: total == null
                  ? _unsetRow(context, c, s, null, store.spentIn(AppStore.totalBudgetKey, now))
                  : BudgetBar(
                      category: null,
                      spent: store.spentIn(AppStore.totalBudgetKey, now),
                      limit: total,
                      onTap: () => editBudget(context, null),
                    ),
            ),
            if (withB.isNotEmpty) ...[
              _section(c, s.withBudget),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Column(
                  children: [
                    for (var i = 0; i < withB.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.divider),
                      BudgetBar(
                        category: withB[i],
                        spent: store.spentIn(withB[i].id, now),
                        limit: store.budgets[withB[i].id]!,
                        onTap: () => editBudget(context, withB[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (withoutB.isNotEmpty) ...[
              _section(c, s.withoutBudget),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Column(
                  children: [
                    for (var i = 0; i < withoutB.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.divider),
                      _unsetRow(context, c, s, withoutB[i], store.spentIn(withoutB[i].id, now)),
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

  Widget _section(AppColors c, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 0, 10),
        child: Text(t, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800, letterSpacing: .5)),
      );

  Widget _unsetRow(BuildContext context, AppColors c, S s, Category? cat, int spent) => InkWell(
        onTap: () => editBudget(context, cat),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              cat == null
                  ? Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.account_balance_wallet_outlined, color: c.muted, size: 21),
                    )
                  : CatIcon(category: cat),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat == null ? s.totalBudget : s.catName(cat),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('${s.monthExpense}: ${compact(spent)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(s.setBudget, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

/// Bottom sheet nhập hạn mức cho danh mục [cat] (null = tổng chi tiêu).
Future<void> editBudget(BuildContext context, Category? cat) async {
  final store = StoreScope.read(context);
  final s = S.current;
  final c = AppColors.of(context);
  final key = cat?.id ?? AppStore.totalBudgetKey;
  final current = store.budgets[key];
  final ctl = TextEditingController(text: current == null ? '' : groupDigits(current));
  final now = DateTime.now();
  final lastMonth = store.spentIn(key, DateTime(now.year, now.month - 1));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      void save(int? v) {
        store.setBudget(key, v);
        Navigator.pop(ctx);
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.budgetFor(cat == null ? s.totalBudget : s.catName(cat)),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('${s.lastMonth}: ${vnd(lastMonth)}', style: TextStyle(color: c.muted)),
              const SizedBox(height: 14),
              TextField(
                controller: ctl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyFormatter()],
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.text),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'đ',
                  filled: true,
                  fillColor: c.chip,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onSubmitted: (v) => save(int.tryParse(v.replaceAll('.', ''))),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (current != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => save(null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.expense,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: Text(s.removeBudget,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => save(int.tryParse(ctl.text.replaceAll('.', ''))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: Text(s.save, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Cảnh báo nếu danh mục (hoặc tổng) đã dùng từ 80% / vượt hạn mức trong tháng [month]; null nếu không.
({String text, bool over})? budgetWarning(AppStore store, String categoryId, DateTime month) {
  final s = S.current;
  ({String text, bool over})? check(String key, String name) {
    final limit = store.budgets[key];
    if (limit == null) return null;
    final spent = store.spentIn(key, month);
    if (spent > limit) return (text: s.budgetOver(name, compact(spent - limit)), over: true);
    if (spent >= limit * AppStore.budgetWarnAt) {
      return (text: s.budgetWarn(name, (spent / limit * 100).round()), over: false);
    }
    return null;
  }

  return check(categoryId, s.catName(store.cat(categoryId))) ?? check(AppStore.totalBudgetKey, s.totalBudget);
}
