import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Un trámite vehicular. Espejo de los campos del prototipo.
class Tramite {
  final String id;
  final DateTime fecha;
  final String placa;
  final String tramite;
  final String cliente;
  final String sitio;
  final int valor;
  final int recibido;
  final String estado; // pendiente | proceso | completado
  final String obs;
  final String gestor;
  final String ownerUid;

  const Tramite({
    required this.id,
    required this.fecha,
    required this.placa,
    required this.tramite,
    required this.cliente,
    required this.sitio,
    required this.valor,
    required this.recibido,
    required this.estado,
    required this.obs,
    required this.gestor,
    required this.ownerUid,
  });

  /// Saldo pendiente (nunca negativo).
  int get saldo => math.max(0, valor - recibido);

  bool get pagado => saldo <= 0;

  factory Tramite.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Tramite(
      id: doc.id,
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      placa: d['placa'] as String? ?? '',
      tramite: d['tramite'] as String? ?? '',
      cliente: d['cliente'] as String? ?? '',
      sitio: d['sitio'] as String? ?? '',
      valor: (d['valor'] as num?)?.toInt() ?? 0,
      recibido: (d['recibido'] as num?)?.toInt() ?? 0,
      estado: d['estado'] as String? ?? 'pendiente',
      obs: d['obs'] as String? ?? '',
      gestor: d['gestor'] as String? ?? '',
      ownerUid: d['ownerUid'] as String? ?? '',
    );
  }
}
