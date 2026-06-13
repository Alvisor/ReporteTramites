import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../data/models/tramite.dart';
import '../../domain/estados.dart';

class TramiteCard extends StatelessWidget {
  const TramiteCard({super.key, required this.tramite, required this.onTap});

  final Tramite tramite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = estadoInfo(tramite.estado);
    final saldo = tramite.saldo;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(tramite.placa,
                                style: AppTheme.serif(size: 17)),
                            Text(fmtFecha(tramite.fecha),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.grisSuave)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EDE7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(tramite.gestor,
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.grisTexto)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(tramite.tramite,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.tinta)),
                        Text('${tramite.cliente} · ${tramite.sitio}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grisTexto)),
                      ],
                    ),
                  ),
                  _EstadoBadge(e: e),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: _DashedDivider(),
              ),
              Text.rich(TextSpan(children: [
                const TextSpan(
                    text: 'Recibido ',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.grisTexto)),
                TextSpan(
                    text: cop(tramite.recibido),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (tramite.valor > 0)
                  TextSpan(
                      text: ' / ${cop(tramite.valor)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grisSuave)),
              ])),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _PagoChip(saldo: saldo),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFFCBC6BD)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.e});
  final EstadoInfo e;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: e.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: e.borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(e.icon, size: 13, color: e.color),
          const SizedBox(width: 5),
          Text(e.label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: e.color)),
        ],
      ),
    );
  }
}

class _PagoChip extends StatelessWidget {
  const _PagoChip({required this.saldo});
  final int saldo;

  @override
  Widget build(BuildContext context) {
    final pagado = saldo <= 0;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: pagado ? AppColors.verdeBg : AppColors.rojoBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        pagado ? 'Pagado' : 'Debe ${cop(saldo)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: pagado ? AppColors.verde : AppColors.rojo,
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashW = 4.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1,
              color: AppColors.borde,
            ),
          ),
        );
      },
    );
  }
}
