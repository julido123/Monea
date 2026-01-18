import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/sms_service.dart';
import '../services/category_service.dart';
import 'detail_screen.dart';
import 'summary_screen.dart';
import 'budget_config_screen.dart';
import 'monthly_budget_screen.dart';
import 'category_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermissions = false;
  bool _isLoadingPermissions = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await SmsService.hasPermissions();
    setState(() {
      _hasPermissions = hasPermissions;
      _isLoadingPermissions = false;
    });
    
    // Si tiene permisos, asegurar que el listener esté activo
    if (hasPermissions) {
      try {
        await SmsService.initSmsListener();
      } catch (e) {
        print('Error al inicializar listener: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await SmsService.requestPermissions();
    if (granted) {
      await SmsService.initSmsListener();
      setState(() {
        _hasPermissions = true;
      });
      
      // Mostrar diálogo para importar SMS históricos
      if (mounted) {
        _showImportDialog();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de SMS denegados'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar transacciones'),
        content: const Text(
          '¿Deseas importar transacciones de tus SMS históricos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _importFromSms();
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromSms() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final importCount = SmsService.getImportCount();
      final count = await SmsService.importFromSms(count: importCount);
      await SmsService.incrementSyncCount();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count transacciones importadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.teal,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Monea',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.teal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MonthlyBudgetScreen(),
                ),
              );
            },
            tooltip: 'Presupuesto mensual',
          ),
          IconButton(
            icon: const Icon(Icons.category, color: Colors.teal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              );
            },
            tooltip: 'Gestionar categorías',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.teal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SummaryScreen(),
                ),
              );
            },
            tooltip: 'Estadísticas',
          ),
          if (!_hasPermissions && !_isLoadingPermissions)
            IconButton(
              icon: const Icon(Icons.sms, color: Colors.teal),
              onPressed: _requestPermissions,
              tooltip: 'Activar lectura de SMS',
            ),
          if (_hasPermissions)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.teal),
              onPressed: () async {
                await _importFromSms();
              },
              tooltip: 'Importar SMS recientes',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasPermissions && !_isLoadingPermissions)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permisos de SMS desactivados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Activa los permisos para detectar transacciones automáticamente',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _requestPermissions,
                    child: const Text('Activar'),
                  ),
                ],
              ),
            ),
          // Selector de mes
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'es').format(_selectedMonth),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                          final now = DateTime.now();
                          if (nextMonth.year <= now.year && 
                              (nextMonth.year < now.year || nextMonth.month <= now.month + 1)) {
                            setState(() {
                              _selectedMonth = nextMonth;
                            });
                          }
                        },
                      ),
                      // Botón para volver al mes actual
                      if (_selectedMonth.year != DateTime.now().year || 
                          _selectedMonth.month != DateTime.now().month)
                        IconButton(
                          icon: const Icon(Icons.today),
                          tooltip: 'Mes actual',
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime.now();
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
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
                          Icons.receipt_long,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay transacciones',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay transacciones en ${DateFormat('MMMM yyyy', 'es').format(_selectedMonth)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca el botón + para agregar una',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _TransactionCard(
                      transaction: transaction,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              transaction: transaction,
                            ),
                          ),
                        );
                      },
                      onDelete: () async {
                        await StorageService.deleteTransaction(transaction.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transacción eliminada'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DetailScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Color de fondo según tipo de transacción
    final cardColor = transaction.isIncome 
        ? Colors.green.shade100 // Verde para ingresos
        : Colors.red.shade100; // Rojo para gastos

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: cardColor,
      child: Dismissible(
        key: Key(transaction.id),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: const Text('¿Estás seguro de eliminar esta transacción?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        child: ListTile(
          onTap: onTap,
          leading: Builder(
            builder: (context) {
              if (transaction.isIncome) {
                final category = CategoryService.getCategoryByName(transaction.category, true);
                return CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    category?.emoji ?? '💰',
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              } else {
                final category = CategoryService.getCategoryByName(transaction.category, false);
                return CircleAvatar(
                  backgroundColor: category != null 
                      ? _hexToColor(category.color)
                      : _getCategoryColor(transaction.category),
                  child: Text(
                    category?.emoji ?? '📁',
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              }
            },
          ),
          title: Text(
            currencyFormat.format(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: transaction.isIncome ? Colors.green : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (transaction.isIncome) ...[
                    Icon(Icons.arrow_downward, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('Ingreso', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(transaction.description)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(transaction.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (transaction.isFromSms) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.sms, size: 12, color: Colors.blue.shade400),
                  ],
                ],
              ),
            ],
          ),
          trailing: transaction.isIncome 
            ? null
            : Builder(
                builder: (context) {
                  final category = CategoryService.getCategoryByName(transaction.category, false);
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Chip(
                      avatar: Text(category?.emoji ?? '📁'),
                      label: Text(
                        transaction.category,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      backgroundColor: category != null
                          ? _hexToColor(category.color).withOpacity(0.2)
                          : _getCategoryColor(transaction.category).withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
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

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

