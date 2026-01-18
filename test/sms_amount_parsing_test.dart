import 'package:flutter_test/flutter_test.dart';
import 'package:monea_generic/models/transaction.dart';

void main() {
  group('SMS Amount Parsing Tests', () {
    test('Parse \$413,300.00 correctly', () {
      const sms = 'Bancolombia: Pagaste \$413,300.00 a APORTES EN LINEA desde tu producto *9497 el 07/11/2025 21:28:29.';
      final transaction = Transaction.fromSms(sms, DateTime.now());
      expect(transaction.amount, 413300.00);
    });

    test('Parse \$20,000.00 correctly', () {
      const sms = 'Bancolombia: JULIAN DAVID VASQUEZ CIRO pagaste \$20,000.00 por codigo QR desde tu cuenta *9497 a la llave 0088021321 el 26/11/2025 a las 13:25.';
      final transaction = Transaction.fromSms(sms, DateTime.now());
      expect(transaction.amount, 20000.00);
    });

    test('Parse \$400,000 correctly (no decimals)', () {
      const sms = 'Bancolombia: Transferiste \$400,000 desde tu cuenta *9497 a la cuenta *32525581534 el 27/11/2025 a las 07:32.';
      final transaction = Transaction.fromSms(sms, DateTime.now());
      expect(transaction.amount, 400000.00);
    });

    test('Parse \$60,000 correctly (no decimals)', () {
      const sms = 'Bancolombia: Transferiste \$60,000 desde tu cuenta *9497 a la cuenta *32525581534 el 17/11/2025 a las 20:59.';
      final transaction = Transaction.fromSms(sms, DateTime.now());
      expect(transaction.amount, 60000.00);
    });

    test('Parse large amounts with multiple commas', () {
      const sms = 'Bancolombia: Pagaste \$4,000,000.00 a TEST desde tu cuenta.';
      final transaction = Transaction.fromSms(sms, DateTime.now());
      expect(transaction.amount, 4000000.00);
    });

    test('Parse amounts with only periods (European format fallback)', () {
      const sms = 'Banco: Pagaste \$1.200.000,00 a TEST.';
      final transaction = Transaction.fromSms(sms, DateTime.now());
      expect(transaction.amount, 1200000.00);
    });
  });
}
