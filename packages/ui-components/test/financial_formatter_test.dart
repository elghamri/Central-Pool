import 'package:flutter_test/flutter_test.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('FinancialFormatter — Pure Integer Safety Tests', () {
    test('formats positive amounts without float rounding error', () {
      expect(FinancialFormatter.formatMinorUnits(500000, currency: 'USD'), '\$5,000.00');
      expect(FinancialFormatter.formatMinorUnits(10000, currency: 'USD'), '\$100.00');
      expect(FinancialFormatter.formatMinorUnits(99, currency: 'USD'), '\$0.99');
      expect(FinancialFormatter.formatMinorUnits(5, currency: 'USD'), '\$0.05');
      expect(FinancialFormatter.formatMinorUnits(0, currency: 'USD'), '\$0.00');
    });

    test('formats large institutional amounts with thousand separators', () {
      expect(FinancialFormatter.formatMinorUnits(100000000, currency: 'USD'), '\$1,000,000.00');
      expect(FinancialFormatter.formatMinorUnits(250000050, currency: 'USD'), '\$2,500,000.50');
    });

    test('formats negative amounts and explicit signs correctly', () {
      expect(FinancialFormatter.formatMinorUnits(-50000, currency: 'USD'), '-\$500.00');
      expect(FinancialFormatter.formatMinorUnits(50000, currency: 'USD', showSign: true), '+\$500.00');
    });

    test('parses user string inputs into integer minor units safely', () {
      expect(FinancialFormatter.parseToMinorUnits('5000.00'), 500000);
      expect(FinancialFormatter.parseToMinorUnits('100.5'), 10050);
      expect(FinancialFormatter.parseToMinorUnits('\$1,234.56'), 123456);
      expect(FinancialFormatter.parseToMinorUnits('0.99'), 99);
      expect(FinancialFormatter.parseToMinorUnits('0'), 0);
    });
  });

  group('StatusBadge Factory Tests', () {
    test('maps statuses to correct badge types', () {
      final settledBadge = StatusBadge.fromStatus('SETTLED');
      expect(settledBadge.type, StatusBadgeType.success);

      final pendingBadge = StatusBadge.fromStatus('PENDING');
      expect(pendingBadge.type, StatusBadgeType.warning);

      final delinquentBadge = StatusBadge.fromStatus('DELINQUENT');
      expect(delinquentBadge.type, StatusBadgeType.error);

      final unknownBadge = StatusBadge.fromStatus('UNKNOWN');
      expect(unknownBadge.type, StatusBadgeType.info);
    });
  });
}
