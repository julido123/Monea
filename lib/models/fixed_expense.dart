import 'package:hive/hive.dart';

part 'fixed_expense.g.dart';

@HiveType(typeId: 2)
class FixedExpense extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late int dayOfMonth; // Día del mes en que se paga (1-31)

  @HiveField(4)
  late String category;

  @HiveField(5)
  String? description;

  @HiveField(6)
  bool isActive;

  FixedExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    this.category = 'Vivienda',
    this.description,
    this.isActive = true,
  });
}

