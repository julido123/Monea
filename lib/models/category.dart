import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 5)
class Category extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String emoji;

  @HiveField(3)
  late bool isIncome; // true = categoría para ingresos, false = para gastos

  @HiveField(4)
  late String color; // Color en formato hex (ej: "#FF5722")

  Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.isIncome = false,
    this.color = '#9E9E9E', // Gris por defecto
  });

  // Crea categorías por defecto genéricas para gastos
  static List<Category> getDefaultExpenseCategories() {
    return [
      Category(id: 'sin_categoria', name: 'Sin categoría', emoji: '📁', isIncome: false, color: '#9E9E9E'),
      Category(id: 'alimentacion', name: 'Alimentación', emoji: '🍔', isIncome: false, color: '#4CAF50'),
      Category(id: 'transporte', name: 'Transporte', emoji: '🚗', isIncome: false, color: '#03A9F4'),
      Category(id: 'vivienda', name: 'Vivienda', emoji: '🏘️', isIncome: false, color: '#795548'),
      Category(id: 'servicios', name: 'Servicios', emoji: '🔧', isIncome: false, color: '#009688'),
      Category(id: 'salud', name: 'Salud', emoji: '🏥', isIncome: false, color: '#F44336'),
      Category(id: 'educacion', name: 'Educación', emoji: '📚', isIncome: false, color: '#FF9800'),
      Category(id: 'entretenimiento', name: 'Entretenimiento', emoji: '🎬', isIncome: false, color: '#9C27B0'),
      Category(id: 'compras', name: 'Compras', emoji: '🛒', isIncome: false, color: '#E91E63'),
      Category(id: 'ahorro', name: 'Ahorro', emoji: '💰', isIncome: false, color: '#00796B'),
      Category(id: 'otros', name: 'Otros', emoji: '📦', isIncome: false, color: '#9E9E9E'),
    ];
  }

  static List<Category> getDefaultIncomeCategories() {
    return [
      Category(id: 'sin_categoria_ingreso', name: 'Sin categoría', emoji: '📁', isIncome: true, color: '#9E9E9E'),
      Category(id: 'sueldo', name: 'Sueldo', emoji: '💼', isIncome: true, color: '#4CAF50'),
      Category(id: 'transferencia', name: 'Transferencia', emoji: '💸', isIncome: true, color: '#2196F3'),
      Category(id: 'deposito', name: 'Depósito', emoji: '🏦', isIncome: true, color: '#009688'),
      Category(id: 'freelance', name: 'Freelance', emoji: '💻', isIncome: true, color: '#FF9800'),
      Category(id: 'bonificacion', name: 'Bonificación', emoji: '🎁', isIncome: true, color: '#F57C00'),
      Category(id: 'otros_ingresos', name: 'Otros ingresos', emoji: '💳', isIncome: true, color: '#9E9E9E'),
    ];
  }
}

