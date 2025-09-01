import 'package:intl/intl.dart';

/// Utilitário para formatação de valores monetários no padrão brasileiro
class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Formata um valor double para o padrão brasileiro (R$ 1.234,56)
  static String format(double value) {
    return _currencyFormat.format(value);
  }

  /// Formata um valor double para o padrão brasileiro sem símbolo (1.234,56)
  static String formatWithoutSymbol(double value) {
    final format = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    return format.format(value).trim();
  }

  /// Formata um valor double para o padrão brasileiro com unidade (R$ 1.234,56/km)
  static String formatWithUnit(double value, String unit) {
    return '${format(value)}/$unit';
  }

  /// Converte uma string no formato brasileiro para double
  /// Ex: "1.234,56" -> 1234.56
  static double parse(String value) {
    // Remove espaços e símbolos
    String cleanValue = value.replaceAll(RegExp(r'[R\$\s]'), '');

    // Substitui vírgula por ponto para parsing
    cleanValue = cleanValue.replaceAll(',', '.');

    return double.parse(cleanValue);
  }

  /// Valida se uma string está no formato monetário brasileiro válido
  static bool isValid(String value) {
    try {
      parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }
}
