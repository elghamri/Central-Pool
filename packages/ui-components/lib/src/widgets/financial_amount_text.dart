import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Pure integer financial formatting utilities.
/// Guarantees ZERO floating-point conversions or IEEE-754 rounding errors.
class FinancialFormatter {
  FinancialFormatter._();

  /// Formats integer minor units (e.g. cents) into a standard currency string.
  /// Example: 500000 minor units -> "$5,000.00"
  static String formatMinorUnits(
    int minorUnits, {
    String currency = 'USD',
    bool showSign = false,
  }) {
    final bool isNegative = minorUnits < 0;
    final int absMinor = isNegative ? -minorUnits : minorUnits;

    final int majorUnits = absMinor ~/ 100;
    final int cents = absMinor % 100;

    // Add thousands commas via integer buffer
    final String majorStr = _formatThousands(majorUnits);
    final String centsStr = cents < 10 ? '0$cents' : '$cents';

    final String symbol = currency == 'USD' ? '\$' : '$currency ';
    final String sign = isNegative
        ? '-'
        : (showSign && minorUnits > 0 ? '+' : '');

    return '$sign$symbol$majorStr.$centsStr';
  }

  /// Parses user-entered currency string back into integer minor units.
  /// Example: "5000.00" -> 500000
  static int? parseToMinorUnits(String input) {
    final clean = input.replaceAll(RegExp(r'[^\d.]'), '');
    if (clean.isEmpty) return null;

    final parts = clean.split('.');
    if (parts.length > 2) return null;

    final int major = int.tryParse(parts[0]) ?? 0;
    int minor = 0;
    if (parts.length == 2) {
      final String centsPart = parts[1].padRight(2, '0').substring(0, 2);
      minor = int.tryParse(centsPart) ?? 0;
    }

    return (major * 100) + minor;
  }

  static String _formatThousands(int number) {
    if (number == 0) return '0';
    final String str = number.toString();
    final StringBuffer buffer = StringBuffer();
    int count = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }

    return buffer.toString().split('').reversed.join('');
  }
}

/// Specialized UI widget for rendering institutional financial amounts safely.
class FinancialAmountText extends StatelessWidget {
  final int amountMinor;
  final String currency;
  final TextStyle? style;
  final Color? color;
  final bool showSign;

  const FinancialAmountText({
    super.key,
    required this.amountMinor,
    this.currency = 'USD',
    this.style,
    this.color,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = FinancialFormatter.formatMinorUnits(
      amountMinor,
      currency: currency,
      showSign: showSign,
    );

    final defaultStyle = style ?? AppTypography.financialDisplay;
    final effectiveColor = color ??
        (amountMinor < 0
            ? AppColors.crimsonRed
            : (amountMinor > 0 && showSign
                ? AppColors.emeraldGreen
                : defaultStyle.color ?? AppColors.textPrimary));

    return Text(
      formatted,
      style: defaultStyle.copyWith(color: effectiveColor),
    );
  }
}
