import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 3)
class Income extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  String description;

  @HiveField(4)
  String source; // Ej: "Sueldo", "Freelance", etc.

  Income({
    required this.id,
    required this.amount,
    required this.date,
    this.description = '',
    this.source = 'Sueldo',
  });
}

