import 'package:hive/hive.dart';

part 'payment_record.g.dart';

@HiveType(typeId: 4)
class PaymentRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String fixedExpenseId; // ID del gasto fijo

  @HiveField(2)
  late DateTime month; // Mes al que corresponde el pago

  @HiveField(3)
  late DateTime paidDate; // Fecha en que se pagó

  @HiveField(4)
  late double amount;

  @HiveField(5)
  String? transactionId; // ID de la transacción relacionada (opcional)

  PaymentRecord({
    required this.id,
    required this.fixedExpenseId,
    required this.month,
    required this.paidDate,
    required this.amount,
    this.transactionId,
  });

  // Crea un ID único para el registro de pago
  factory PaymentRecord.create({
    required String fixedExpenseId,
    required DateTime month,
    required DateTime paidDate,
    required double amount,
    String? transactionId,
  }) {
    return PaymentRecord(
      id: '${fixedExpenseId}_${month.year}_${month.month}',
      fixedExpenseId: fixedExpenseId,
      month: DateTime(month.year, month.month, 1),
      paidDate: paidDate,
      amount: amount,
      transactionId: transactionId,
    );
  }
}

