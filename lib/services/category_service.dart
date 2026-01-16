import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';

class CategoryService {
  static const String _categoriesBox = 'categories';
  static Box<Category>? _box;

  // Inicializa el servicio
  static Future<void> init() async {
    _box = await Hive.openBox<Category>(_categoriesBox);
    
    // Inicializa categorías por defecto si no existen
    await _initializeDefaultCategories();
  }

  // Inicializa categorías por defecto
  static Future<void> _initializeDefaultCategories() async {
    if (_box == null || !_box!.isOpen) return;

    // Verifica si ya hay categorías
    if (_box!.isNotEmpty) return;

    // Crea categorías por defecto
    final defaultCategories = [
      ...Category.getDefaultExpenseCategories(),
      ...Category.getDefaultIncomeCategories(),
    ];

    for (var category in defaultCategories) {
      await _box!.put(category.id, category);
    }
  }

  // Obtiene la caja de categorías
  static Box<Category> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('CategoryService no inicializado. Llama a CategoryService.init() primero.');
    }
    return _box!;
  }

  // Obtiene todas las categorías
  static List<Category> getAllCategories() {
    return box.values.toList();
  }

  // Obtiene categorías por tipo
  static List<Category> getCategoriesByType(bool isIncome) {
    return box.values.where((c) => c.isIncome == isIncome).toList();
  }

  // Obtiene una categoría por ID
  static Category? getCategory(String id) {
    return box.get(id);
  }

  // Obtiene una categoría por nombre
  static Category? getCategoryByName(String name, bool isIncome) {
    return box.values.firstWhere(
      (c) => c.name == name && c.isIncome == isIncome,
      orElse: () => box.values.firstWhere(
        (c) => c.name == 'Sin categoría' && c.isIncome == isIncome,
        orElse: () => Category(
          id: 'default',
          name: 'Sin categoría',
          emoji: '📁',
          isIncome: isIncome,
        ),
      ),
    );
  }

  // Agrega una nueva categoría
  static Future<void> addCategory(Category category) async {
    await box.put(category.id, category);
  }

  // Actualiza una categoría existente
  static Future<void> updateCategory(Category category) async {
    await category.save();
  }

  // Elimina una categoría
  static Future<void> deleteCategory(String id) async {
    await box.delete(id);
  }

  // Verifica si una categoría existe
  static bool categoryExists(String id) {
    return box.containsKey(id);
  }
}

