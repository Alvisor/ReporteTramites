import 'package:cloud_firestore/cloud_firestore.dart';

/// Evento inmutable del historial de un trámite.
/// tipo: creacion | pago | estado.
class Evento {
  final String id;
  final String tipo;
  final String texto;
  final DateTime sello;
  final String autorUid;
  final String autorNombre;

  const Evento({
    required this.id,
    required this.tipo,
    required this.texto,
    required this.sello,
    required this.autorUid,
    required this.autorNombre,
  });

  factory Evento.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Evento(
      id: doc.id,
      tipo: d['tipo'] as String? ?? 'estado',
      texto: d['texto'] as String? ?? '',
      sello: (d['sello'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autorUid: d['autorUid'] as String? ?? '',
      autorNombre: d['autorNombre'] as String? ?? '',
    );
  }

  /// Mapa para crear el evento (el sello lo pone el servidor).
  /// `ownerUid` es el dueño del trámite al que pertenece el evento; permite
  /// validar permisos sin depender del documento padre al crearse en lote.
  static Map<String, dynamic> toCreate({
    required String tipo,
    required String texto,
    required String autorUid,
    required String autorNombre,
    required String ownerUid,
  }) =>
      {
        'tipo': tipo,
        'texto': texto,
        'autorUid': autorUid,
        'autorNombre': autorNombre,
        'ownerUid': ownerUid,
        'sello': FieldValue.serverTimestamp(),
      };
}
