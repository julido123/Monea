import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';

class DetailScreen extends StatefulWidget {
  final Transaction? transaction;

  const DetailScreen({super.key, this.transaction});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedCategoryId;
  bool _isEditing = false;
  bool _isIncome = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transaction != null;
    
    if (_isEditing) {
      _amountController = TextEditingController(
        text: widget.transaction!.amount.toStringAsFixed(2),
      );
      _descriptionController = TextEditingController(
        text: widget.transaction!.description,
      );
      _tagController = TextEditingController(
        text: widget.transaction!.tag ?? '',
      );
      _selectedDate = widget.transaction!.date;
      _selectedCategory = widget.transaction!.category;
      // Buscar la categoría por nombre para obtener el ID
      final category = CategoryService.getCategoryByName(_selectedCategory, widget.transaction!.isIncome);
      _selectedCategoryId = category?.id ?? '';
      _isIncome = widget.transaction!.isIncome;
    } else {
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _tagController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCategory = 'Sin categoría';
      // Obtener la primera categoría por defecto
      final defaultCategories = CategoryService.getCategoriesByType(false);
      final defaultCategory = defaultCategories.isNotEmpty ? defaultCategories.first : null;
      _selectedCategoryId = defaultCategory?.id ?? '';
      _isIncome = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (timePicked != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final tag = _tagController.text.isEmpty ? null : _tagController.text;

      if (_isEditing) {
        // Actualizar transacción existente
        widget.transaction!.amount = amount;
        widget.transaction!.description = description;
        widget.transaction!.category = _selectedCategory;
        widget.transaction!.tag = tag;
        widget.transaction!.date = _selectedDate;
        widget.transaction!.isIncome = _isIncome;
        
        await StorageService.updateTransaction(widget.transaction!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transacción actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Crear nueva transacción
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          date: _selectedDate,
          description: description,
          category: _selectedCategory,
          tag: tag,
          isFromSms: false,
          isIncome: _isIncome,
        );
        
        await StorageService.addTransaction(transaction);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transacción creada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing 
          ? (_isIncome ? 'Editar ingreso' : 'Editar gasto')
          : 'Nueva transacción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTransaction,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo de transacción (Ingreso/Gasto)
            if (!_isEditing)
              Card(
                color: _isIncome ? Colors.green.shade50 : Colors.orange.shade50,
                child: SwitchListTile(
                  title: Text(
                    _isIncome ? 'Ingreso' : 'Gasto',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_isIncome 
                    ? 'Dinero que recibes'
                    : 'Dinero que gastas'),
                  value: _isIncome,
                  onChanged: (value) {
                    setState(() {
                      _isIncome = value;
                      // Resetear categoría cuando cambia el tipo
                      final defaultCategories = CategoryService.getCategoriesByType(value);
                      if (defaultCategories.isNotEmpty) {
                        final defaultCategory = defaultCategories.first;
                        _selectedCategoryId = defaultCategory.id;
                        _selectedCategory = defaultCategory.name;
                      }
                    });
                  },
                  secondary: Icon(
                    _isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: _isIncome ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            if (!_isEditing) const SizedBox(height: 16),
            // Monto
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Ingresa el monto de la transacción',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción (opcional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Describe brevemente la transacción',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Categoría
            ValueListenableBuilder(
              valueListenable: CategoryService.box.listenable(),
              builder: (context, Box<Category> box, _) {
                final categories = CategoryService.getCategoriesByType(_isIncome);
                
                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId.isEmpty && categories.isNotEmpty 
                      ? categories.first.id 
                      : _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    helperText: 'Selecciona una categoría',
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
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

            // Etiqueta
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Etiqueta (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Agrega una etiqueta personalizada',
                prefixIcon: Icon(Icons.label),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Fecha y hora
            ListTile(
              title: const Text('Fecha y hora'),
              subtitle: Text(dateFormat.format(_selectedDate)),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.edit),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),

            // Información adicional si es desde SMS
            if (_isEditing && widget.transaction!.isFromSms)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sms, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Detectada desde SMS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (widget.transaction!.originalSms != null)
                        Text(
                          widget.transaction!.originalSms!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
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
      case 'Sueldo':
        return Colors.green.shade700;
      case 'Transferencia':
        return Colors.blue.shade700;
      case 'Depósito':
        return Colors.teal.shade700;
      case 'Freelance':
        return Colors.orange.shade700;
      case 'Bonificación':
        return Colors.amber.shade700;
      case 'Otros ingresos':
        return Colors.grey.shade700;
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
      case 'Sueldo':
        return Icons.work;
      case 'Transferencia':
        return Icons.swap_horiz;
      case 'Depósito':
        return Icons.account_balance;
      case 'Freelance':
        return Icons.computer;
      case 'Bonificación':
        return Icons.card_giftcard;
      case 'Otros ingresos':
        return Icons.attach_money;
      case 'Ahorro':
        return Icons.savings;
      default:
        return Icons.attach_money;
    }
  }
}

