import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../l10n.dart';
import '../theme.dart';

/// Mở máy tính số tiền; trả về kết quả (> 0) khi bấm "Dùng", null nếu đóng.
Future<int?> showAmountCalculator(BuildContext context, {int initial = 0, Color? accent}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _Calculator(initial: initial, accent: accent),
  );
}

class _Calculator extends StatefulWidget {
  const _Calculator({required this.initial, this.accent});
  final int initial;
  final Color? accent;

  @override
  State<_Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<_Calculator> {
  /// Biểu thức thô: chữ số và các phép tính trong [calcOps], ví dụ "45000+30000".
  late String _expr = widget.initial > 0 ? '${widget.initial}' : '';
  String? _error;

  bool get _endsWithOp => _expr.isNotEmpty && calcOps.contains(_expr[_expr.length - 1]);

  /// Chữ số của số đang gõ (sau phép tính cuối).
  String get _lastNumber {
    var i = _expr.length;
    while (i > 0 && !calcOps.contains(_expr[i - 1])) {
      i--;
    }
    return _expr.substring(i);
  }

  void _press(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      switch (k) {
        case 'C':
          _expr = '';
        case '⌫':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        case '=':
          final r = evalAmount(_expr);
          if (r == null) {
            if (_expr.isNotEmpty) _error = S.current.cannotCalc;
          } else {
            _expr = r < 0 ? '' : '$r';
            if (r <= 0) _error = S.current.resultMustBePositive;
          }
        case '000':
          if (_lastNumber.isNotEmpty && _lastNumber.length <= 12) _expr += '000';
        default:
          if (calcOps.contains(k)) {
            if (_expr.isEmpty) return;
            _expr = _endsWithOp ? _expr.substring(0, _expr.length - 1) + k : _expr + k;
          } else if (_lastNumber.length < 15) {
            // Bỏ số 0 vô nghĩa ở đầu: "0" rồi gõ "5" -> "5".
            if (_lastNumber == '0') _expr = _expr.substring(0, _expr.length - 1);
            _expr += k;
          }
      }
    });
  }

  void _use() {
    final r = evalAmount(_expr);
    if (r == null || r <= 0) {
      setState(() => _error = r == null && _expr.isNotEmpty ? S.current.cannotCalc : S.current.resultMustBePositive);
      return;
    }
    Navigator.pop(context, r);
  }

  /// "45000+30000" -> "45.000 + 30.000"
  String get _pretty {
    final b = StringBuffer();
    var cur = '';
    for (final ch in _expr.split('')) {
      if (calcOps.contains(ch)) {
        if (cur.isNotEmpty) b.write(groupDigits(int.parse(cur)));
        b.write(' $ch ');
        cur = '';
      } else {
        cur += ch;
      }
    }
    if (cur.isNotEmpty) b.write(groupDigits(int.parse(cur)));
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = S.of(context);
    final accent = widget.accent ?? c.primary;
    final result = evalAmount(_expr);
    // Chỉ hiện "= …" khi biểu thức có phép tính.
    final showResult = result != null && calcOps.any(_expr.contains);

    Widget key(String k, {Color? bg, Color? fg, int flex = 1, VoidCallback? onTap}) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Material(
              color: bg ?? c.chip,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap ?? () => _press(k),
                child: SizedBox(
                  height: 58,
                  child: Center(
                    child: k == '⌫'
                        ? Icon(Icons.backspace_outlined, color: fg ?? c.text)
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(k,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: fg ?? c.text)),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
    Widget op(String k) => key(k, bg: accent.op(c.isDark ? 0.25 : 0.14), fg: accent);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(s.calculator, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            // Màn hình
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 30,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(_expr.isEmpty ? '0' : _pretty,
                          style: TextStyle(
                              fontSize: showResult ? 20 : 28,
                              fontWeight: FontWeight.w700,
                              color: showResult ? c.muted : c.text)),
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _error ?? (showResult ? '= ${vnd(result)}' : ''),
                        style: TextStyle(
                            fontSize: _error == null ? 30 : 16,
                            fontWeight: FontWeight.w800,
                            color: _error == null ? accent : c.expense),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [key('C', fg: c.expense), key('⌫'), op('÷'), op('×')]),
            Row(children: [key('7'), key('8'), key('9'), op('−')]),
            Row(children: [key('4'), key('5'), key('6'), op('+')]),
            Row(children: [key('1'), key('2'), key('3'), op('=')]),
            Row(children: [
              key('0'),
              key('000'),
              key(s.useResult, bg: accent, fg: Colors.white, flex: 2, onTap: _use),
            ]),
          ],
        ),
      ),
    );
  }
}
