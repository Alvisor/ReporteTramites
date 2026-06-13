import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'settings_cubit.dart';

/// Abre el selector de tamaño de letra.
Future<void> mostrarTamanoFuente(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.fondo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _FontSizeSheet(),
    ),
  );
}

class _FontSizeSheet extends StatelessWidget {
  const _FontSizeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: BlocBuilder<SettingsCubit, double>(
          builder: (context, escalaActual) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_size, color: AppColors.oscuro),
                    const SizedBox(width: 10),
                    Text('Tamaño de la letra', style: AppTheme.serif(size: 20)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige el tamaño que mejor se vea para ti.',
                  style: TextStyle(color: AppColors.grisTexto),
                ),
                const SizedBox(height: 16),
                for (final n in nivelesFuente)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OpcionFuente(
                      nivel: n,
                      activo: (escalaActual - n.escala).abs() < 0.001,
                      onTap: () => context.read<SettingsCubit>().setEscala(n.escala),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OpcionFuente extends StatelessWidget {
  const _OpcionFuente({
    required this.nivel,
    required this.activo,
    required this.onTap,
  });

  final NivelFuente nivel;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // No escalamos esta vista previa con el textScaler global: mostramos el
    // tamaño relativo de cada opción de forma fija para poder compararlas.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: activo ? AppColors.acento.withValues(alpha: 0.18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activo ? AppColors.acento : AppColors.bordeInput,
            width: activo ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 16 * nivel.escala,
                      fontWeight: FontWeight.w700,
                      color: AppColors.oscuro,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                  Text(
                    nivel.label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.grisTexto),
                    textScaler: TextScaler.noScaling,
                  ),
                ],
              ),
            ),
            if (activo)
              const Icon(Icons.check_circle, color: AppColors.acento),
          ],
        ),
      ),
    );
  }
}
