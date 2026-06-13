import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../usuarios/presentation/seleccionar_usuario.dart';
import '../../data/models/evento.dart';
import '../../data/models/tramite.dart';
import '../../data/tramites_repository.dart';
import '../../domain/estados.dart';
import '../tramites_cubit.dart';
import 'timeline.dart';

/// Abre el bottom-sheet de detalle de un trámite.
Future<void> mostrarDetalle(BuildContext context, String tramiteId,
    {bool esAdmin = false}) {
  final cubit = context.read<TramitesCubit>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.fondo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _DetalleSheet(tramiteId: tramiteId, esAdmin: esAdmin),
    ),
  );
}

class _DetalleSheet extends StatefulWidget {
  const _DetalleSheet({required this.tramiteId, required this.esAdmin});
  final String tramiteId;
  final bool esAdmin;

  @override
  State<_DetalleSheet> createState() => _DetalleSheetState();
}

class _DetalleSheetState extends State<_DetalleSheet> {
  String _tab = 'acciones';
  final _abono = TextEditingController();
  String? _estadoSel;

  @override
  void dispose() {
    _abono.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TramitesCubit, TramitesState>(
      builder: (context, state) {
        final matches = state.tramites.where((x) => x.id == widget.tramiteId);
        final t = matches.isEmpty ? null : matches.first;
        if (t == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Este trámite ya no existe.')),
          );
        }
        _estadoSel ??= t.estado;
        final e = estadoInfo(t.estado);
        final media = MediaQuery.of(context);

        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _cabecera(context, t, e),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _tab == 'acciones'
                        ? _acciones(context, t)
                        : _historial(t),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cabecera(BuildContext context, Tramite t, EstadoInfo e) {
    final saldo = t.saldo;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borde)),
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
                        Text(t.placa, style: AppTheme.serif(size: 23)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: e.bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(e.icon, size: 12, color: e.color),
                              const SizedBox(width: 4),
                              Text(e.label,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: e.color)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(t.tramite,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.tinta)),
                    Text('${t.cliente} · ${t.sitio} · ${fmtFecha(t.fecha)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grisTexto)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.borde,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniBox('Recibido', cop(t.recibido), AppColors.oscuro),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniBox(
                  saldo > 0 ? 'Debe' : 'Estado pago',
                  saldo > 0 ? cop(saldo) : 'Pagado',
                  saldo > 0 ? AppColors.rojo : AppColors.verde,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _tabBtn('acciones', 'Acciones', Icons.attach_money),
              const SizedBox(width: 6),
              _tabBtn('historial', 'Historial', Icons.history),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBox(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.grisSuave)),
            Text(value, style: AppTheme.serif(size: 16, color: color)),
          ],
        ),
      );

  Widget _tabBtn(String key, String label, IconData icon) {
    final active = _tab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.oscuro : AppColors.borde,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: active ? Colors.white : AppColors.grisTexto),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.grisTexto)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- TAB ACCIONES ----------------
  Widget _acciones(BuildContext context, Tramite t) {
    final saldo = t.saldo;
    final rapidos = <int>{
      if (saldo > 0) saldo,
      if (saldo > 0) (saldo / 2 / 1000).round() * 1000,
    }.where((v) => v > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('REGISTRAR ABONO'),
        if (saldo > 0 && t.valor > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in rapidos)
                  OutlinedButton(
                    onPressed: () {
                      final t = cop(v);
                      _abono.value = TextEditingValue(
                        text: t,
                        selection: TextSelection.collapsed(offset: t.length),
                      );
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grisTexto,
                      side: const BorderSide(color: AppColors.bordeInput),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Text(v == saldo ? 'Saldo ${cop(v)}' : cop(v),
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _abono,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  hintText: 'Monto del abono',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: AppColors.bordeInput),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: AppColors.bordeInput),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: parseMoneda(_abono.text) > 0
                  ? () => _registrarAbono(context, t)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.acento,
                foregroundColor: AppColors.oscuro,
                disabledBackgroundColor: AppColors.borde,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Abonar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        if (saldo > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pagoCompleto(context, t),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.verde,
                  backgroundColor: AppColors.verdeBg,
                  side: const BorderSide(color: Color(0xFF86EFAC)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 17),
                label: Flexible(
                  child: Text('Confirmar pago completo (${cop(saldo)})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.verde),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Este trámite ya está pagado por completo.',
                      style: TextStyle(fontSize: 13, color: AppColors.verde)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _titulo('ESTADO DEL TRÁMITE'),
        for (final info in estados.values)
          _opcionEstado(info, t.estado),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (_estadoSel != null && _estadoSel != t.estado)
                ? () => _cambiarEstado(context, t)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.oscuro,
              disabledBackgroundColor: const Color(0xFFD6D3D1),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check, size: 17),
            label: Flexible(
              child: Text(
                (_estadoSel != null && _estadoSel != t.estado)
                    ? 'Confirmar: ${estadoInfo(_estadoSel!).label}'
                    : 'Sin cambios de estado',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        if (widget.esAdmin) ...[
          const SizedBox(height: 24),
          _titulo('REASIGNAR (ADMIN)'),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Dueño actual: ${t.gestor}',
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.grisTexto)),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _reasignar(context, t),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.oscuro,
                side: const BorderSide(color: AppColors.bordeInput),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Flexible(
                child: Text('Reasignar a otra persona',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _opcionEstado(EstadoInfo info, String estadoActual) {
    final activo = _estadoSel == info.key;
    final actual = estadoActual == info.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _estadoSel = info.key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: activo ? info.bg : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: activo ? info.color : AppColors.bordeInput, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: activo ? info.color : const Color(0xFFF0EDE7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(info.icon,
                    size: 16,
                    color: activo ? Colors.white : AppColors.grisSuave),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(info.label,
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: activo ? info.color : AppColors.oscuro)),
                        if (actual)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text('(actual)',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.grisSuave)),
                          ),
                      ],
                    ),
                    Text(info.desc,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.grisTexto)),
                  ],
                ),
              ),
              if (activo) Icon(Icons.check, size: 18, color: info.color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.grisTexto)),
      );

  // ---------------- TAB HISTORIAL ----------------
  Widget _historial(Tramite t) {
    return StreamBuilder<List<Evento>>(
      stream: getIt<TramitesRepository>().watchEventos(t.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Timeline(eventos: snap.data!);
      },
    );
  }

  // ---------------- acciones ----------------
  Future<void> _registrarAbono(BuildContext context, Tramite t) async {
    final monto = parseMoneda(_abono.text);
    if (monto <= 0) return;
    await context.read<TramitesCubit>().abonar(t.id, monto);
    _abono.clear();
    if (mounted) setState(() {});
  }

  Future<void> _pagoCompleto(BuildContext context, Tramite t) async {
    final cubit = context.read<TramitesCubit>();
    final ok = await _confirmar(context, 'Confirmar pago completo',
        'Se marcará como pagado el saldo de ${cop(t.saldo)}. ¿Continuar?');
    if (ok != true) return;
    await cubit.pagoCompleto(t.id);
  }

  Future<void> _cambiarEstado(BuildContext context, Tramite t) async {
    final nuevo = _estadoSel!;
    final cubit = context.read<TramitesCubit>();
    final ok = await _confirmar(context, 'Cambiar estado',
        'Cambiar de "${estadoInfo(t.estado).label}" a "${estadoInfo(nuevo).label}"?');
    if (ok != true) return;
    await cubit.cambiarEstado(t.id, nuevo);
  }

  Future<void> _reasignar(BuildContext context, Tramite t) async {
    final cubit = context.read<TramitesCubit>();
    final u = await seleccionarUsuario(context,
        titulo: 'Reasignar trámite a:', excluirUid: t.ownerUid);
    if (u == null) return;
    await cubit.reasignar(t.id, u.uid, u.nombre);
  }

  Future<bool?> _confirmar(BuildContext context, String titulo, String msg) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.oscuro),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
  }
}
