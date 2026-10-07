import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../screens/detail.dart';
import '../store.dart';
import '../theme.dart';

const Map<String, IconData> kIcons = {
  'food': Icons.restaurant,
  'move': Icons.directions_bus_filled_outlined,
  'coffee': Icons.local_cafe_outlined,
  'work': Icons.work_outline,
  'health': Icons.favorite_border,
  'more': Icons.more_horiz,
  'debt': Icons.swap_horiz,
  'wallet': Icons.account_balance_wallet_outlined,
  'shop': Icons.shopping_bag_outlined,
  'home': Icons.home_outlined,
  'gift': Icons.card_giftcard,
  'book': Icons.menu_book_outlined,
  'movie': Icons.movie_outlined,
  'pet': Icons.pets,
  'phone': Icons.phone_iphone,
  'trend': Icons.trending_up,
};

const List<int> kPalette = [
  0xFFF59E0B, 0xFF8B5CF6, 0xFFB45309, 0xFF3B82F6, 0xFFEF5350, 0xFF9097A8,
  0xFF16A06A, 0xFF0EA5E9, 0xFFEC4899, 0xFF14B8A6,
];

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 24});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

/// Ô icon bo tròn có nền nhạt theo màu danh mục.
class CatIcon extends StatelessWidget {
  const CatIcon({super.key, required this.category, this.size = 44});
  final Category? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final col = Color(category?.color ?? 0xFF9097A8);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: col.op(c.isDark ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(kIcons[category?.icon] ?? Icons.more_horiz, color: col, size: size * 0.46),
    );
  }
}

/// Thanh chuyển Chi / Thu (hoặc Tuần / Tháng).
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.activeColors,
    this.height = 40,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<Color>? activeColors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: height + 8,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.segment, borderRadius: BorderRadius.circular(height)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: i == index ? (c.isDark ? const Color(0xFF2F3F3A) : Colors.white) : Colors.transparent,
                    borderRadius: BorderRadius.circular(height),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: i == index ? (activeColors?[i] ?? c.text) : c.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CircleBtn extends StatelessWidget {
  const CircleBtn({super.key, required this.icon, required this.onTap, this.bg, this.fg});
  final IconData icon;
  final VoidCallback onTap;
  final Color? bg, fg;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: bg ?? c.card, shape: BoxShape.circle),
        child: Icon(icon, color: fg ?? c.text, size: 22),
      ),
    );
  }
}

/// Một dòng giao dịch (dùng ở Tổng quan và Lịch sử).
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx});
  final Tx tx;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final cat = store.cat(tx.categoryId);
    final sub = '${hm(tx.date)} · ${tx.type == TxType.expense ? 'Khoản chi' : 'Khoản thu'}';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(txId: tx.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CatIcon(category: cat),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat?.name ?? 'Đã xóa',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(tx.note.isEmpty ? sub : '$sub · ${tx.note}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: 12.5)),
                ],
              ),
            ),
            Text(
              vnd(tx.signed, sign: true),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: tx.type == TxType.expense ? c.expense : c.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Biểu đồ vành khuyên.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.slices, required this.centerTop, required this.centerBottom, this.size = 180});
  final List<MapEntry<Color, int>> slices;
  final String centerTop, centerBottom;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(size), painter: _DonutPainter(slices, c.segment)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerTop, style: TextStyle(color: c.muted, fontSize: 13)),
              Text(centerBottom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.empty);
  final List<MapEntry<Color, int>> slices;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 28.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final total = slices.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) {
      p.color = empty;
      canvas.drawArc(rect, 0, math.pi * 2, false, p);
      return;
    }
    final gap = slices.length > 1 ? 0.03 : 0.0;
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.value / total * math.pi * 2;
      p.color = s.key;
      canvas.drawArc(rect, start + gap / 2, math.max(0.001, sweep - gap), false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.slices != slices || old.empty != empty;
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(text, style: TextStyle(color: AppColors.of(context).muted)),
        ),
      );
}
