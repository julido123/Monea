import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/income.dart';
import '../models/payment_record.dart';
import 'storage_service.dart';
import 'budget_service.dart';

class BackupService {
  // Exporta todos los datos a un archivo JSON
  static Future<String> exportData() async {
    try {
      // Obtener todos los datos
      final transactions = StorageService.getAllTransactions();
      final budgets = BudgetService.getAllBudgets();
      final fixedExpenses = BudgetService.getAllFixedExpenses();
      final incomes = BudgetService.getAllIncomes();
      final paymentRecords = BudgetService.getAllPaymentRecords();

      // Convertir a JSON
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => _transactionToJson(t)).toList(),
        'budgets': budgets.map((b) => _budgetToJson(b)).toList(),
        'fixedExpenses': fixedExpenses.map((f) => _fixedExpenseToJson(f)).toList(),
        'incomes': incomes.map((i) => _incomeToJson(i)).toList(),
        'paymentRecords': paymentRecords.map((p) => _paymentRecordToJson(p)).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Guardar en un archivo temporal
      final directory = await getTemporaryDirectory();
      final fileName = 'monea_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Error al exportar datos: $e');
    }
  }

  // Comparte el archivo de backup
  static Future<void> shareBackup() async {
    try {
      final filePath = await exportData();
      final file = File(filePath);
      
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Backup de Monea - ${DateTime.now().toString().split(' ')[0]}',
        );
      }
    } catch (e) {
      throw Exception('Error al compartir backup: $e');
    }
  }

  // Importa datos desde un archivo JSON
  static Future<ImportResult> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('El archivo no existe');
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      int transactionsImported = 0;
      int budgetsImported = 0;
      int fixedExpensesImported = 0;
      int incomesImported = 0;
      int paymentRecordsImported = 0;

      // Importar transacciones
      if (jsonData.containsKey('transactions')) {
        final transactions = (jsonData['transactions'] as List)
            .map((t) => _transactionFromJson(t))
            .toList();
        
        for (var transaction in transactions) {
          // Verificar si ya existe
          final existing = StorageService.getTransaction(transaction.id);
          if (existing == null) {
            await StorageService.addTransaction(transaction);
            transactionsImported++;
          }
        }
      }

      // Importar presupuestos
      if (jsonData.containsKey('budgets')) {
        final budgets = (jsonData['budgets'] as List)
            .map((b) => _budgetFromJson(b))
            .toList();
        
        for (var budget in budgets) {
          // Verificar si ya existe
          final existing = BudgetService.budgetsBox.get(budget.id);
          if (existing == null) {
            await BudgetService.addBudget(budget);
            budgetsImported++;
          }
        }
      }

      // Importar gastos fijos
      if (jsonData.containsKey('fixedExpenses')) {
        final fixedExpenses = (jsonData['fixedExpenses'] as List)
            .map((f) => _fixedExpenseFromJson(f))
            .toList();
        
        for (var expense in fixedExpenses) {
          // Verificar si ya existe
          final existing = BudgetService.getFixedExpense(expense.id);
          if (existing == null) {
            await BudgetService.addFixedExpense(expense);
            fixedExpensesImported++;
          }
        }
      }

      // Importar ingresos
      if (jsonData.containsKey('incomes')) {
        final incomes = (jsonData['incomes'] as List)
            .map((i) => _incomeFromJson(i))
            .toList();
        
        for (var income in incomes) {
          // Verificar si ya existe
          final existing = BudgetService.getIncome(income.id);
          if (existing == null) {
            await BudgetService.addIncome(income);
            incomesImported++;
          }
        }
      }

      // Importar registros de pago
      if (jsonData.containsKey('paymentRecords')) {
        final paymentRecords = (jsonData['paymentRecords'] as List)
            .map((p) => _paymentRecordFromJson(p))
            .toList();
        
        for (var record in paymentRecords) {
          // Verificar si ya existe
          final existing = BudgetService.getPaymentRecord(record.fixedExpenseId, record.month);
          if (existing == null) {
            await BudgetService.recordPayment(record);
            paymentRecordsImported++;
          }
        }
      }

      return ImportResult(
        transactionsImported: transactionsImported,
        budgetsImported: budgetsImported,
        fixedExpensesImported: fixedExpensesImported,
        incomesImported: incomesImported,
        paymentRecordsImported: paymentRecordsImported,
      );
    } catch (e) {
      throw Exception('Error al importar datos: $e');
    }
  }

  // Selecciona un archivo para importar
  static Future<String?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      throw Exception('Error al seleccionar archivo: $e');
    }
  }

  // Conversión a JSON
  static Map<String, dynamic> _transactionToJson(Transaction t) {
    return {
      'id': t.id,
      'amount': t.amount,
      'date': t.date.toIso8601String(),
      'description': t.description,
      'category': t.category,
      'tag': t.tag,
      'isFromSms': t.isFromSms,
      'originalSms': t.originalSms,
      'isIncome': t.isIncome,
    };
  }

  static Transaction _transactionFromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Sin categoría',
      tag: json['tag'] as String?,
      isFromSms: json['isFromSms'] as bool? ?? false,
      originalSms: json['originalSms'] as String?,
      isIncome: json['isIncome'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _budgetToJson(Budget b) {
    return {
      'id': b.id,
      'category': b.category,
      'amount': b.amount,
      'month': b.month.toIso8601String(),
    };
  }

  static Budget _budgetFromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      month: DateTime.parse(json['month'] as String),
    );
  }

  static Map<String, dynamic> _fixedExpenseToJson(FixedExpense f) {
    return {
      'id': f.id,
      'name': f.name,
      'amount': f.amount,
      'dayOfMonth': f.dayOfMonth,
      'category': f.category,
      'description': f.description,
    };
  }

  static FixedExpense _fixedExpenseFromJson(Map<String, dynamic> json) {
    return FixedExpense(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dayOfMonth: json['dayOfMonth'] as int,
      category: json['category'] as String,
      description: json['description'] as String?,
    );
  }

  static Map<String, dynamic> _incomeToJson(Income i) {
    return {
      'id': i.id,
      'amount': i.amount,
      'date': i.date.toIso8601String(),
      'source': i.source,
      'description': i.description,
    };
  }

  static Income _incomeFromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      source: json['source'] as String,
      description: (json['description'] as String?) ?? '',
    );
  }

  static Map<String, dynamic> _paymentRecordToJson(PaymentRecord p) {
    return {
      'id': p.id,
      'fixedExpenseId': p.fixedExpenseId,
      'month': p.month.toIso8601String(),
      'paidDate': p.paidDate.toIso8601String(),
      'amount': p.amount,
      'transactionId': p.transactionId,
    };
  }

  static PaymentRecord _paymentRecordFromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      fixedExpenseId: json['fixedExpenseId'] as String,
      month: DateTime.parse(json['month'] as String),
      paidDate: DateTime.parse(json['paidDate'] as String),
      amount: (json['amount'] as num).toDouble(),
      transactionId: json['transactionId'] as String?,
    );
  }
}

class ImportResult {
  final int transactionsImported;
  final int budgetsImported;
  final int fixedExpensesImported;
  final int incomesImported;
  final int paymentRecordsImported;

  ImportResult({
    required this.transactionsImported,
    required this.budgetsImported,
    required this.fixedExpensesImported,
    required this.incomesImported,
    required this.paymentRecordsImported,
  });

  int get totalImported =>
      transactionsImported +
      budgetsImported +
      fixedExpensesImported +
      incomesImported +
      paymentRecordsImported;
}

