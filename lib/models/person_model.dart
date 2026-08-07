import 'package:hive/hive.dart';

part 'person_model.g.dart';

@HiveType(typeId: 5)
class PersonModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String notes;

  @HiveField(3)
  DateTime createdAt;

  PersonModel({
    required this.id,
    required this.name,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
