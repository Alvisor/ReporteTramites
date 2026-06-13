import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../data/models/evento.dart';
import '../../domain/estados.dart';

/// Línea de tiempo del historial de un trámite (eventos inmutables).
class Timeline extends StatelessWidget {
  const Timeline({super.key, required this.eventos});
  final List<Evento> eventos;

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Sin eventos todavía',
              style: TextStyle(color: AppColors.grisTexto)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTÓRICO DEL TRÁMITE',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.grisTexto)),
        const SizedBox(height: 14),
        for (int i = 0; i < eventos.length; i++)
          _EventoFila(
            evento: eventos[i],
            ultimo: i == eventos.length - 1,
          ),
      ],
    );
  }
}

class _EventoFila extends StatelessWidget {
  const _EventoFila({required this.evento, required this.ultimo});
  final Evento evento;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final t = tipoEventoInfo(evento.tipo);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(t.icon, size: 17, color: t.color),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(width: 2, color: AppColors.bordeInput),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: ultimo ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.texto,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.oscuro)),
                  const SizedBox(height: 2),
                  Text(
                    '${fmtSello(evento.sello)}'
                    '${evento.autorNombre.isNotEmpty ? ' · ${evento.autorNombre}' : ''}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.grisSuave),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
