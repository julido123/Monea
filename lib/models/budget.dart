import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String category;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late DateTime month; // Mes al que aplica el presupuesto

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
  });

  // Crea un presupuesto para el mes actual
  factory Budget.forCurrentMonth({
    required String category,
    required double amount,
  }) {
    final now = DateTime.now();
    return Budget(
      id: '${category}_${now.year}_${now.month}',
      category: category,
      amount: amount,
      month: DateTime(now.year, now.month, 1),
    );
  }

  // Crea un presupuesto para un mes específico
  factory Budget.forMonth({
    required String category,
    required double amount,
    required DateTime month,
  }) {
    return Budget(
      id: '${category}_${month.year}_${month.month}',
      category: category,
      amount: amount,
      month: DateTime(month.year, month.month, 1),
    );
  }
}

