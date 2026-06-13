import 'package:flutter/material.dart';

/// Definición de los 3 estados de un trámite (espejo del prototipo).
class EstadoInfo {
  final String key;
  final String label;
  final IconData icon;
  final Color color; // texto/acento
  final Color bg; // fondo del badge
  final Color borde; // borde del badge
  final String desc;

  const EstadoInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.borde,
    required this.desc,
  });
}

const estados = <String, EstadoInfo>{
  'pendiente': EstadoInfo(
    key: 'pendiente',
    label: 'Pendiente',
    icon: Icons.schedule,
    color: Color(0xFFB45309),
    bg: Color(0xFFFEF3C7),
    borde: Color(0xFFFCD34D),
    desc: 'Aún no se ha empezado a gestionar',
  ),
  'proceso': EstadoInfo(
    key: 'proceso',
    label: 'En proceso',
    icon: Icons.hourglass_bottom,
    color: Color(0xFF1D4ED8),
    bg: Color(0xFFDBEAFE),
    borde: Color(0xFF93C5FD),
    desc: 'Ya se está gestionando',
  ),
  'completado': EstadoInfo(
    key: 'completado',
    label: 'Completado',
    icon: Icons.check,
    color: Color(0xFF15803D),
    bg: Color(0xFFDCFCE7),
    borde: Color(0xFF86EFAC),
    desc: 'Trámite terminado y entregado',
  ),
};

EstadoInfo estadoInfo(String key) => estados[key] ?? estados['pendiente']!;

/// Estilo visual por tipo de evento del historial.
class TipoEventoInfo {
  final IconData icon;
  final Color color;
  final Color bg;
  const TipoEventoInfo(this.icon, this.color, this.bg);
}

const tiposEvento = <String, TipoEventoInfo>{
  'creacion':
      TipoEventoInfo(Icons.description, Color(0xFF7C3AED), Color(0xFFEDE9FE)),
  'estado': TipoEventoInfo(
      Icons.hourglass_bottom, Color(0xFF1D4ED8), Color(0xFFDBEAFE)),
  'pago':
      TipoEventoInfo(Icons.attach_money, Color(0xFF15803D), Color(0xFFDCFCE7)),
  'reasignacion':
      TipoEventoInfo(Icons.swap_horiz, Color(0xFFC2410C), Color(0xFFFFEDD5)),
};

TipoEventoInfo tipoEventoInfo(String tipo) =>
    tiposEvento[tipo] ?? tiposEvento['estado']!;
