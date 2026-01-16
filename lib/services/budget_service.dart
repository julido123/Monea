import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/payment_record.dart';
import '../models/income.dart';
import '../models/transaction.dart';
import 'storage_service.dart';

class BudgetService {
  static const String _budgetsBox = 'budgets';
  static const String _fixedExpensesBox = 'fixed_expenses';
  static const String _paymentRecordsBox = 'payment_records';
  static const String _incomesBox = 'incomes';

  static Box<Budget>? _budgetsBoxInstance;
  static Box<FixedExpense>? _fixedExpensesBoxInstance;
  static Box<PaymentRecord>? _paymentRecordsBoxInstance;
  static Box<Income>? _incomesBoxInstance;

  // Inicializa los boxes
  static Future<void> init() async {
    _budgetsBoxInstance = await Hive.openBox<Budget>(_budgetsBox);
    _fixedExpensesBoxInstance = await Hive.openBox<FixedExpense>(_fixedExpensesBox);
    _paymentRecordsBoxInstance = await Hive.openBox<PaymentRecord>(_paymentRecordsBox);
    _incomesBoxInstance = await Hive.openBox<Income>(_incomesBox);
    
    // No inicializa presupuestos ni gastos fijos por defecto - el usuario los crea
  }

  // ========== PRESUPUESTOS ==========

  static Box<Budget> get budgetsBox {
    if (_budgetsBoxInstance == null || !_budgetsBoxInstance!.isOpen) {
      throw Exception('BudgetService no inicializado');
    }
    return _budgetsBoxInstance!;
  }

  static Future<void> setBudget(Budget budget) async {
    await budgetsBox.put(budget.id, budget);
  }

  static Future<void> addBudget(Budget budget) async {
    await budgetsBox.put(budget.id, budget);
  }

  static Budget? getBudget(String category, DateTime month) {
    final id = '${category}_${month.year}_${month.month}';
    return budgetsBox.get(id);
  }

  static Budget? getBudgetById(String id) {
    return budgetsBox.get(id);
  }

  static Budget? getCurrentMonthBudget(String category) {
    final now = DateTime.now();
    return getBudget(category, DateTime(now.year, now.month, 1));
  }

  static List<Budget> getAllBudgets() {
    return budgetsBox.values.toList();
  }

  static List<Budget> getBudgetsForMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    return budgetsBox.values
        .where((b) => b.month.year == monthStart.year && b.month.month == monthStart.month)
        .toList();
  }

  static Future<void> deleteBudget(String id) async {
    await budgetsBox.delete(id);
  }

  // Duplica todos los presupuestos de un mes al siguiente mes
  static Future<int> duplicateBudgetsToNextMonth(DateTime sourceMonth) async {
    final sourceBudgets = getBudgetsForMonth(sourceMonth);
    
    if (sourceBudgets.isEmpty) {
      return 0;
    }

    // Calcular el siguiente mes
    final nextMonth = DateTime(sourceMonth.year, sourceMonth.month + 1, 1);
    
    int duplicatedCount = 0;
    
    for (var budget in sourceBudgets) {
      // Verificar si ya existe un presupuesto para esa categoría en el siguiente mes
      final existing = getBudget(budget.category, nextMonth);
      if (existing == null) {
        // Crear nuevo presupuesto para el siguiente mes
        final newBudget = Budget.forMonth(
          category: budget.category,
          amount: budget.amount,
          month: nextMonth,
        );
        await setBudget(newBudget);
        duplicatedCount++;
      }
    }
    
    return duplicatedCount;
  }

  // Obtiene el gasto total en una categoría para un mes
  static double getSpentInCategory(String category, DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final transactions = StorageService.getTransactionsByDateRange(monthStart, monthEnd)
        .where((t) {
          if (t.isIncome) return false;
          return t.category == category;
        })
        .toList();

    return transactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  // Obtiene el saldo disponible en una categoría
  static double getAvailableBalance(String category, DateTime month) {
    final budget = getBudget(category, month);
    if (budget == null) return 0.0;

    final spent = getSpentInCategory(category, month);
    return (budget.amount - spent).clamp(0.0, double.infinity);
  }

  // ========== GASTOS FIJOS ==========

  static Box<FixedExpense> get fixedExpensesBox {
    if (_fixedExpensesBoxInstance == null || !_fixedExpensesBoxInstance!.isOpen) {
      throw Exception('BudgetService no inicializado');
    }
    return _fixedExpensesBoxInstance!;
  }

  static Future<void> addFixedExpense(FixedExpense expense) async {
    await fixedExpensesBox.put(expense.id, expense);
  }

  static List<FixedExpense> getAllFixedExpenses() {
    return fixedExpensesBox.values.where((e) => e.isActive).toList();
  }

  static FixedExpense? getFixedExpense(String id) {
    return fixedExpensesBox.get(id);
  }

  static Future<void> updateFixedExpense(FixedExpense expense) async {
    await expense.save();
  }

  static Future<void> deleteFixedExpense(String id) async {
    await fixedExpensesBox.delete(id);
  }

  // Obtiene los gastos fijos pendientes para el mes actual
  static List<FixedExpense> getPendingFixedExpenses(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final expenses = getAllFixedExpenses();
    final pending = <FixedExpense>[];

    for (var expense in expenses) {
      final isPaid = isFixedExpensePaid(expense.id, monthStart);
      if (!isPaid) {
        pending.add(expense);
      }
    }

    return pending;
  }

  // Obtiene los gastos fijos mensuales automáticos (los que siempre deben aparecer)
  static List<FixedExpense> getMonthlyFixedExpenses() {
    // En la versión genérica, no hay gastos fijos predefinidos
    return [];
  }

  // Obtiene el estado de pago de los gastos fijos mensuales para un mes específico
  static Map<String, bool> getMonthlyFixedExpensesStatus(DateTime month) {
    // En la versión genérica, no hay gastos fijos predefinidos
    return {};
  }

  // Obtiene el total de gastos fijos pendientes para un mes
  static double getTotalPendingFixedExpenses(DateTime month) {
    final pending = getPendingFixedExpenses(month);
    return pending.fold(0.0, (sum, e) => sum + e.amount);
  }

  // ========== REGISTROS DE PAGO ==========

  static Box<PaymentRecord> get paymentRecordsBox {
    if (_paymentRecordsBoxInstance == null || !_paymentRecordsBoxInstance!.isOpen) {
      throw Exception('BudgetService no inicializado');
    }
    return _paymentRecordsBoxInstance!;
  }

  static Future<void> recordPayment(PaymentRecord record) async {
    await paymentRecordsBox.put(record.id, record);
  }

  static bool isFixedExpensePaid(String fixedExpenseId, DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final id = '${fixedExpenseId}_${monthStart.year}_${monthStart.month}';
    return paymentRecordsBox.containsKey(id);
  }

  static PaymentRecord? getPaymentRecord(String fixedExpenseId, DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final id = '${fixedExpenseId}_${monthStart.year}_${monthStart.month}';
    return paymentRecordsBox.get(id);
  }

  static List<PaymentRecord> getPaymentRecordsForMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    return paymentRecordsBox.values
        .where((r) => r.month.year == monthStart.year && r.month.month == monthStart.month)
        .toList();
  }

  static Future<void> deletePaymentRecord(String id) async {
    await paymentRecordsBox.delete(id);
  }

  static List<PaymentRecord> getAllPaymentRecords() {
    return paymentRecordsBox.values.toList();
  }

  // ========== INGRESOS ==========

  static Box<Income> get incomesBox {
    if (_incomesBoxInstance == null || !_incomesBoxInstance!.isOpen) {
      throw Exception('BudgetService no inicializado');
    }
    return _incomesBoxInstance!;
  }

  static Future<void> addIncome(Income income) async {
    await incomesBox.put(income.id, income);
  }

  static List<Income> getAllIncomes() {
    return incomesBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static Income? getIncome(String id) {
    return incomesBox.get(id);
  }

  static Future<void> updateIncome(Income income) async {
    await income.save();
  }

  static Future<void> deleteIncome(String id) async {
    await incomesBox.delete(id);
  }

  // Obtiene ingresos del mes actual
  static List<Income> getCurrentMonthIncomes() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return incomesBox.values
        .where((i) => i.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            i.date.isBefore(monthEnd.add(const Duration(days: 1))))
        .toList();
  }

  // Calcula el total de ingresos del mes
  static double getTotalIncomeForMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final incomes = incomesBox.values
        .where((i) => i.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            i.date.isBefore(monthEnd.add(const Duration(days: 1))))
        .toList();

    return incomes.fold(0.0, (sum, i) => sum + i.amount);
  }

  // ========== CÁLCULOS DE BALANCE ==========

  // Calcula el balance disponible después de compromisos
  static double getAvailableBalanceAfterCommitments(DateTime month) {
    final totalIncome = getTotalIncomeForMonth(month);
    final totalPendingFixed = getTotalPendingFixedExpenses(month);
    final totalSpent = StorageService.getTotalAmount(
      StorageService.getTransactionsByDateRange(
        DateTime(month.year, month.month, 1),
        DateTime(month.year, month.month + 1, 0, 23, 59, 59),
      ).where((t) => !t.isIncome).toList(),
    );

    return totalIncome - totalPendingFixed - totalSpent;
  }

  // Obtiene el total comprometido (gastos fijos pendientes + gastos ya realizados)
  static double getTotalCommitted(DateTime month) {
    final totalPendingFixed = getTotalPendingFixedExpenses(month);
    final totalSpent = StorageService.getTotalAmount(
      StorageService.getTransactionsByDateRange(
        DateTime(month.year, month.month, 1),
        DateTime(month.year, month.month + 1, 0, 23, 59, 59),
      ).where((t) => !t.isIncome).toList(),
    );

    return totalPendingFixed + totalSpent;
  }

  // Verifica si una transacción coincide con algún gasto fijo y lo marca como pagado
  static Future<void> checkAndMarkFixedExpenseAsPaid(Transaction transaction) async {
    if (transaction.isIncome) return;

    final fixedExpenses = getAllFixedExpenses();
    
    for (var expense in fixedExpenses) {
      // Verificar si la transacción coincide con el gasto fijo
      final matchesCategory = transaction.category == expense.category;
      final matchesAmount = (transaction.amount - expense.amount).abs() < 1.0; // Tolerancia de 1 peso
      final matchesMonth = transaction.date.year == DateTime.now().year &&
                          transaction.date.month == DateTime.now().month;

      if (matchesCategory && matchesAmount && matchesMonth) {
        // Verificar si ya está pagado
        final monthStart = DateTime(transaction.date.year, transaction.date.month, 1);
        if (!isFixedExpensePaid(expense.id, monthStart)) {
          // Crear registro de pago
          final record = PaymentRecord.create(
            fixedExpenseId: expense.id,
            month: monthStart,
            paidDate: transaction.date,
            amount: transaction.amount,
            transactionId: transaction.id,
          );
          await recordPayment(record);
        }
      }
    }
  }
}
