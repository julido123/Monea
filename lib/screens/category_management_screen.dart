import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _showIncomeCategories = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
      ),
      body: Column(
        children: [
          // Toggle para cambiar entre gastos e ingresos
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Gastos'),
                    selected: !_showIncomeCategories,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _showIncomeCategories = false);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Ingresos'),
                    selected: _showIncomeCategories,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _showIncomeCategories = true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: CategoryService.box.listenable(),
              builder: (context, Box<Category> box, _) {
                final categories = CategoryService.getCategoriesByType(_showIncomeCategories);
                
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay categorías',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _hexToColor(category.color),
                          child: Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        title: Text(category.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCategory(context, category),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCategory(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addCategory(BuildContext context) {
    _showCategoryDialog(context, isIncome: _showIncomeCategories);
  }

  void _editCategory(BuildContext context, Category category) {
    _showCategoryDialog(context, category: category);
  }

  void _showCategoryDialog(BuildContext context, {Category? category, bool? isIncome}) {
    final isEditing = category != null;
    final categoryIsIncome = category?.isIncome ?? isIncome ?? false;
    
    final nameController = TextEditingController(text: category?.name ?? '');
    final emojiController = TextEditingController(text: category?.emoji ?? '😀');
    String selectedColor = category?.color ?? '#9E9E9E';

    final colorOptions = [
      '#F44336', // Rojo
      '#E91E63', // Rosa
      '#9C27B0', // Púrpura
      '#673AB7', // Púrpura oscuro
      '#3F51B5', // Índigo
      '#2196F3', // Azul
      '#03A9F4', // Azul claro
      '#00BCD4', // Cian
      '#009688', // Verde azulado
      '#4CAF50', // Verde
      '#8BC34A', // Verde claro
      '#CDDC39', // Lima
      '#FFEB3B', // Amarillo
      '#FFC107', // Ámbar
      '#FF9800', // Naranja
      '#FF5722', // Naranja oscuro
      '#795548', // Marrón
      '#9E9E9E', // Gris
      '#607D8B', // Azul gris
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emojiController,
                  decoration: const InputDecoration(
                    labelText: 'Emoji',
                    border: OutlineInputBorder(),
                    helperText: 'Ingresa un emoji (ej: 🍔, 🚗, 💰)',
                  ),
                  maxLength: 2,
                ),
                const SizedBox(height: 16),
                const Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            if (isEditing)
              TextButton(
                onPressed: () async {
                  await CategoryService.deleteCategory(category!.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría eliminada')),
                    );
                  }
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }

                if (emojiController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El emoji es requerido')),
                  );
                  return;
                }

                final newCategory = Category(
                  id: isEditing
                      ? category!.id
                      : '${nameController.text.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  emoji: emojiController.text,
                  isIncome: categoryIsIncome,
                  color: selectedColor,
                );

                if (isEditing) {
                  await CategoryService.updateCategory(newCategory);
                } else {
                  await CategoryService.addCategory(newCategory);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Categoría actualizada' : 'Categoría creada'),
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

