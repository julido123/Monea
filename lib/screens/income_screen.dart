import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/budget_service.dart';

class IncomeScreen extends StatefulWidget {
  final Income? income;

  const IncomeScreen({super.key, this.income});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _sourceController;
  late DateTime _selectedDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.income != null;

    if (_isEditing) {
      _amountController = TextEditingController(
        text: widget.income!.amount.toStringAsFixed(2),
      );
      _descriptionController = TextEditingController(
        text: widget.income!.description,
      );
      _sourceController = TextEditingController(
        text: widget.income!.source,
      );
      _selectedDate = widget.income!.date;
    } else {
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _sourceController = TextEditingController(text: 'Sueldo');
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final source = _sourceController.text;

      if (_isEditing) {
        widget.income!.amount = amount;
        widget.income!.description = description;
        widget.income!.source = source;
        widget.income!.date = _selectedDate;

        await BudgetService.updateIncome(widget.income!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingreso actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final income = Income(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          date: _selectedDate,
          description: description,
          source: source,
        );

        await BudgetService.addIncome(income);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingreso registrado'),
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ingreso' : 'Nuevo ingreso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveIncome,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Monto
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Ingresa el monto del ingreso',
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

            // Fuente
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Fuente',
                border: OutlineInputBorder(),
                helperText: 'Ej: Sueldo, Freelance, etc.',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa la fuente del ingreso';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
                helperText: 'Agrega una descripción adicional',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Fecha
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(dateFormat.format(_selectedDate)),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.edit),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onTap: _selectDate,
            ),
          ],
        ),
      ),
    );
  }
}

