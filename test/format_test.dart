import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reporte_tramites/core/utils/format.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('cop', () {
    test('formatea miles con separador', () {
      expect(cop(234000), '\$234.000');
      expect(cop(0), '\$0');
      expect(cop(null), '\$0');
    });
  });

  group('normalizar', () {
    test('recorta, colapsa espacios y capitaliza', () {
      expect(normalizar('  cambio   de  MOTOR '), 'Cambio De Motor');
      expect(normalizar('bogotá'), 'Bogotá');
      expect(normalizar(''), '');
    });
  });

  group('fmtFecha', () {
    test('formato dd/MM/yy', () {
      expect(fmtFecha(DateTime(2025, 7, 8)), '08/07/25');
    });
  });
}
