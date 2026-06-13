import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/campo_buscador.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/estados.dart';
import 'catalogos_cubit.dart';
import 'tramites_cubit.dart';

/// Abre el asistente paso a paso para crear un trámite.
Future<void> abrirNuevoTramite(BuildContext context) {
  final tramitesCubit = context.read<TramitesCubit>();
  final catalogosCubit = context.read<CatalogosCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: tramitesCubit),
          BlocProvider.value(value: catalogosCubit),
        ],
        child: const NuevoTramitePage(),
      ),
    ),
  );
}

class NuevoTramitePage extends StatefulWidget {
  const NuevoTramitePage({super.key});

  @override
  State<NuevoTramitePage> createState() => _NuevoTramitePageState();
}

class _NuevoTramitePageState extends State<NuevoTramitePage> {
  static const _totalPasos = 5;
  int _paso = 0;
  bool _guardando = false;

  DateTime _fecha = DateTime.now();
  final _placa = TextEditingController();
  final _cliente = TextEditingController();
  final _valor = TextEditingController();
  final _abono = TextEditingController();
  final _obs = TextEditingController();
  String? _tramite;
  String? _sitio;
  String _estado = 'pendiente';

  @override
  void dispose() {
    for (final c in [_placa, _cliente, _valor, _abono, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- validación por paso ----------
  String? _errorPaso(int paso) {
    switch (paso) {
      case 0:
        if (_placa.text.trim().isEmpty) return 'Escribe la placa del vehículo.';
        return null;
      case 1:
        if (_tramite == null || _tramite!.isEmpty) {
          return 'Elige el tipo de trámite.';
        }
        return null;
      case 2:
        if (_cliente.text.trim().isEmpty) return 'Escribe el nombre del cliente.';
        return null;
      case 3:
        final valor = parseMoneda(_valor.text);
        if (valor < 10000) return 'El valor del trámite debe ser de al menos \$10.000.';
        final abono = parseMoneda(_abono.text);
        if (abono > valor) return 'El abono no puede ser mayor que el valor del trámite.';
        return null;
      default:
        return null;
    }
  }

  void _siguiente() {
    final error = _errorPaso(_paso);
    if (error != null) {
      _avisar(error);
      return;
    }
    if (_paso < _totalPasos - 1) {
      setState(() => _paso++);
    } else {
      _guardar();
    }
  }

  void _atras() {
    if (_paso > 0) setState(() => _paso--);
  }

  void _avisar(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final catCubit = context.read<CatalogosCubit>();
    final tramitesCubit = context.read<TramitesCubit>();
    final navigator = Navigator.of(context);

    try {
      final cat = catCubit.state;
      if (_tramite != null && !cat.tramites.contains(_tramite)) {
        await catCubit.agregarTramite(_tramite!);
      }
      if (_sitio != null && _sitio!.isNotEmpty && !cat.sitios.contains(_sitio)) {
        await catCubit.agregarSitio(_sitio!);
      }
      await tramitesCubit.crear(
        fecha: _fecha,
        placa: _placa.text,
        tramite: _tramite!,
        cliente: _cliente.text,
        sitio: _sitio ?? '',
        valor: parseMoneda(_valor.text),
        recibido: parseMoneda(_abono.text),
        estado: _estado,
        obs: _obs.text,
      );
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _guardando = false);
        _avisar('No se pudo guardar. Intenta de nuevo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        elevation: 0,
        title: Text('Nuevo trámite', style: AppTheme.serif(size: 20)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _progreso(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _contenidoPaso(),
              ),
            ),
            _barraInferior(),
          ],
        ),
      ),
    );
  }

  Widget _progreso() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_totalPasos, (i) {
              final hecho = i <= _paso;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < _totalPasos - 1 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: hecho ? AppColors.acento : AppColors.bordeInput,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('Paso ${_paso + 1} de $_totalPasos',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grisTexto)),
        ],
      ),
    );
  }

  Widget _contenidoPaso() {
    switch (_paso) {
      case 0:
        return _pasoVehiculo();
      case 1:
        return _pasoTramite();
      case 2:
        return _pasoCliente();
      case 3:
        return _pasoDinero();
      default:
        return _pasoEstadoYResumen();
    }
  }

  // ---------- pasos ----------
  Widget _pasoVehiculo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('🚗 Datos del vehículo'),
        _campo(
          label: 'Placa',
          controller: _placa,
          requerido: true,
          hint: 'Ej: ABC123',
          mayus: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        _LabelCampo('Fecha', false),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _fecha,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (d != null) setState(() => _fecha = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.bordeInput),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 18, color: AppColors.grisTexto),
                const SizedBox(width: 10),
                Text(fmtFecha(_fecha), style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pasoTramite() {
    final cat = context.watch<CatalogosCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('📄 Trámite y lugar'),
        CampoBuscador(
          label: 'Tipo de trámite',
          requerido: true,
          value: _tramite,
          items: cat.tramites,
          onChanged: (v) => setState(() => _tramite = v),
        ),
        const SizedBox(height: 18),
        CampoBuscador(
          label: 'Sitio de matrícula',
          value: _sitio,
          items: cat.sitios,
          onChanged: (v) => setState(() => _sitio = v),
        ),
      ],
    );
  }

  Widget _pasoCliente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('👤 Cliente'),
        _campo(
          label: 'Nombre del cliente',
          controller: _cliente,
          requerido: true,
          hint: 'Ej: Sr. Adrián',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _pasoDinero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('💵 Dinero'),
        _campo(
          label: 'Valor del trámite',
          controller: _valor,
          requerido: true,
          hint: '\$0',
          moneda: true,
          onChanged: (_) => setState(() {}),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6, left: 4),
          child: Text('Mínimo \$10.000',
              style: TextStyle(fontSize: 12.5, color: AppColors.grisTexto)),
        ),
        const SizedBox(height: 18),
        _campo(
          label: 'Abono inicial (opcional)',
          controller: _abono,
          hint: '\$0',
          moneda: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _resumenSaldo(),
      ],
    );
  }

  Widget _resumenSaldo() {
    final valor = parseMoneda(_valor.text);
    final abono = parseMoneda(_abono.text);
    if (valor <= 0) return const SizedBox.shrink();
    final saldo = (valor - abono).clamp(0, valor);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Quedaría debiendo',
              style: TextStyle(fontSize: 14, color: AppColors.grisTexto)),
          Text(cop(saldo),
              style: AppTheme.serif(
                  size: 17,
                  color: saldo > 0 ? AppColors.rojo : AppColors.verde)),
        ],
      ),
    );
  }

  Widget _pasoEstadoYResumen() {
    final nombre = getIt<AuthRepository>().nombre;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('✅ Estado y confirmación'),
        _LabelCampo('Estado inicial', false),
        const SizedBox(height: 8),
        for (final info in estados.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _chipEstado(info),
          ),
        const SizedBox(height: 14),
        _campo(
          label: 'Observaciones (opcional)',
          controller: _obs,
          hint: 'Ej: Pendiente fotocopia',
          onChanged: (_) {},
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen', style: AppTheme.serif(size: 17)),
              const SizedBox(height: 10),
              _filaResumen('Placa', _placa.text.toUpperCase()),
              _filaResumen('Trámite', _tramite ?? '—'),
              _filaResumen('Cliente', _cliente.text),
              if ((_sitio ?? '').isNotEmpty) _filaResumen('Sitio', _sitio!),
              _filaResumen('Valor', cop(parseMoneda(_valor.text))),
              _filaResumen('Abono', cop(parseMoneda(_abono.text))),
              _filaResumen('Registrado por', nombre),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filaResumen(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.grisTexto)),
            ),
            Expanded(
              child: Text(v.isEmpty ? '—' : v,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _chipEstado(EstadoInfo info) {
    final activo = _estado == info.key;
    return GestureDetector(
      onTap: () => setState(() => _estado = info.key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: activo ? info.bg : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: activo ? info.color : AppColors.bordeInput,
              width: activo ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(info.icon,
                size: 20, color: activo ? info.color : AppColors.grisSuave),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.label,
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: activo ? info.color : AppColors.oscuro)),
                  Text(info.desc,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.grisTexto)),
                ],
              ),
            ),
            if (activo) Icon(Icons.check_circle, color: info.color),
          ],
        ),
      ),
    );
  }

  Widget _barraInferior() {
    final esUltimo = _paso == _totalPasos - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          if (_paso > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _guardando ? null : _atras,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.bordeInput),
                  foregroundColor: AppColors.oscuro,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
                child: const Text('Atrás',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_paso > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _guardando ? null : _siguiente,
              style: FilledButton.styleFrom(
                backgroundColor: esUltimo ? AppColors.verde : AppColors.oscuro,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              icon: _guardando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(esUltimo ? Icons.check : Icons.arrow_forward, size: 19),
              label: Flexible(
                child: Text(esUltimo ? 'Guardar trámite' : 'Siguiente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- helpers de campo ----------
  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(t, style: AppTheme.serif(size: 22)),
      );

  Widget _campo({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? hint,
    bool requerido = false,
    bool moneda = false,
    bool mayus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelCampo(label, requerido),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: moneda ? TextInputType.number : TextInputType.text,
          textCapitalization:
              mayus ? TextCapitalization.characters : TextCapitalization.sentences,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          inputFormatters: [
            if (moneda) CurrencyInputFormatter(),
            if (mayus) UpperCaseFormatter(),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.bordeInput),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.bordeInput),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.oscuro, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelCampo extends StatelessWidget {
  const _LabelCampo(this.text, this.requerido);
  final String text;
  final bool requerido;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF57534E),
        ),
        children: [
          if (requerido)
            const TextSpan(text: ' *', style: TextStyle(color: AppColors.rojo)),
        ],
      ),
    );
  }
}
