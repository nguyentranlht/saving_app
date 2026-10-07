enum TxType { expense, income }

class Category {
  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  String id;
  String name;
  String icon; // key trong kIcons
  int color; // 0xFFRRGGBB
  TxType type;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'type': type.name,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: j['icon'] as String,
        color: j['color'] as int,
        type: TxType.values.byName(j['type'] as String),
      );
}

class Tx {
  Tx({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    required this.date,
    this.recurringId,
  });

  String id;
  int amount; // luôn dương
  TxType type;
  String categoryId;
  String note;
  DateTime date;
  String? recurringId; // được tạo tự động từ giao dịch định kỳ nào

  int get signed => type == TxType.expense ? -amount : amount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'note': note,
        'date': date.toIso8601String(),
        if (recurringId != null) 'recurringId': recurringId,
      };

  factory Tx.fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'] as String,
        amount: j['amount'] as int,
        type: TxType.values.byName(j['type'] as String),
        categoryId: j['categoryId'] as String,
        note: (j['note'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        recurringId: j['recurringId'] as String?,
      );
}

enum Freq { daily, weekly, monthly, yearly }

/// Giao dịch định kỳ: tự tạo [Tx] tại mỗi lần [occurrence] đến hạn.
class Recurring {
  Recurring({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    required this.freq,
    required this.anchor,
    this.nextIndex = 0,
    this.lastGenerated,
    this.active = true,
  });

  String id;
  int amount;
  TxType type;
  String categoryId;
  String note;
  Freq freq;
  DateTime anchor; // lần đầu tiên; các lần sau tính từ đây
  int nextIndex; // lần kế tiếp chưa tạo
  DateTime? lastGenerated;
  bool active;

  /// Lần thứ [n] (0 = [anchor]). Ngày 31 hằng tháng sẽ rơi vào ngày cuối của tháng ngắn hơn.
  DateTime occurrence(int n) {
    final a = anchor;
    switch (freq) {
      case Freq.daily:
        return DateTime(a.year, a.month, a.day + n, a.hour, a.minute);
      case Freq.weekly:
        return DateTime(a.year, a.month, a.day + 7 * n, a.hour, a.minute);
      case Freq.monthly:
        final last = DateTime(a.year, a.month + n + 1, 0).day;
        return DateTime(a.year, a.month + n, a.day < last ? a.day : last, a.hour, a.minute);
      case Freq.yearly:
        final last = DateTime(a.year + n, a.month + 1, 0).day;
        return DateTime(a.year + n, a.month, a.day < last ? a.day : last, a.hour, a.minute);
    }
  }

  DateTime get next => occurrence(nextIndex);

  /// Chỉ số của lần đầu tiên sau thời điểm [t].
  int firstIndexAfter(DateTime t) {
    var n = 0;
    while (!occurrence(n).isAfter(t)) {
      n++;
    }
    return n;
  }

  Tx makeTx(int n) {
    final d = occurrence(n);
    return Tx(
      id: 'r${id}_${d.millisecondsSinceEpoch}',
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note,
      date: d,
      recurringId: id,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'note': note,
        'freq': freq.name,
        'anchor': anchor.toIso8601String(),
        'nextIndex': nextIndex,
        'lastGenerated': lastGenerated?.toIso8601String(),
        'active': active,
      };

  factory Recurring.fromJson(Map<String, dynamic> j) => Recurring(
        id: j['id'] as String,
        amount: j['amount'] as int,
        type: TxType.values.byName(j['type'] as String),
        categoryId: j['categoryId'] as String,
        note: (j['note'] as String?) ?? '',
        freq: Freq.values.byName(j['freq'] as String),
        anchor: DateTime.parse(j['anchor'] as String),
        nextIndex: (j['nextIndex'] as int?) ?? 0,
        lastGenerated: j['lastGenerated'] == null ? null : DateTime.parse(j['lastGenerated'] as String),
        active: (j['active'] as bool?) ?? true,
      );
}
