import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/settings/font_size_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../usuarios/presentation/seleccionar_usuario.dart';
import '../data/catalogos_repository.dart';
import '../data/models/tramite.dart';
import '../data/tramites_repository.dart';
import '../domain/estados.dart';
import 'catalogos_cubit.dart';
import 'nuevo_tramite_page.dart';
import 'tramites_cubit.dart';
import 'widgets/detalle_sheet.dart';
import 'widgets/stat_card.dart';
import 'widgets/tramite_card.dart';

class TramitesPage extends StatelessWidget {
  const TramitesPage({super.key, required this.perfil});
  final UserProfile perfil;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => TramitesCubit(
                  getIt<TramitesRepository>(),
                  uid: perfil.uid,
                  esAdmin: perfil.esAdmin,
                )),
        BlocProvider(
            create: (_) => CatalogosCubit(getIt<CatalogosRepository>())),
      ],
      child: _TramitesView(perfil: perfil),
    );
  }
}

class _TramitesView extends StatefulWidget {
  const _TramitesView({required this.perfil});
  final UserProfile perfil;

  @override
  State<_TramitesView> createState() => _TramitesViewState();
}

class _TramitesViewState extends State<_TramitesView> {
  String _busqueda = '';
  String _filtro = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirNuevoTramite(context),
        backgroundColor: AppColors.acento,
        foregroundColor: AppColors.oscuro,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<TramitesCubit, TramitesState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, state)),
              SliverToBoxAdapter(child: _busquedaYFiltros()),
              if (state.cargando)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _lista(context, state),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, TramitesState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.oscuro, AppColors.oscuro2],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.acento,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car,
                        size: 22, color: AppColors.oscuro),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mis Trámites',
                            style: AppTheme.serif(size: 21, color: Colors.white)),
                        const Text('Registro de gestiones vehiculares',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  if (widget.perfil.esAdmin)
                    IconButton(
                      tooltip: 'Mover trámites entre personas',
                      onPressed: _moverTramites,
                      icon: const Icon(Icons.swap_horiz,
                          size: 22, color: Colors.white70),
                    ),
                  IconButton(
                    tooltip: 'Tamaño de letra',
                    onPressed: () => mostrarTamanoFuente(context),
                    icon: const Icon(Icons.format_size,
                        size: 22, color: Colors.white70),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () => _confirmarSalir(context),
                    icon: const Icon(Icons.logout,
                        size: 20, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Recibido',
                    value: cop(state.totalRecibido),
                    accent: const Color(0xFF86EFAC),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    icon: Icons.error_outline,
                    label: 'Por cobrar',
                    value: cop(state.totalPorCobrar),
                    accent: state.totalPorCobrar > 0
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFF86EFAC),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _busquedaYFiltros() {
    final filtros = [
      ['todos', 'Todos'],
      for (final e in estados.values) [e.key, e.label],
    ];
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar placa, cliente o trámite…',
              prefixIcon: const Icon(Icons.search, color: AppColors.grisSuave),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borde),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borde),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < filtros.length; i++) ...[
                  if (i > 0) const SizedBox(width: 7),
                  _ChipFiltro(
                    label: filtros[i][1],
                    activo: _filtro == filtros[i][0],
                    onTap: () => setState(() => _filtro = filtros[i][0]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _lista(BuildContext context, TramitesState state) {
    final q = _busqueda.toLowerCase().trim();
    final filtrados = state.tramites.where((t) {
      if (_filtro != 'todos' && t.estado != _filtro) return false;
      if (q.isEmpty) return true;
      return t.placa.toLowerCase().contains(q) ||
          t.cliente.toLowerCase().contains(q) ||
          t.tramite.toLowerCase().contains(q);
    }).toList();

    if (filtrados.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Center(
            child: Text('No hay trámites para mostrar.',
                style: TextStyle(color: AppColors.grisTexto)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverList.separated(
        itemCount: filtrados.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final Tramite t = filtrados[i];
          return TramiteCard(
            tramite: t,
            onTap: () => mostrarDetalle(context, t.id, esAdmin: widget.perfil.esAdmin),
          );
        },
      ),
    );
  }

  Future<void> _confirmarSalir(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.oscuro),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true) authCubit.logout();
  }

  Future<void> _moverTramites() async {
    final cubit = context.read<TramitesCubit>();
    final origen =
        await seleccionarUsuario(context, titulo: 'Mover trámites DE:');
    if (origen == null || !mounted) return;
    final destino = await seleccionarUsuario(context,
        titulo: 'Mover trámites A:', excluirUid: origen.uid);
    if (destino == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover trámites'),
        content: Text(
            '¿Mover TODOS los trámites de ${origen.nombre} a ${destino.nombre}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.oscuro),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mover')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await cubit.moverTodos(origen.uid, destino.uid, destino.nombre);
      messenger.showSnackBar(SnackBar(
        content: Text(n == 0
            ? '${origen.nombre} no tenía trámites.'
            : 'Se movieron $n trámite(s) a ${destino.nombre}.'),
      ));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo mover. Intenta de nuevo.')));
    }
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  final String label;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.oscuro : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: activo ? AppColors.oscuro : AppColors.borde),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? Colors.white : AppColors.grisTexto,
          ),
        ),
      ),
    );
  }
}
