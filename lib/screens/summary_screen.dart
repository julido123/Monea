import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
      ),
      body: ValueListenableBuilder(
        valueListenable: StorageService.box.listenable(),
        builder: (context, Box<Transaction> box, _) {
          // Filtrar transacciones del mes seleccionado
          final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
          final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
          final transactions = StorageService.getTransactionsByDateRange(monthStart, monthEnd);

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay datos para mostrar',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filtrar solo gastos (excluir ingresos)
          final expenses = transactions.where((t) => !t.isIncome).toList();
          
          final totalAmount = StorageService.getTotalAmount(expenses);
          final categoryAmounts = StorageService.getAmountByCategory(expenses);
          final dailyAmounts = StorageService.getAmountByDay(expenses);

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

                // Total de gastos
                _TotalCard(amount: totalAmount),
                const SizedBox(height: 24),

                // Gráfico circular por categoría
                const Text(
                  'Gastos por categoría',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _CategoryPieChart(categoryAmounts: categoryAmounts),
                const SizedBox(height: 24),

                // Lista de categorías con montos
                _CategoryList(categoryAmounts: categoryAmounts),
                const SizedBox(height: 24),

                // Gráfico de barras por día
                const Text(
                  'Gastos diarios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _DailyBarChart(dailyAmounts: dailyAmounts),
              ],
            ),
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

class _TotalCard extends StatelessWidget {
  final double amount;

  const _TotalCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Total de gastos',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryAmounts;

  const _CategoryPieChart({required this.categoryAmounts});

  @override
  Widget build(BuildContext context) {
    if (categoryAmounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = categoryAmounts.values.fold(0.0, (sum, amount) => sum + amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 280,
              child: PieChart(
                PieChartData(
                  sections: sortedCategories.map((entry) {
                    final percentage = (entry.value / total * 100);
                    final color = _getCategoryColor(entry.key);
                    
                    // Solo mostrar porcentaje si es mayor a 3%
                    final showPercentage = percentage >= 3.0;
                    
                    return PieChartSectionData(
                      value: entry.value,
                      title: showPercentage ? '${percentage.toStringAsFixed(1)}%' : '',
                      color: color,
                      radius: 110,
                      titleStyle: TextStyle(
                        fontSize: percentage > 10 ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                ),
              ),
            ),
            // Widget central con el total
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(total),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
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
      case 'Sin categoría':
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }
}

class _CategoryList extends StatelessWidget {
  final Map<String, double> categoryAmounts;

  const _CategoryList({required this.categoryAmounts});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final sortedCategories = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedCategories.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = sortedCategories[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(entry.key),
              child: Icon(
                _getCategoryIcon(entry.key),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(entry.key),
            trailing: Text(
              currencyFormat.format(entry.value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        },
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

class _DailyBarChart extends StatelessWidget {
  final Map<DateTime, double> dailyAmounts;

  const _DailyBarChart({required this.dailyAmounts});

  @override
  Widget build(BuildContext context) {
    if (dailyAmounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = dailyAmounts.keys.toList()..sort();
    final maxAmount = dailyAmounts.values.fold(0.0, (max, amount) => amount > max ? amount : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final date = sortedDates[group.x.toInt()];
                    final dateFormat = DateFormat('dd/MM');
                    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
                    return BarTooltipItem(
                      '${dateFormat.format(date)}\n${currencyFormat.format(rod.toY)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= sortedDates.length) {
                        return const Text('');
                      }
                      final date = sortedDates[value.toInt()];
                      final format = DateFormat('dd/MM');
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          format.format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: sortedDates.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                final amount = dailyAmounts[date] ?? 0.0;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: amount,
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

