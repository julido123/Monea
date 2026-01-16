import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/budget_service.dart';
import '../services/storage_service.dart';
import 'budget_config_screen.dart';

class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    
    final budgets = BudgetService.getBudgetsForMonth(_selectedMonth);

    // Calcular totales
    double totalBudgeted = 0.0;
    double totalSpent = 0.0;
    
    final budgetData = <_BudgetItem>[];
    
    for (var budget in budgets) {
      final spent = BudgetService.getSpentInCategory(budget.category, _selectedMonth);
      totalBudgeted += budget.amount;
      totalSpent += spent;
      
      budgetData.add(_BudgetItem(
        category: budget.category,
        budgeted: budget.amount,
        spent: spent,
        remaining: budget.amount - spent,
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto Mensual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar presupuestos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetConfigScreen(),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: BudgetService.budgetsBox.listenable(),
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

                    // Resumen total
                    _TotalSummaryCard(
                      totalBudgeted: totalBudgeted,
                      totalSpent: totalSpent,
                      remaining: totalBudgeted - totalSpent,
                    ),
                    const SizedBox(height: 24),

                    // Lista de presupuestos
                    if (budgetData.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No hay presupuestos configurados',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BudgetConfigScreen(),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              child: const Text('Configurar presupuestos'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...budgetData.map((item) => _BudgetItemCard(item: item)),
                  ],
                ),
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
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', 'es').format(selectedMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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

class _TotalSummaryCard extends StatelessWidget {
  final double totalBudgeted;
  final double totalSpent;
  final double remaining;

  const _TotalSummaryCard({
    required this.totalBudgeted,
    required this.totalSpent,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');
    final percentage = totalBudgeted > 0 ? (totalSpent / totalBudgeted * 100) : 0.0;
    final isOverBudget = totalSpent > totalBudgeted;

    return Card(
      color: isOverBudget ? Colors.red.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Presupuesto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Total Presupuestado',
              amount: totalBudgeted,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Total Ejecutado',
              amount: totalSpent,
              color: isOverBudget ? Colors.red : Colors.orange,
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: isOverBudget ? 'Sobrepasado' : 'Disponible',
              amount: remaining.abs(),
              color: isOverBudget ? Colors.red : Colors.green,
              isBold: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (percentage.clamp(0.0, 100.0) / 100),
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
              ],
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
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

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

class _BudgetItem {
  final String category;
  final double budgeted;
  final double spent;
  final double remaining;

  _BudgetItem({
    required this.category,
    required this.budgeted,
    required this.spent,
    required this.remaining,
  });
}

class _BudgetItemCard extends StatelessWidget {
  final _BudgetItem item;

  const _BudgetItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');
    final percentage = item.budgeted > 0 ? (item.spent / item.budgeted * 100) : 0.0;
    final isOverBudget = item.spent > item.budgeted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getCategoryColor(item.category),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Presupuestado: ${currencyFormat.format(item.budgeted)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOverBudget ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOverBudget ? Colors.red.shade700 : Colors.green.shade700,
                    ),
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
                      'Ejecutado:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.spent),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverBudget ? 'Sobrepasado:' : 'Disponible:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.remaining.abs()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (percentage.clamp(0.0, 100.0) / 100),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
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

