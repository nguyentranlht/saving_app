import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Hướng dẫn dùng Phím tắt: menu "Sổ thu chi" và tự ghi khi thanh toán Apple Pay; chọn danh mục mặc định.
class ApplePayScreen extends StatelessWidget {
  const ApplePayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);

    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 0, 10),
          child: Text(t, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800, letterSpacing: .5)),
        );

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
                    child: Text(s.applePayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 46),
              ],
            ),
            // Menu "Sổ thu chi"
            section(s.menuTitle),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _badge(c, Icons.bolt, c.primary),
                      const SizedBox(width: 14),
                      Expanded(child: Text(s.menuIntro, style: const TextStyle(height: 1.45))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final (i, way) in s.menuWays.indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(const [Icons.mic_none, Icons.apps, Icons.radio_button_checked, Icons.tune][i],
                              size: 18, color: c.muted),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(way, style: const TextStyle(height: 1.4))),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Tự ghi khi thanh toán (tự động hóa "Giao dịch" + hành động "Ghi khoản chi")
            section(s.autoLogTitle),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _badge(c, Icons.contactless_outlined, c.text),
                      const SizedBox(width: 14),
                      Expanded(child: Text(s.apIntro, style: const TextStyle(height: 1.45))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(s.apSetupTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  for (final (i, step) in s.apSteps.indexed) ...[
                    if (i > 0) const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                          child: Text('${i + 1}',
                              style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(step, style: const TextStyle(height: 1.45))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            section(s.apCategoryTitle),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.apCategoryHint, style: TextStyle(color: c.muted, height: 1.4)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in store.catsOf(TxType.expense))
                        _chip(c, s, cat, cat.id == store.guessCategory(''), () => store.setAutoCategory(cat.id)),
                    ],
                  ),
                ],
              ),
            ),
            section(s.apNotesTitle),
            AppCard(
              child: Column(
                children: [
                  for (final (i, note) in s.apNotes.indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.info_outline, size: 18, color: c.muted),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(note, style: TextStyle(color: c.muted, height: 1.4))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(AppColors c, IconData icon, Color bg) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: c.card),
      );

  Widget _chip(AppColors c, S s, Category cat, bool sel, VoidCallback onTap) {
    final col = Color(cat.color);
    return GestureDetector(
      onTap: onTap,
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
          ],
        ),
      ),
    );
  }
}
