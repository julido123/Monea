import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import 'budget_service.dart';

class StorageService {
  static const String _transactionsBox = 'transactions';
  static Box<Transaction>? _box;

  // Inicializa Hive y registra los adaptadores
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Registra el adaptador de Transaction
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    
    // Abre la caja de transacciones
    _box = await Hive.openBox<Transaction>(_transactionsBox);
  }

  // Obtiene la caja de transacciones
  static Box<Transaction> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('Storage no inicializado. Llama a StorageService.init() primero.');
    }
    return _box!;
  }

  // Agrega una nueva transacción
  static Future<void> addTransaction(Transaction transaction) async {
    // Verificar duplicados antes de agregar
    final existingTransactions = getAllTransactions();
    final isDuplicate = existingTransactions.any((existing) {
      if (existing.isFromSms && transaction.isFromSms) {
        return existing.originalSms == transaction.originalSms;
      }
      // Para transacciones manuales, comparar fecha, monto y descripción
      return existing.date.year == transaction.date.year &&
             existing.date.month == transaction.date.month &&
             existing.date.day == transaction.date.day &&
             existing.amount == transaction.amount &&
             existing.description == transaction.description;
    });

    if (!isDuplicate) {
      await box.put(transaction.id, transaction);
      
      // Verifica si la transacción coincide con algún gasto fijo mensual y lo marca como pagado
      try {
        await BudgetService.checkAndMarkFixedExpenseAsPaid(transaction);
      } catch (e) {
        // Si hay error, no afecta la creación de la transacción
        print('Error al verificar gastos fijos: $e');
      }
    } else {
      print('Transacción duplicada detectada, omitiendo: ${transaction.description}');
    }
  }

  // Obtiene todas las transacciones
  static List<Transaction> getAllTransactions() {
    return box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Ordenar por fecha descendente
  }

  // Obtiene una transacción por ID
  static Transaction? getTransaction(String id) {
    return box.get(id);
  }

  // Actualiza una transacción existente
  static Future<void> updateTransaction(Transaction transaction) async {
    await transaction.save();
    
    // Verifica si la transacción actualizada coincide con algún gasto fijo mensual
    try {
      await BudgetService.checkAndMarkFixedExpenseAsPaid(transaction);
    } catch (e) {
      print('Error al verificar gastos fijos: $e');
    }
  }

  // Elimina una transacción
  static Future<void> deleteTransaction(String id) async {
    await box.delete(id);
  }

  // Obtiene transacciones por rango de fechas
  static List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return box.values.where((transaction) {
      // Comparar solo año, mes y día (ignorar hora)
      final transactionDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      
      // Verificar si la fecha está dentro del rango (inclusive)
      final compareStart = transactionDate.compareTo(startDate);
      final compareEnd = transactionDate.compareTo(endDate);
      
      return compareStart >= 0 && compareEnd <= 0;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Obtiene transacciones del mes actual
  static List<Transaction> getCurrentMonthTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  // Obtiene el total de gastos
  static double getTotalAmount(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Obtiene gastos por categoría (sin agrupaciones)
  static Map<String, double> getAmountByCategory(List<Transaction> transactions) {
    final Map<String, double> categoryAmounts = {};
    
    for (var transaction in transactions) {
      final category = transaction.category;
      categoryAmounts[category] = 
          (categoryAmounts[category] ?? 0.0) + transaction.amount;
    }
    
    return categoryAmounts;
  }

  // Obtiene gastos agrupados por día
  static Map<DateTime, double> getAmountByDay(List<Transaction> transactions) {
    final Map<DateTime, double> dailyAmounts = {};
    
    for (var transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyAmounts[date] = (dailyAmounts[date] ?? 0.0) + transaction.amount;
    }
    
    return dailyAmounts;
  }

  // Cierra todas las cajas
  static Future<void> close() async {
    await Hive.close();
  }
}

