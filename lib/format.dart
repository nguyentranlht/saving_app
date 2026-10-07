/// 1234567 -> "1.234.567"
String groupDigits(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// -91000 -> "−91.000đ"; sign=true thêm dấu + cho số dương.
String vnd(int n, {bool sign = false}) {
  final p = n < 0 ? '−' : (sign && n > 0 ? '+' : '');
  return '$p${groupDigits(n)}đ';
}

/// 75401405 -> "75,4tr", 125000 -> "125k"
String compact(int n) {
  final a = n.abs();
  if (a >= 1000000) {
    var s = (a / 1e6).toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return '${s.replaceAll('.', ',')}tr';
  }
  if (a >= 1000) return '${(a / 1000).round()}k';
  return '$a';
}

String two(int n) => n.toString().padLeft(2, '0');
String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String dm(DateTime d) => '${d.day} thg ${d.month}';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayLabel(DateTime d, [DateTime? now]) {
  final n = now ?? DateTime.now();
  if (sameDay(d, n)) return 'Hôm nay · ${dm(d)}';
  if (sameDay(d, n.subtract(const Duration(days: 1)))) {
    return 'Hôm qua · ${dm(d)}';
  }
  return d.year == n.year ? dm(d) : '${dm(d)}, ${d.year}';
}

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return 'Chào buổi sáng';
  if (h < 14) return 'Chào buổi trưa';
  if (h < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}
