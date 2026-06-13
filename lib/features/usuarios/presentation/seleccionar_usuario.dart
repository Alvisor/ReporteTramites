import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/usuarios_repository.dart';

/// Muestra la lista de usuarios y devuelve el elegido (o null si cancela).
Future<Usuario?> seleccionarUsuario(
  BuildContext context, {
  required String titulo,
  String? excluirUid,
}) {
  return showModalBottomSheet<Usuario>(
    context: context,
    backgroundColor: AppColors.fondo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SelectorUsuario(titulo: titulo, excluirUid: excluirUid),
  );
}

class _SelectorUsuario extends StatelessWidget {
  const _SelectorUsuario({required this.titulo, this.excluirUid});
  final String titulo;
  final String? excluirUid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: FutureBuilder<List<Usuario>>(
          future: getIt<UsuariosRepository>().listar(),
          builder: (context, snap) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppTheme.serif(size: 19)),
                const SizedBox(height: 12),
                if (!snap.hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ...snap.data!
                      .where((u) => u.uid != excluirUid)
                      .map((u) => Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.borde),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.acento.withValues(alpha: 0.25),
                                child: Text(
                                  u.nombre.isNotEmpty
                                      ? u.nombre[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppColors.oscuro,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(u.nombre,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              subtitle: u.esAdmin
                                  ? const Text('Administrador')
                                  : null,
                              onTap: () => Navigator.pop(context, u),
                            ),
                          )),
              ],
            );
          },
        ),
      ),
    );
  }
}
