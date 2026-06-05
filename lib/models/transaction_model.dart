enum TransactionType { income, expense }

class TransactionModel {
  final int? id;
  final String title;
  final double value;
  final DateTime date;
  final TransactionType type;

  TransactionModel({
    this.id,
    required this.title,
    required this.value,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'value': value,
      // O SQLite não possui tipo DateTime nativo, por isso salvamos como String ISO8601
      'date': date.toIso8601String(),
      'type': type == TransactionType.income ? 'income' : 'expense',
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      value: (map['value'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }
}