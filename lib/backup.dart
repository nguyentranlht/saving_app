import 'dart:convert';

import 'models.dart';

/// Nội dung một bản sao lưu (file .json do app tự xuất).
class Backup {
  Backup({
    required this.categories,
    required this.txs,
    this.recurrings = const [],
    required this.exportedAt,
    this.theme,
    this.lang,
    this.reminderHour,
    this.reminderMinute,
  });

  static const format = 'so_thu_chi_backup';
  static const version = 2; // 2: thêm giao dịch định kỳ

  final List<Category> categories;
  final List<Tx> txs;
  final List<Recurring> recurrings;
  final DateTime exportedAt;
  final String? theme; // 'light' | 'dark'
  final String? lang; // 'vi' | 'en'
  final int? reminderHour;
  final int? reminderMinute;

  String encode() => const JsonEncoder.withIndent(' ').convert({
        'format': format,
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        'settings': {
          'theme': theme,
          'lang': lang,
          'reminderHour': reminderHour,
          'reminderMinute': reminderMinute,
        },
        'categories': categories.map((e) => e.toJson()).toList(),
        'txs': txs.map((e) => e.toJson()).toList(),
        'recurrings': recurrings.map((e) => e.toJson()).toList(),
      });

  /// Đọc file sao lưu. Ném [FormatException] nếu không phải file của app hoặc bị hỏng.
  static Backup parse(String text) {
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, dynamic> || j['format'] != format) {
        throw const FormatException('not a backup file');
      }
      final v = j['version'];
      if (v is! int || v > version) throw const FormatException('unsupported version');
      final cats = (j['categories'] as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      final txs = (j['txs'] as List).map((e) => Tx.fromJson(e as Map<String, dynamic>)).toList();
      if (!TxType.values.every((t) => cats.any((c) => c.type == t))) {
        throw const FormatException('missing categories');
      }
      final recs = ((j['recurrings'] as List?) ?? const [])
          .map((e) => Recurring.fromJson(e as Map<String, dynamic>))
          .toList();
      final st = (j['settings'] as Map<String, dynamic>?) ?? const {};
      return Backup(
        categories: cats,
        txs: txs,
        recurrings: recs,
        exportedAt: DateTime.parse(j['exportedAt'] as String),
        theme: st['theme'] as String?,
        lang: st['lang'] as String?,
        reminderHour: st['reminderHour'] as int?,
        reminderMinute: st['reminderMinute'] as int?,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      // Sai kiểu dữ liệu, thiếu trường...
      throw FormatException('invalid backup: $e');
    }
  }
}
