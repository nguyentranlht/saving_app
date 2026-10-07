import 'l10n.dart';

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
    return '${s.replaceAll('.', S.current.decimalSep)}${S.current.million}';
  }
  if (a >= 1000) return '${(a / 1000).round()}k';
  return '$a';
}

String two(int n) => n.toString().padLeft(2, '0');
String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String dm(DateTime d) => S.current.dayMonth(d);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayLabel(DateTime d, [DateTime? now]) {
  final n = now ?? DateTime.now();
  if (sameDay(d, n)) return '${S.current.today} · ${dm(d)}';
  if (sameDay(d, n.subtract(const Duration(days: 1)))) {
    return '${S.current.yesterday} · ${dm(d)}';
  }
  return d.year == n.year ? dm(d) : '${dm(d)}, ${d.year}';
}

String greeting([DateTime? now]) => S.current.greeting((now ?? DateTime.now()).hour);

const _accents = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậ',
  'e': 'èéẻẽẹêềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọôồốổỗộơờớởỡợ',
  'u': 'ùúủũụưừứửữự',
  'y': 'ỳýỷỹỵ',
  'd': 'đ',
};
final _plain = {
  for (final e in _accents.entries)
    for (final ch in e.value.split('')) ch: e.key,
};

/// Chuẩn hóa để tìm kiếm: chữ thường, bỏ dấu tiếng Việt ("Cà Phê" -> "ca phe").
String searchKey(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final u = ch.codeUnitAt(0);
    if (u >= 0x0300 && u <= 0x036F) continue; // dấu rời (Unicode dạng tổ hợp)
    b.write(_plain[ch] ?? ch);
  }
  return b.toString();
}
