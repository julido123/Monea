import 'package:flutter/material.dart';

class CategoryUtils {
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Alimentación':
        return Colors.green;
      case 'Transporte':
        return Colors.blue.shade300;
      case 'Vivienda':
        return Colors.brown;
      case 'Servicios':
        return Colors.teal;
      case 'Salud':
        return Colors.red;
      case 'Educación':
        return Colors.orange;
      case 'Entretenimiento':
        return Colors.purple.shade300;
      case 'Compras':
        return Colors.pink;
      case 'Ahorro':
        return Colors.teal.shade700;
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
      default:
        return Colors.grey;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Alimentación':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_car;
      case 'Vivienda':
        return Icons.home;
      case 'Servicios':
        return Icons.build;
      case 'Salud':
        return Icons.medical_services;
      case 'Educación':
        return Icons.school;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Compras':
        return Icons.shopping_bag;
      case 'Ahorro':
        return Icons.savings;
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
      default:
        return Icons.attach_money;
    }
  }
}

