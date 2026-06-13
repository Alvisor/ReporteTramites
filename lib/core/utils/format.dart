import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatea un valor en pesos colombianos: 234000 -> "$234.000".
String cop(num? n) => '\$${NumberFormat('#,##0', 'es_CO').format(n ?? 0)}';

/// Extrae el entero de un texto con formato de dinero ("$234.000" -> 234000).
int parseMoneda(String s) =>
    int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Formatea en vivo lo que se digita como moneda: 234000 -> "$234.000".
/// Solo acepta dígitos (impide negativos y decimales por construcción).
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _f = NumberFormat('#,##0', 'es_CO');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final valor = int.parse(digits);
    final texto = '\$${_f.format(valor)}';
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Fecha corta: 08/07/25.
String fmtFecha(DateTime f) => DateFormat('dd/MM/yy').format(f);

/// Sello del historial: "08 jul · 09:12".
String fmtSello(DateTime d) =>
    '${DateFormat('dd MMM', 'es').format(d)} · ${DateFormat('HH:mm').format(d)}';

/// Convierte el texto a mayúsculas mientras se escribe (placas).
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Normaliza texto: recorta, colapsa espacios y capitaliza cada palabra.
/// "  cambio   de  MOTOR " -> "Cambio De Motor".
String normalizar(String s) {
  final limpio = s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  if (limpio.isEmpty) return limpio;
  return limpio
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
