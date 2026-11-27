import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../screens/detail.dart';
import '../store.dart';
import '../theme.dart';

/// Icon danh mục theo nhóm (tên nhóm: S.iconGroup). Key icon đã lưu trong dữ liệu, không được đổi tên.
const Map<String, Map<String, IconData>> kIconGroups = {
  'food': {
    'food': Icons.restaurant,
    'coffee': Icons.local_cafe_outlined,
    'fastfood': Icons.fastfood_outlined,
    'ramen': Icons.ramen_dining_outlined,
    'bakery': Icons.bakery_dining_outlined,
    'icecream': Icons.icecream_outlined,
    'bar': Icons.local_bar_outlined,
    'grocery': Icons.local_grocery_store_outlined,
    'cake': Icons.cake_outlined,
  },
  'transport': {
    'move': Icons.directions_bus_filled_outlined,
    'car': Icons.directions_car_outlined,
    'bike': Icons.two_wheeler,
    'fuel': Icons.local_gas_station_outlined,
    'taxi': Icons.local_taxi_outlined,
    'flight': Icons.flight_outlined,
    'train': Icons.train_outlined,
    'parking': Icons.local_parking,
  },
  'home': {
    'home': Icons.home_outlined,
    'electric': Icons.bolt,
    'water': Icons.water_drop_outlined,
    'wifi': Icons.wifi,
    'phone': Icons.phone_iphone,
    'rent': Icons.key_outlined,
    'repair': Icons.build_outlined,
    'laundry': Icons.local_laundry_service_outlined,
    'cleaning': Icons.cleaning_services_outlined,
  },
  'shopping': {
    'shop': Icons.shopping_bag_outlined,
    'cart': Icons.shopping_cart_outlined,
    'clothes': Icons.checkroom,
    'beauty': Icons.face_retouching_natural,
    'devices': Icons.devices_other_outlined,
    'furniture': Icons.chair_outlined,
    'gift': Icons.card_giftcard,
  },
  'fun': {
    'movie': Icons.movie_outlined,
    'game': Icons.sports_esports_outlined,
    'music': Icons.music_note_outlined,
    'travel': Icons.luggage_outlined,
    'sport': Icons.fitness_center,
    'beach': Icons.beach_access_outlined,
    'camera': Icons.photo_camera_outlined,
    'party': Icons.celebration_outlined,
  },
  'health': {
    'health': Icons.favorite_border,
    'medicine': Icons.medication_outlined,
    'hospital': Icons.local_hospital_outlined,
    'spa': Icons.spa_outlined,
    'baby': Icons.child_friendly_outlined,
    'family': Icons.family_restroom,
    'pet': Icons.pets,
    'school': Icons.school_outlined,
    'book': Icons.menu_book_outlined,
  },
  'finance': {
    'wallet': Icons.account_balance_wallet_outlined,
    'work': Icons.work_outline,
    'salary': Icons.payments_outlined,
    'trend': Icons.trending_up,
    'invest': Icons.show_chart,
    'bank': Icons.account_balance_outlined,
    'savings': Icons.savings_outlined,
    'card': Icons.credit_card,
    'debt': Icons.swap_horiz,
    'bonus': Icons.redeem,
    'tax': Icons.receipt_long_outlined,
    'insurance': Icons.shield_outlined,
    'charity': Icons.volunteer_activism_outlined,
    'more': Icons.more_horiz,
  },
};

final Map<String, IconData> kIcons = {
  for (final g in kIconGroups.values) ...g,
};

const List<int> kPalette = [
  0xFFF59E0B, 0xFFF97316, 0xFFEF5350, 0xFFE11D48, 0xFFEC4899, 0xFF8B5CF6,
  0xFF6366F1, 0xFF3B82F6, 0xFF0EA5E9, 0xFF14B8A6, 0xFF16A06A, 0xFF84CC16,
  0xFFB45309, 0xFF9097A8,
];

/// Tự thêm dấu chấm ngăn cách hàng nghìn khi gõ.
class MoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = groupDigits(int.parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Ô nhập tiền đang dùng bàn phím riêng của app (null = không ô nào).
class _KeypadTarget {
  _KeypadTarget(this.controller, this.focusNode, this.onChanged);
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
}

final _activeKeypad = ValueNotifier<_KeypadTarget?>(null);

/// Bọc quanh ô nhập tiền (TextField có `keyboardType: TextInputType.none` để không bật bàn phím
/// của hệ thống): khi ô được chọn thì hiện bàn phím số riêng của app ([MoneyKeypadHost]).
class MoneyKeypadField extends StatefulWidget {
  const MoneyKeypadField(
      {super.key, required this.controller, required this.focusNode, required this.child, this.onChanged});
  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget child;

  /// Gọi sau mỗi lần bấm phím (đổi chữ bằng code thì TextField không tự gọi onChanged).
  final ValueChanged<String>? onChanged;

  @override
  State<MoneyKeypadField> createState() => _MoneyKeypadFieldState();
}

class _MoneyKeypadFieldState extends State<MoneyKeypadField> {
  late final _target = _KeypadTarget(widget.controller, widget.focusNode, widget.onChanged);

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_sync);
    if (widget.focusNode.hasFocus) _sync();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_sync);
    _release();
    super.dispose();
  }

  void _sync() {
    if (widget.focusNode.hasFocus) {
      _activeKeypad.value = _target;
    } else {
      _release();
    }
  }

  // Đổi sau khung hình hiện tại: có thể đang trong lúc dựng / gỡ cây widget.
  void _release() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_activeKeypad.value == _target) _activeKeypad.value = null;
      });

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Đặt bàn phím số riêng ở đáy app (trong MaterialApp.builder). Khi bàn phím hiện, phần app phía trên
/// được thu lại như khi có bàn phím hệ thống, nên ô nhập và các bảng trượt lên không bị che.
class MoneyKeypadHost extends StatelessWidget {
  const MoneyKeypadHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_KeypadTarget?>(
      valueListenable: _activeKeypad,
      child: child,
      builder: (context, target, child) => Column(
        children: [
          Expanded(
            // Đáy màn hình (thanh home) đã do bàn phím lo.
            child: target == null ? child! : MediaQuery.removePadding(context: context, removeBottom: true, child: child!),
          ),
          if (target != null) _MoneyKeypad(target: target),
        ],
      ),
    );
  }
}

class _MoneyKeypad extends StatelessWidget {
  const _MoneyKeypad({required this.target});
  final _KeypadTarget target;

  void _set(String digits) {
    final text = digits.isEmpty ? '' : groupDigits(int.parse(digits));
    target.controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    target.onChanged?.call(text);
  }

  void _press(String key) {
    HapticFeedback.selectionClick();
    var digits = target.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (key == '⌫') {
      if (digits.isNotEmpty) digits = digits.substring(0, digits.length - 1);
    } else {
      if (digits.isEmpty && key.startsWith('0')) return; // không bắt đầu bằng số 0
      digits += key;
      if (digits.length > 12) return; // tối đa 999 tỷ
    }
    _set(digits);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget key(String label, {bool special = false}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: special ? c.chip : c.card,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _press(label),
                onLongPress: label == '⌫' ? () => _set('') : null, // giữ phím xoá: xoá hết
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: label == '⌫'
                        ? Icon(Icons.backspace_outlined, color: c.text, size: 22)
                        : Text(label, style: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ),
        );

    return TextFieldTapRegion(
      child: Material(
        color: c.bg,
        child: SafeArea(
          top: false,
          child: MediaQuery.withNoTextScaling(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(children: [for (final k in row) key(k)]),
                  Row(children: [key('000', special: true), key('0'), key('⌫', special: true)]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: target.focusNode.unfocus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(S.current.done, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: i == index ? (c.isDark ? const Color(0xFF2F3F3A) : Colors.white) : Colors.transparent,
                    borderRadius: BorderRadius.circular(height),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: i == index ? (activeColors?[i] ?? c.text) : c.muted,
                      ),
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
    final s = S.of(context);
    final cat = store.cat(tx.categoryId);
    final sub = '${hm(tx.date)} · ${tx.type == TxType.expense ? s.expense : s.income}'
        '${tx.recurringId == null ? '' : ' · ${s.recurringBadge}'}';
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
                  Text(s.catName(cat),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(tx.note.isEmpty ? sub : '${hm(tx.date)} · ${tx.note}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  vnd(tx.signed, sign: true),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: tx.type == TxType.expense ? c.expense : c.income,
                  ),
                ),
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
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size - 70),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(centerBottom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26)),
                ),
              ),
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
