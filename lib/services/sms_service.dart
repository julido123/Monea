import 'dart:io' show Platform;
import 'package:telephony/telephony.dart';
import '../models/transaction.dart';
import 'storage_service.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;
  
  // Verifica si la plataforma soporta SMS
  static bool get isSmsSupported => !Platform.isLinux && !Platform.isWindows && !Platform.isMacOS;

  // Solicita permisos para leer SMS
  static Future<bool> requestPermissions() async {
    if (!isSmsSupported) return false;
    
    try {
      final bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      return permissionsGranted ?? false;
    } catch (e) {
      print('Error al solicitar permisos: $e');
      return false;
    }
  }

  // Verifica si los permisos están otorgados
  static Future<bool> hasPermissions() async {
    if (!isSmsSupported) return false;
    
    try {
      // En Android, intenta obtener mensajes
      await telephony.getInboxSms(columns: [SmsColumn.ID]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Inicializa el listener de SMS entrantes
  static Future<void> initSmsListener() async {
    if (!isSmsSupported) return;
    
    try {
      telephony.listenIncomingSms(
        onNewMessage: onMessage,
        onBackgroundMessage: onBackgroundMessage,
      );
    } catch (e) {
      print('Error al inicializar listener de SMS: $e');
    }
  }

  // Callback para mensajes nuevos (cuando la app está en primer plano)
  static void onMessage(SmsMessage message) {
    _processSmsMessage(message);
  }

  // Callback para mensajes en segundo plano
  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessage(SmsMessage message) async {
    // Inicializa Hive para el background
    await StorageService.init();
    _processSmsMessage(message);
  }

  // Procesa un mensaje SMS
  static void _processSmsMessage(SmsMessage message) {
    final body = message.body ?? '';
    
    // Verifica si el SMS contiene palabras clave de transacciones
    if (Transaction.isTransactionSms(body)) {
      // Intenta extraer la fecha del SMS, si no, usa la fecha del mensaje
      final date = _extractDateFromSms(body) ?? 
          (message.date != null 
              ? DateTime.fromMillisecondsSinceEpoch(message.date!)
              : DateTime.now());
      
      final transaction = Transaction.fromSms(body, date);
      
      // Verificar si ya existe una transacción con el mismo SMS original (evitar duplicados)
      final existingTransactions = StorageService.getAllTransactions();
      final isDuplicate = existingTransactions.any((existing) {
        if (existing.isFromSms && transaction.isFromSms) {
          return existing.originalSms == transaction.originalSms;
        }
        return false;
      });
      
      // Solo guardar si no es duplicado
      if (!isDuplicate) {
        StorageService.addTransaction(transaction);
      }
    }
  }

  // Extrae la fecha del SMS de Bancolombia
  static DateTime? _extractDateFromSms(String sms) {
    try {
      // Patrón 1: "el 15/12/2025 a las 17:35"
      var match = RegExp(r'el\s+(\d{2})/(\d{2})/(\d{4})\s+a\s+las\s+(\d{2}):(\d{2})', caseSensitive: false).firstMatch(sms);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        return DateTime(year, month, day, hour, minute);
      }

      // Patrón 2: "10/11/2025 15:46"
      match = RegExp(r'(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2})').firstMatch(sms);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        return DateTime(year, month, day, hour, minute);
      }

      // Patrón 3: "el 07/11/2025 21:28:29"
      match = RegExp(r'el\s+(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})', caseSensitive: false).firstMatch(sms);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        return DateTime(year, month, day, hour, minute);
      }

      // Patrón 4: "el 13/12/2025 a las 21:05"
      match = RegExp(r'el\s+(\d{2})/(\d{2})/(\d{4})\s+a\s+las\s+(\d{1,2}):(\d{2})', caseSensitive: false).firstMatch(sms);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        return DateTime(year, month, day, hour, minute);
      }

      // Patrón 5: Solo fecha "15/12/2025"
      match = RegExp(r'(\d{2})/(\d{2})/(\d{4})').firstMatch(sms);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error al extraer fecha del SMS: $e');
    }
    
    return null;
  }

  // Lee SMS históricos de la bandeja de entrada
  static Future<List<Transaction>> readHistoricalSms({int count = 100}) async {
    final List<Transaction> transactions = [];
    
    if (!isSmsSupported) return transactions;
    
    try {
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Limitar manualmente a 'count' mensajes
      final limitedMessages = messages.take(count);

      for (var message in limitedMessages) {
        final body = message.body ?? '';
        
        if (Transaction.isTransactionSms(body)) {
          // Intenta extraer la fecha del SMS, si no, usa la fecha del mensaje
          final date = _extractDateFromSms(body) ?? 
              (message.date != null
                  ? DateTime.fromMillisecondsSinceEpoch(message.date!)
                  : DateTime.now());
          
          final transaction = Transaction.fromSms(body, date);
          transactions.add(transaction);
        }
      }
    } catch (e) {
      print('Error al leer SMS históricos: $e');
    }
    
    return transactions;
  }

  // Importa transacciones desde SMS históricos
  static Future<int> importFromSms({int count = 100}) async {
    final transactions = await readHistoricalSms(count: count);
    int imported = 0;
    
    // Obtener todas las transacciones existentes para comparar
    final existingTransactions = StorageService.getAllTransactions();
    
    for (var transaction in transactions) {
      // Verifica si ya existe una transacción con el mismo SMS original
      // Esto evita duplicados cuando se importa múltiples veces
      final isDuplicate = existingTransactions.any((existing) {
        // Si ambas son de SMS, comparar el texto original
        if (existing.isFromSms && transaction.isFromSms) {
          return existing.originalSms == transaction.originalSms;
        }
        // Si no son de SMS, comparar por fecha, monto y descripción
        return existing.date.year == transaction.date.year &&
               existing.date.month == transaction.date.month &&
               existing.date.day == transaction.date.day &&
               existing.amount == transaction.amount &&
               existing.description == transaction.description;
      });
      
      if (!isDuplicate) {
        await StorageService.addTransaction(transaction);
        imported++;
      }
    }
    
    return imported;
  }
}

