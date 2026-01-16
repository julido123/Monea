import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/payment_record.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/budget_service.dart';
import '../services/backup_service.dart';
import '../services/category_service.dart';

class BudgetConfigScreen extends StatefulWidget {
  const BudgetConfigScreen({super.key});

  @override
  State<BudgetConfigScreen> createState() => _BudgetConfigScreenState();
}

class _BudgetConfigScreenState extends State<BudgetConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Presupuesto'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportData(context);
              } else if (value == 'import') {
                _importData(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Exportar datos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Importar datos'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Presupuestos', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'Gastos Fijos', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BudgetsTab(),
          _FixedExpensesTab(),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await BackupService.shareBackup();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos exportados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final filePath = await BackupService.pickBackupFile();
      
      if (filePath == null) {
        return; // Usuario canceló
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await BackupService.importData(filePath);

      if (context.mounted) {
        Navigator.pop(context);
        
        if (result.totalImported > 0) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Importación exitosa'),
              content: Text(
                'Se importaron:\n'
                '• ${result.transactionsImported} transacciones\n'
                '• ${result.budgetsImported} presupuestos\n'
                '• ${result.fixedExpensesImported} gastos fijos\n'
                '• ${result.incomesImported} ingresos\n'
                '• ${result.paymentRecordsImported} registros de pago',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se importaron datos nuevos (ya existen)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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
}

class _BudgetsTab extends StatefulWidget {
  const _BudgetsTab();

  @override
  State<_BudgetsTab> createState() => _BudgetsTabState();
}

class _BudgetsTabState extends State<_BudgetsTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Sin categoría';
  String _selectedCategoryId = '';
  final DateTime _currentMonth = DateTime.now();
  bool _isFormExpanded = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      // Validar que haya una categoría seleccionada
      final categories = CategoryService.getCategoriesByType(false);
      if (categories.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay categorías disponibles. Crea una categoría primero.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Asegurar que la categoría seleccionada sea válida
      String categoryName = _selectedCategory;
      if (_selectedCategoryId.isEmpty || 
          !categories.any((c) => c.id == _selectedCategoryId)) {
        // Si el ID no es válido, usar la primera categoría disponible
        final firstCategory = categories.first;
        _selectedCategoryId = firstCategory.id;
        categoryName = firstCategory.name;
      } else {
        // Validar que el nombre coincida con el ID
        final selectedCategory = CategoryService.getCategory(_selectedCategoryId);
        if (selectedCategory != null) {
          categoryName = selectedCategory.name;
        }
      }

      final amount = double.parse(_amountController.text);
      final budget = Budget.forMonth(
        category: categoryName,
        amount: amount,
        month: _currentMonth,
      );

      await BudgetService.setBudget(budget);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presupuesto guardado'),
            backgroundColor: Colors.green,
          ),
        );
        _amountController.clear();
        setState(() {});
      }
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: Text('¿Estás seguro de que deseas eliminar el presupuesto de ${budget.category}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BudgetService.deleteBudget(budget.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presupuesto eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _duplicateToNextMonth() async {
    final budgets = BudgetService.getBudgetsForMonth(_currentMonth);
    if (budgets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay presupuestos para duplicar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    int duplicatedCount = 0;

    for (var budget in budgets) {
      final newBudget = Budget.forMonth(
        category: budget.category,
        amount: budget.amount,
        month: nextMonth,
      );
      
      // Solo duplicar si no existe ya un presupuesto para ese mes
      final existing = BudgetService.getBudget(budget.category, nextMonth);
      if (existing == null) {
        await BudgetService.setBudget(newBudget);
        duplicatedCount++;
      }
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$duplicatedCount presupuesto(s) duplicado(s) al siguiente mes'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editBudget(Budget budget) async {
    _amountController.text = budget.amount.toStringAsFixed(2);
    _selectedCategory = budget.category;
    // Buscar la categoría por nombre para obtener el ID
    final category = CategoryService.getCategoryByName(budget.category, false);
    _selectedCategoryId = category?.id ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar presupuesto'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: CategoryService.box.listenable(),
                builder: (context, Box<Category> box, _) {
                  final categories = CategoryService.getCategoriesByType(false);
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId.isEmpty && categories.isNotEmpty 
                        ? categories.firstWhere(
                            (c) => c.name == _selectedCategory,
                            orElse: () => categories.first,
                          ).id
                        : _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Text(category.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final selectedCategory = CategoryService.getCategory(value);
                        if (selectedCategory != null) {
                          setState(() {
                            _selectedCategoryId = value;
                            _selectedCategory = selectedCategory.name;
                          });
                        }
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un monto';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final amount = double.parse(_amountController.text);
      budget.amount = amount;
      budget.category = _selectedCategory;
      budget.id = '${_selectedCategory}_${budget.month.year}_${budget.month.month}';
      await BudgetService.setBudget(budget);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presupuesto actualizado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgets = BudgetService.getBudgetsForMonth(_currentMonth);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Column(
      children: [
        // Formulario para agregar presupuesto (colapsable)
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.teal),
            title: const Text(
              'Nuevo presupuesto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: _isFormExpanded 
                ? null 
                : const Text(
                    'Toca para agregar un nuevo presupuesto',
                    style: TextStyle(fontSize: 12),
                  ),
            initiallyExpanded: false,
            onExpansionChanged: (expanded) {
              setState(() => _isFormExpanded = expanded);
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: CategoryService.box.listenable(),
                        builder: (context, Box<Category> box, _) {
                          final categories = CategoryService.getCategoriesByType(false);
                          
                          // Determinar el valor actual válido para el dropdown
                          String? currentValue;
                          if (categories.isEmpty) {
                            // No hay categorías disponibles
                            currentValue = null;
                          } else if (_selectedCategoryId.isEmpty || 
                                     !categories.any((c) => c.id == _selectedCategoryId)) {
                            // El ID seleccionado no existe o está vacío, usar la primera categoría
                            currentValue = categories.first.id;
                            // Sincronizar el estado si es necesario
                            if (_selectedCategoryId != currentValue) {
                              Future.microtask(() {
                                if (mounted) {
                                  setState(() {
                                    _selectedCategoryId = currentValue!;
                                    _selectedCategory = categories.first.name;
                                  });
                                }
                              });
                            }
                          } else {
                            // El ID seleccionado es válido
                            currentValue = _selectedCategoryId;
                          }
                          
                          return DropdownButtonFormField<String>(
                            value: currentValue,
                            decoration: const InputDecoration(labelText: 'Categoría'),
                            items: categories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Row(
                                  children: [
                                    Text(category.emoji, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 12),
                                    Text(category.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: categories.isEmpty 
                                ? null 
                                : (value) {
                                    if (value != null) {
                                      final selectedCategory = CategoryService.getCategory(value);
                                      if (selectedCategory != null) {
                                        setState(() {
                                          _selectedCategoryId = value;
                                          _selectedCategory = selectedCategory.name;
                                        });
                                      }
                                    }
                                  },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto mensual',
                          prefixText: '\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un monto';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Monto inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveBudget,
                        child: const Text('Guardar presupuesto'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Botón para duplicar presupuestos
        if (budgets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _duplicateToNextMonth,
              icon: const Icon(Icons.copy),
              label: const Text('Duplicar al siguiente mes'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        // Lista de presupuestos
        Expanded(
          child: budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay presupuestos configurados',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    final spent = BudgetService.getSpentInCategory(budget.category, _currentMonth);
                    final available = budget.amount - spent;
                    final percentage = budget.amount > 0 ? (spent / budget.amount * 100) : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(budget.category),
                          child: Icon(
                            _getCategoryIcon(budget.category),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(budget.category),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Presupuesto: ${currencyFormat.format(budget.amount)}'),
                            Text('Gastado: ${currencyFormat.format(spent)}'),
                            Text(
                              'Disponible: ${currencyFormat.format(available)}',
                              style: TextStyle(
                                color: available < 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percentage.clamp(0.0, 1.0) / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage > 100 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              onPressed: () => _editBudget(budget),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _deleteBudget(budget),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

class _FixedExpensesTab extends StatefulWidget {
  const _FixedExpensesTab();

  @override
  State<_FixedExpensesTab> createState() => _FixedExpensesTabState();
}

class _FixedExpensesTabState extends State<_FixedExpensesTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dayController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Vivienda';
  bool _isFormExpanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveFixedExpense() async {
    if (_formKey.currentState!.validate()) {
      final day = int.parse(_dayController.text);
      if (day < 1 || day > 31) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El día debe estar entre 1 y 31')),
        );
        return;
      }

      final expense = FixedExpense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        dayOfMonth: day,
        category: _selectedCategory,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );

      await BudgetService.addFixedExpense(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto fijo guardado'),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _amountController.clear();
        _dayController.clear();
        _descriptionController.clear();
        setState(() {
          _isFormExpanded = false; // Colapsar el formulario después de guardar
        });
      }
    }
  }

  Future<void> _markAsPaid(FixedExpense expense) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    
    final record = PaymentRecord.create(
      fixedExpenseId: expense.id,
      month: month,
      paidDate: now,
      amount: expense.amount,
    );

    await BudgetService.recordPayment(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado')),
      );
      setState(() {});
    }
  }

  Future<void> _editFixedExpense(FixedExpense expense) async {
    final amountController = TextEditingController(text: expense.amount > 0 ? expense.amount.toStringAsFixed(2) : '');
    final dayController = TextEditingController(text: expense.dayOfMonth.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar: ${expense.name}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dayController,
                    decoration: const InputDecoration(
                      labelText: 'Día del mes (1-31)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              final day = int.tryParse(dayController.text);
              
              if (day == null || day < 1 || day > 31) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Día inválido (1-31)')),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      expense.amount = double.tryParse(amountController.text) ?? 0.0;
      expense.dayOfMonth = int.tryParse(dayController.text) ?? expense.dayOfMonth;
      
      await BudgetService.updateFixedExpense(expense);
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto fijo actualizado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = BudgetService.getAllFixedExpenses();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    return Column(
      children: [
        // Formulario para agregar gasto fijo (colapsable)
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.teal),
            title: const Text(
              'Nuevo gasto fijo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: _isFormExpanded 
                ? null 
                : const Text(
                    'Toca para agregar un nuevo gasto fijo',
                    style: TextStyle(fontSize: 12),
                  ),
            initiallyExpanded: false,
            onExpansionChanged: (expanded) {
              setState(() {
                _isFormExpanded = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un monto';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Monto inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dayController,
                        decoration: const InputDecoration(
                          labelText: 'Día del mes (1-31)',
                          helperText: 'Día en que se paga este gasto',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa el día';
                          }
                          final day = int.tryParse(value);
                          if (day == null || day < 1 || day > 31) {
                            return 'Día inválido (1-31)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        items: Transaction.expenseCategories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saveFixedExpense,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar gasto fijo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de gastos fijos
        Expanded(
          child: expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay gastos fijos configurados',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final isPaid = BudgetService.isFixedExpensePaid(expense.id, currentMonth);
                    final paymentRecord = BudgetService.getPaymentRecord(expense.id, currentMonth);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isPaid ? Colors.green.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? Colors.green : Colors.orange,
                          child: Icon(
                            isPaid ? Icons.check : Icons.pending,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(expense.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (expense.amount > 0)
                              Text('Monto: ${currencyFormat.format(expense.amount)}')
                            else
                              const Text(
                                'Monto no configurado',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            Text('Día del mes: ${expense.dayOfMonth}'),
                            if (expense.description != null)
                              Text('Descripción: ${expense.description}'),
                            if (isPaid && paymentRecord != null)
                              Text(
                                'Pagado el: ${DateFormat('dd/MM/yyyy').format(paymentRecord.paidDate)}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              )
                            else
                              const Text(
                                'Pendiente',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              onPressed: () => _editFixedExpense(expense),
                            ),
                            if (!isPaid && expense.amount > 0)
                              IconButton(
                                icon: const Icon(Icons.check_circle),
                                color: Colors.green,
                                onPressed: () => _markAsPaid(expense),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Total de gastos fijos
        if (expenses.isNotEmpty)
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: ListTile(
              leading: const Icon(Icons.calculate, color: Colors.teal),
              title: const Text(
                'Total gastos fijos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: Text(
                currencyFormat.format(expenses.fold(0.0, (sum, e) => sum + e.amount)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

