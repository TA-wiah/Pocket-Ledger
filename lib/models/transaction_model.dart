import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 1)
enum TransactionStatus {
  @HiveField(0)
  completed,
  @HiveField(1)
  pending,
  @HiveField(2)
  cancelled,
}

@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  double amount;

  @HiveField(4)
  TransactionType type;

  @HiveField(5)
  String category;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String notes;

  @HiveField(8)
  TransactionStatus status;

  @HiveField(9)
  String? personId;

  TransactionModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes = '',
    this.status = TransactionStatus.completed,
    this.personId,
  });

  TransactionModel copyWith({
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? notes,
    TransactionStatus? status,
    String? personId,
    bool clearPersonId = false,
  }) {
    return TransactionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      personId: clearPersonId ? null : (personId ?? this.personId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date.toIso8601String(),
        'notes': notes,
        'status': status.name,
        'personId': personId,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.byName(json['type'] as String),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String? ?? '',
      status: TransactionStatus.values.byName(
        json['status'] as String? ?? 'completed',
      ),
      personId: json['personId'] as String?,
    );
  }
}
