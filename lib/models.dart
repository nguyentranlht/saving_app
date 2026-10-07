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
  });

  String id;
  int amount; // luôn dương
  TxType type;
  String categoryId;
  String note;
  DateTime date;

  int get signed => type == TxType.expense ? -amount : amount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Tx.fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'] as String,
        amount: j['amount'] as int,
        type: TxType.values.byName(j['type'] as String),
        categoryId: j['categoryId'] as String,
        note: (j['note'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
      );
}
