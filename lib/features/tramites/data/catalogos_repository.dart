import 'package:cloud_firestore/cloud_firestore.dart';

/// Catálogos autoalimentados y compartidos: tipos de trámite y sitios.
/// Documentos: catalogos/tramites y catalogos/sitios, cada uno con { items: [...] }.
class CatalogosRepository {
  CatalogosRepository(this._db);
  final FirebaseFirestore _db;

  static const tramitesPorDefecto = [
    'Traspaso',
    'Traspaso indeterminado',
    'Radicación de cuenta',
    'Cambio menor y regrabación',
    'Cambio y regrabación motor',
    'Duplicado de tarjeta',
  ];
  static const sitiosPorDefecto = [
    'Bogotá',
    'Funza',
    'Cota',
    'Mosquera',
    'Soacha',
  ];

  DocumentReference<Map<String, dynamic>> _doc(String tipo) =>
      _db.collection('catalogos').doc(tipo);

  Stream<List<String>> watch(String tipo) {
    final fallback =
        tipo == 'sitios' ? sitiosPorDefecto : tramitesPorDefecto;
    return _doc(tipo).snapshots().map((s) {
      final items = (s.data()?['items'] as List?)?.cast<String>() ?? const [];
      final lista = items.isEmpty ? List<String>.from(fallback) : items;
      lista.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return lista;
    });
  }

  /// Agrega un valor al catálogo si no existe (sin duplicar).
  Future<void> agregar(String tipo, String valor) =>
      _doc(tipo).set({
        'items': FieldValue.arrayUnion([valor]),
      }, SetOptions(merge: true));
}
