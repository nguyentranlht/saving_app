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

/// Ký hiệu tiền tệ hay gặp trong số tiền Phím tắt gửi sang.
const _currency = r'(?:₫|đ|vnđ|vnd|\$|€|£|usd|eur)';
const _number = r'\d[\d.,]*';
// Ngày / giờ ("16/10/2026", "12:45") để bỏ đi trước khi tìm số tiền.
final _dateTime = RegExp(r'\d{1,4}[/:-]\d{1,2}(?:[/:-]\d{1,4})?');
final _money = RegExp('$_currency\\s*($_number)|($_number)\\s*$_currency', caseSensitive: false);

/// Đọc số tiền do Phím tắt gửi sang: "₫125.000", "125,000 ₫", "125000", "$12.50"...
/// Cũng đọc được cả đoạn văn bản của giao dịch (khi "Đầu vào phím tắt" chỉ đưa được dạng Văn bản):
/// bỏ ngày giờ, ưu tiên số đi kèm ký hiệu tiền tệ, không có thì lấy số đầu tiên.
/// Dấu . và , được coi là ngăn cách hàng nghìn, trừ khi chỉ có 1–2 chữ số phía sau
/// (phần thập phân, sẽ được làm tròn). Trả về 0 nếu không đọc được.
int parseAmount(String raw) {
  final text = raw.replaceAll(_dateTime, ' ');
  final m = _money.firstMatch(text);
  var t = m != null ? (m.group(1) ?? m.group(2))! : (RegExp(_number).firstMatch(text)?.group(0) ?? '');
  t = t.replaceAll(RegExp(r'[.,]+$'), '');
  final dec = RegExp(r'^(.*)[.,](\d{1,2})$').firstMatch(t);
  if (dec != null) {
    final whole = int.tryParse(dec.group(1)!.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    final frac = int.parse(dec.group(2)!.padRight(2, '0'));
    return whole + (frac >= 50 ? 1 : 0);
  }
  return int.tryParse(t.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
}

/// Đoán nơi thanh toán từ đoạn văn bản của giao dịch: dòng đầu tiên có chữ,
/// sau khi bỏ số tiền và ngày giờ. Số tiền gửi riêng (vd. "₫65.000") thì trả về ''.
String merchantFromText(String raw) {
  for (final line in raw.split(RegExp(r'[\n\r]+'))) {
    final rest = line
        .replaceAll(_money, ' ')
        .replaceAll(_dateTime, ' ')
        .replaceAll(RegExp(r'^[\s\-–·•:,]+|[\s\-–·•:,]+$'), '')
        .trim();
    if (RegExp(r'[^\d\s.,₫$€£]').hasMatch(rest) && !RegExp('^$_currency\$', caseSensitive: false).hasMatch(rest)) {
      return rest;
    }
  }
  return '';
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

/// Các phép tính của máy tính số tiền (ký hiệu hiển thị).
const calcOps = ['+', '−', '×', '÷'];

/// Tính biểu thức số tiền, ví dụ "45000+30000×2" -> 105000 (× ÷ trước, + − sau),
/// làm tròn tới đồng. Bỏ qua phép tính thừa ở cuối ("45000+" -> 45000).
/// Trả về null nếu rỗng hoặc chia cho 0.
int? evalAmount(String expr) {
  final nums = <double>[];
  final ops = <String>[];
  var cur = '';
  for (final ch in expr.split('')) {
    if (calcOps.contains(ch)) {
      if (cur.isEmpty) continue; // phép tính đứng đầu / liền nhau: bỏ qua
      nums.add(double.parse(cur));
      ops.add(ch);
      cur = '';
    } else if (RegExp(r'\d').hasMatch(ch)) {
      cur += ch;
    }
  }
  if (cur.isNotEmpty) {
    nums.add(double.parse(cur));
  } else if (ops.isNotEmpty) {
    ops.removeLast();
  }
  if (nums.isEmpty) return null;

  // Lượt 1: × ÷
  final n2 = <double>[nums.first];
  final o2 = <String>[];
  for (var i = 0; i < ops.length; i++) {
    final b = nums[i + 1];
    if (ops[i] == '×') {
      n2.last *= b;
    } else if (ops[i] == '÷') {
      if (b == 0) return null;
      n2.last /= b;
    } else {
      n2.add(b);
      o2.add(ops[i]);
    }
  }
  // Lượt 2: + −
  var r = n2.first;
  for (var i = 0; i < o2.length; i++) {
    r = o2[i] == '+' ? r + n2[i + 1] : r - n2[i + 1];
  }
  return r.round();
}
