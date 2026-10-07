import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  TxType _type = TxType.expense;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final cats = store.catsOf(_type);

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
                    child: Text(s.manageCategories, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
                CircleBtn(
                  icon: Icons.add,
                  bg: c.primary,
                  fg: c.onPrimary,
                  onTap: () => _edit(context, store, null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Segmented(
              labels: [s.expense, s.income],
              index: _type == TxType.expense ? 0 : 1,
              activeColors: [c.expense, c.income],
              height: 46,
              onChanged: (i) => setState(() => _type = i == 0 ? TxType.expense : TxType.income),
            ),
            const SizedBox(height: 14),
            Text(s.categoriesHint,
                style: TextStyle(color: c.muted, fontSize: 15)),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              radius: 28,
              child: Column(
                children: [
                  for (var i = 0; i < cats.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.divider),
                    InkWell(
                      onTap: () => _edit(context, store, cats[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            CatIcon(category: cats[i], size: 52),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.catName(cats[i]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                                  Text(s.txCount(store.countIn(cats[i].id)),
                                      style: TextStyle(color: c.muted, fontSize: 14)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: c.muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _edit(context, store, null),
              child: Container(
                height: 66,
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
                      child: Text(s.addCategory,
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

  /// Bottom sheet thêm / sửa danh mục.
  void _edit(BuildContext context, AppStore store, Category? existing) {
    final s = S.current;
    final nameCtl = TextEditingController(text: existing == null ? '' : s.catName(existing));
    var icon = existing?.icon ?? 'shop';
    var color = existing?.color ?? kPalette.first;
    final type = existing?.type ?? _type;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return StatefulBuilder(builder: (ctx, setS) {
          final canDelete = existing != null &&
              store.countIn(existing.id) == 0 &&
              store.catsOf(type).length > 1;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(existing == null ? s.newCategory : s.editCategory,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtl,
                    decoration: InputDecoration(
                      hintText: s.categoryName,
                      filled: true,
                      fillColor: c.chip,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(s.icon, style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final g in kIconGroups.entries) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              child: Text(s.iconGroup(g.key), style: TextStyle(color: c.muted, fontSize: 12.5)),
                            ),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final e in g.value.entries)
                                  GestureDetector(
                                    onTap: () => setS(() => icon = e.key),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: icon == e.key ? Color(color).op(0.2) : c.chip,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: icon == e.key ? Color(color) : Colors.transparent, width: 2),
                                      ),
                                      child: Icon(e.value, color: icon == e.key ? Color(color) : c.muted),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
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
                      if (canDelete) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              store.deleteCategory(existing.id);
                              Navigator.pop(ctx);
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
                          onPressed: () {
                            final name = nameCtl.text.trim();
                            if (name.isEmpty) return;
                            store.upsertCategory(Category(
                              id: existing?.id ?? 'c${DateTime.now().microsecondsSinceEpoch}',
                              name: name,
                              icon: icon,
                              color: color,
                              type: type,
                            ));
                            Navigator.pop(ctx);
                          },
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
        });
      },
    );
  }
}
