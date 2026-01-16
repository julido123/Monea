import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/income.dart';
import '../models/payment_record.dart';
import '../services/budget_service.dart';
import '../services/storage_service.dart';
import 'income_screen.dart';

class BudgetDashboardScreen extends StatefulWidget {
  const BudgetDashboardScreen({super.key});

  @override
  State<BudgetDashboardScreen> createState() => _BudgetDashboardScreenState();
}

class _BudgetDashboardScreenState extends State<BudgetDashboardScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final totalIncome = BudgetService.getTotalIncomeForMonth(_selectedMonth);
    final totalCommitted = BudgetService.getTotalCommitted(_selectedMonth);
    final availableBalance = BudgetService.getAvailableBalanceAfterCommitments(_selectedMonth);
    final pendingFixed = BudgetService.getPendingFixedExpenses(_selectedMonth);
    final budgets = BudgetService.getBudgetsForMonth(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Presupuesto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Registrar ingreso',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IncomeScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: BudgetService.budgetsBox.listenable(),
        builder: (context, _, __) {
          return ValueListenableBuilder(
            valueListenable: BudgetService.fixedExpensesBox.listenable(),
            builder: (context, _, __) {
              return ValueListenableBuilder(
                valueListenable: BudgetService.incomesBox.listenable(),
                builder: (context, _, __) {
                  return ValueListenableBuilder(
                    valueListenable: StorageService.box.listenable(),
                    builder: (context, _, __) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selector de mes
                            _MonthSelector(
                              selectedMonth: _selectedMonth,
                              onMonthChanged: (month) {
                                setState(() {
                                  _selectedMonth = month;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            // Resumen financiero
                            _FinancialSummaryCard(
                              totalIncome: totalIncome,
                              totalCommitted: totalCommitted,
                              availableBalance: availableBalance,
                            ),
                            const SizedBox(height: 24),

                            // Gastos fijos pendientes
                            if (pendingFixed.isNotEmpty) ...[
                              const Text(
                                'Gastos fijos pendientes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PendingFixedExpensesList(expenses: pendingFixed),
                              const SizedBox(height: 24),
                            ],

                            // Presupuestos y saldos disponibles
                            if (budgets.isNotEmpty) ...[
                              const Text(
                                'Presupuestos disponibles',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _BudgetsList(budgets: budgets, month: _selectedMonth),
                            ],

                            // Ingresos del mes
                            const SizedBox(height: 24),
                            const Text(
                              'Ingresos del mes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _IncomesList(month: _selectedMonth),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
                onMonthChanged(prevMonth);
              },
            ),
            Text(
              DateFormat('MMMM yyyy', 'es').format(selectedMonth),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
                    final now = DateTime.now();
                    if (nextMonth.year <= now.year && 
                        (nextMonth.year < now.year || nextMonth.month <= now.month + 1)) {
                      onMonthChanged(nextMonth);
                    }
                  },
                ),
                // Botón para volver al mes actual
                if (selectedMonth.year != DateTime.now().year || 
                    selectedMonth.month != DateTime.now().month)
                  IconButton(
                    icon: const Icon(Icons.today),
                    tooltip: 'Mes actual',
                    onPressed: () {
                      onMonthChanged(DateTime.now());
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalCommitted;
  final double availableBalance;

  const _FinancialSummaryCard({
    required this.totalIncome,
    required this.totalCommitted,
    required this.availableBalance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen Financiero',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Ingresos totales',
              amount: totalIncome,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Comprometido',
              amount: totalCommitted,
              color: Colors.orange,
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Disponible',
              amount: availableBalance,
              color: availableBalance >= 0 ? Colors.blue : Colors.red,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MonthlyFixedExpensesSection extends StatelessWidget {
  final DateTime month;

  const _MonthlyFixedExpensesSection({required this.month});

  @override
  Widget build(BuildContext context) {
    final monthlyExpenses = BudgetService.getMonthlyFixedExpenses();
    final status = BudgetService.getMonthlyFixedExpensesStatus(month);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (monthlyExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final pendingCount = status.values.where((paid) => !paid).length;
    final totalPending = monthlyExpenses
        .where((e) => !(status[e.id] ?? false))
        .fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Gastos fijos mensuales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (pendingCount > 0)
              Chip(
                label: Text('$pendingCount pendiente${pendingCount > 1 ? 's' : ''}'),
                backgroundColor: Colors.orange.shade100,
                labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ...monthlyExpenses.map((expense) {
                final isPaid = status[expense.id] ?? false;
                final paymentRecord = BudgetService.getPaymentRecord(expense.id, month);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPaid ? Colors.green : Colors.orange,
                    child: Icon(
                      isPaid ? Icons.check : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    expense.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                      color: isPaid ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (expense.amount > 0)
                        Text('Monto: ${currencyFormat.format(expense.amount)}')
                      else
                        const Text(
                          'Monto no configurado',
                          style: TextStyle(color: Colors.orange),
                        ),
                      if (isPaid && paymentRecord != null)
                        Text(
                          'Pagado el: ${DateFormat('dd/MM/yyyy').format(paymentRecord.paidDate)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        )
                      else
                        Text(
                          'Pendiente - Día ${expense.dayOfMonth}',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: expense.amount > 0
                      ? Text(
                          currencyFormat.format(expense.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.grey : Colors.orange,
                            decoration: isPaid ? TextDecoration.lineThrough : null,
                          ),
                        )
                      : const Icon(Icons.warning, color: Colors.orange),
                  onTap: !isPaid && expense.amount > 0
                      ? () => _markAsPaid(context, expense, month)
                      : null,
                );
              }),
              // Total de gastos fijos
              const Divider(),
              ListTile(
                title: const Text(
                  'Total gastos fijos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: Text(
                  currencyFormat.format(monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount)),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.teal,
                  ),
                ),
              ),
              if (totalPending > 0) ...[
                const Divider(),
                ListTile(
                  title: const Text(
                    'Total pendiente',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    currencyFormat.format(totalPending),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _markAsPaid(BuildContext context, FixedExpense expense, DateTime month) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Marcar como pagado: ${expense.name}'),
        content: Text('¿Confirmas que ya pagaste ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(expense.amount)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final now = DateTime.now();
              final monthStart = DateTime(month.year, month.month, 1);
              
              final record = PaymentRecord.create(
                fixedExpenseId: expense.id,
                month: monthStart,
                paidDate: now,
                amount: expense.amount,
              );

              await BudgetService.recordPayment(record);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pago registrado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _PendingFixedExpensesList extends StatelessWidget {
  final List<FixedExpense> expenses;

  const _PendingFixedExpensesList({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Card(
      child: Column(
        children: [
          ...expenses.map((expense) {
            return ListTile(
              leading: const Icon(Icons.pending, color: Colors.orange),
              title: Text(expense.name),
              subtitle: Text('Día ${expense.dayOfMonth} - ${expense.category}'),
              trailing: Text(
                currencyFormat.format(expense.amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
          const Divider(),
          ListTile(
            title: const Text(
              'Total pendiente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              currencyFormat.format(total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetsList extends StatelessWidget {
  final List<Budget> budgets;
  final DateTime month;

  const _BudgetsList({required this.budgets, required this.month});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Column(
      children: budgets.map((budget) {
        final spent = BudgetService.getSpentInCategory(budget.category, month);
        final available = budget.amount - spent;
        final percentage = budget.amount > 0 ? (spent / budget.amount * 100) : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getCategoryColor(budget.category),
                      child: Icon(
                        _getCategoryIcon(budget.category),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Presupuesto: ${currencyFormat.format(budget.amount)}',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gastado: ${currencyFormat.format(spent)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Disponible: ${currencyFormat.format(available)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: available >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: percentage > 100 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (percentage.clamp(0.0, 100.0) / 100),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 100 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      
      
      
      
      
      case 'Suscripciones':
        return Colors.purple;
      
      
      case 'Alimentación':
        return Colors.green;
      case 'Transporte':
        return Colors.blue.shade300;
      case 'Entretenimiento':
        return Colors.purple.shade300;
      case 'Compras':
        return Colors.pink;
      case 'Salud':
        return Colors.red;
      case 'Educación':
        return Colors.orange;
      case 'Vivienda':
        return Colors.brown;
      case 'Servicios':
        return Colors.teal;
      case 'Ahorro':
        return Colors.teal.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      
      
      
      
      
      case 'Suscripciones':
        return Icons.subscriptions;
      
      
      case 'Alimentación':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_car;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Compras':
        return Icons.shopping_bag;
      case 'Salud':
        return Icons.medical_services;
      case 'Educación':
        return Icons.school;
      case 'Vivienda':
        return Icons.home;
      case 'Servicios':
        return Icons.build;
      case 'Ahorro':
        return Icons.savings;
      default:
        return Icons.attach_money;
    }
  }
}

class _IncomesList extends StatelessWidget {
  final DateTime month;

  const _IncomesList({required this.month});

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ValueListenableBuilder(
      valueListenable: BudgetService.incomesBox.listenable(),
      builder: (context, Box<Income> box, _) {
        final incomes = box.values
            .where((i) => i.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                i.date.isBefore(monthEnd.add(const Duration(days: 1))))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (incomes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Text(
                    'No hay ingresos registrados este mes',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        final total = incomes.fold(0.0, (sum, i) => sum + i.amount);

        return Card(
          child: Column(
            children: [
              ...incomes.map((income) {
                return ListTile(
                  leading: const Icon(Icons.arrow_downward, color: Colors.green),
                  title: Text(income.source),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(income.date)}${income.description.isNotEmpty ? ' - ${income.description}' : ''}',
                  ),
                  trailing: Text(
                    currencyFormat.format(income.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                );
              }),
              const Divider(),
              ListTile(
                title: const Text(
                  'Total ingresos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  currencyFormat.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

