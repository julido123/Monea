import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  String description;

  @HiveField(4)
  String category;

  @HiveField(5)
  String? tag;

  @HiveField(6)
  bool isFromSms;

  @HiveField(7)
  String? originalSms;

  @HiveField(8)
  bool isIncome; // true = ingreso, false = gasto

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    this.description = '',
    this.category = 'Sin categoría',
    this.tag,
    this.isFromSms = false,
    this.originalSms,
    this.isIncome = false, // Por defecto es un gasto
  });

  // Lista de categorías disponibles para gastos
  static List<String> get expenseCategories => [
        'Sin categoría',
        'Alimentación',
        'Transporte',
        'Vivienda',
        'Servicios',
        'Salud',
        'Educación',
        'Entretenimiento',
        'Compras',
        'Ahorro',
        'Otros',
      ];

  // Lista de categorías disponibles para ingresos
  static List<String> get incomeCategories => [
        'Sin categoría',
        'Sueldo',
        'Transferencia',
        'Depósito',
        'Freelance',
        'Bonificación',
        'Otros ingresos',
      ];

  // Lista de categorías disponibles (compatibilidad hacia atrás)
  static List<String> get categories => expenseCategories;

  // Normaliza categorías para agrupación (actualmente no hay agrupaciones)
  static String getGroupedCategory(String category) {
    return category;
  }

  // Método para crear una transacción desde SMS
  factory Transaction.fromSms(String smsBody, DateTime date) {
    final amount = _extractAmount(smsBody);
    final category = _detectCategory(smsBody);
    final isIncome = _detectIncome(smsBody);
    
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: date,
      description: _extractDescription(smsBody),
      category: category,
      isFromSms: true,
      originalSms: smsBody,
      isIncome: isIncome,
    );
  }

  // Detecta si el SMS es un ingreso
  static bool _detectIncome(String sms) {
    final lowerSms = sms.toLowerCase();
    final incomeKeywords = [
      'recibiste',
      'transferencia recibida',
      'depósito',
      'deposito',
      'abono',
    ];
    
    return incomeKeywords.any((keyword) => lowerSms.contains(keyword));
  }

  // Detecta la categoría automáticamente basándose en el contenido del SMS
  // Versión genérica: solo detecta gasolina
  static String _detectCategory(String sms) {
    final upperSms = sms.toUpperCase();

    // Solo detecta gasolina
    if (upperSms.contains('GASOLINA') || 
        upperSms.contains('GASOLINERA') ||
        upperSms.contains('COMBUSTIBLE')) {
      return 'Transporte';
    }

    // Por defecto, usa "Sin categoría" - el usuario puede cambiar la categoría después
    return 'Sin categoría';
  }

  // Extrae el monto del SMS
  static double _extractAmount(String sms) {
    // Formato colombiano: $36.753,00 o $1.200.000,00 (punto para miles, coma para decimales)
    // Formato internacional: $1,234.56 (coma para miles, punto para decimales)
    
    // Patrón 1: Formato colombiano con punto para miles y coma para decimales
    // Ejemplo: $36.753,00 o $1.200.000,00
    var match = RegExp(r'\$\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)').firstMatch(sms);
    if (match != null) {
      String amountStr = match.group(1)!
          .replaceAll('.', '') // Elimina puntos (separadores de miles)
          .replaceAll(',', '.'); // Convierte coma decimal a punto
      final amount = double.tryParse(amountStr);
      if (amount != null) return amount;
    }

    // Patrón 2: Formato internacional con coma para miles y punto para decimales
    // Ejemplo: $1,234.56
    match = RegExp(r'\$\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)').firstMatch(sms);
    if (match != null) {
      String amountStr = match.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount != null) return amount;
    }

    // Patrón 3: Solo número con formato colombiano (punto miles, coma decimal)
    match = RegExp(r'(\d{1,3}(?:\.\d{3})*(?:,\d{2})?)').firstMatch(sms);
    if (match != null) {
      String amountStr = match.group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final amount = double.tryParse(amountStr);
      if (amount != null) return amount;
    }

    // Patrón 4: Solo número con formato internacional
    match = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)').firstMatch(sms);
    if (match != null) {
      String amountStr = match.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount != null) return amount;
    }

    // Patrón 5: Número simple sin separadores
    match = RegExp(r'\$\s*(\d+(?:\.\d{2})?)').firstMatch(sms);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!);
      if (amount != null) return amount;
    }

    return 0.0;
  }

  // Extrae una descripción básica del SMS
  static String _extractDescription(String sms) {
    // Intenta extraer el nombre del establecimiento o destinatario
    String description = '';
    
    // Para compras: busca "en [ESTABLECIMIENTO]"
    final compraMatch = RegExp(r'en\s+([A-Z\s\*]+?)(?:\s+con|\s+el|\s+a|\s+desde|$)').firstMatch(sms.toUpperCase());
    if (compraMatch != null) {
      description = compraMatch.group(1)?.trim() ?? '';
    }
    
    // Para transferencias: busca "a la cuenta *[NUMERO]" o "a [NOMBRE]"
    if (description.isEmpty) {
      final transferMatch = RegExp(r'a\s+(?:la\s+)?(?:cuenta\s+\*)?(\d+|\w+\s+\w+)').firstMatch(sms);
      if (transferMatch != null) {
        description = 'Transferencia ${transferMatch.group(1)}';
      }
    }
    
    // Para recargas
    if (description.isEmpty && sms.toUpperCase().contains('RECARGA')) {
      description = 'Recarga de saldo';
    }
    
    // Para pagos
    if (description.isEmpty) {
      final pagoMatch = RegExp(r'a\s+([A-Z\s]+?)(?:\s+desde|\s+el|$)').firstMatch(sms.toUpperCase());
      if (pagoMatch != null) {
        description = pagoMatch.group(1)?.trim() ?? '';
      }
    }
    
    // Si no se encontró nada específico, toma las primeras palabras relevantes
    if (description.isEmpty) {
      // Elimina palabras comunes del banco
      final cleaned = sms
          .replaceAll(RegExp(r'^[A-Za-z]+:\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'\$\d+[.,\d]*', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d{2}/\d{2}/\d{4}', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d{2}:\d{2}', caseSensitive: false), '');
      
      final words = cleaned.split(' ').where((w) => 
        w.isNotEmpty && 
        !['con', 'tu', 'el', 'a', 'las', 'desde', 'cuenta', 'producto', 'si', 'tienes', 'dudas'].contains(w.toLowerCase())
      ).take(8).join(' ');
      
      description = words.length > 50 ? '${words.substring(0, 50)}...' : words;
    }
    
    return description.trim().isEmpty ? 'Transacción bancaria' : description.trim();
  }

  // Verifica si un SMS contiene palabras clave de transacciones
  static bool isTransactionSms(String sms) {
    final lowerSms = sms.toLowerCase();
    
    // Verificar si contiene nombre de banco común o palabras clave
    final hasBank = lowerSms.contains('banco') || 
                    lowerSms.contains('bancolombia') ||
                    lowerSms.contains('davivienda') ||
                    lowerSms.contains('bancodebogota') ||
                    lowerSms.contains('banco de') ||
                    lowerSms.contains('bbva') ||
                    lowerSms.contains('scotiabank');
    
    if (!hasBank) return false;

    // Filtrar SMS promocionales/informativos
    final promoBlacklist = [
      '0% interes',
      '0% interés',
      'tyc',
      't&c',
      'términos',
      'terminos',
      'aplica',
      'promoc',
      'oferta',
      'cuotas',
      'vigencia',
      'hasta el',
      'productos',
      'www.',
      'http',
      'interes*',
      'interés*',
    ];
    final isPromoByKeyword = promoBlacklist.any((k) => lowerSms.contains(k));
    final isPromoByPattern = RegExp(r'por\s+compras\s+desde', caseSensitive: false).hasMatch(sms);
    if (isPromoByKeyword || isPromoByPattern) return false;

    // Solo marcar como transacción si tiene verbos claros de movimiento
    final hasVerb = RegExp(
      r'\b(compraste|pagaste|transferiste|recibiste|recarga|retiro|cargo|debito|débito)\b',
      caseSensitive: false,
    ).hasMatch(sms);

    final hasAmount = RegExp(r'\$\s*[0-9][0-9\.,]*').hasMatch(sms);

    return hasVerb && hasAmount;
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, date: $date, description: $description, category: $category)';
  }
}
