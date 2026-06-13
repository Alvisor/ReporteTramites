import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/tramite.dart';
import '../data/tramites_repository.dart';

class TramitesState {
  final bool cargando;
  final List<Tramite> tramites;
  final String? error;

  const TramitesState({
    this.cargando = true,
    this.tramites = const [],
    this.error,
  });

  int get totalRecibido =>
      tramites.fold(0, (s, t) => s + t.recibido);
  int get totalPorCobrar =>
      tramites.fold(0, (s, t) => s + t.saldo);

  TramitesState copyWith({
    bool? cargando,
    List<Tramite>? tramites,
    String? error,
  }) =>
      TramitesState(
        cargando: cargando ?? this.cargando,
        tramites: tramites ?? this.tramites,
        error: error,
      );
}

class TramitesCubit extends Cubit<TramitesState> {
  TramitesCubit(this._repo, {required this.uid, required this.esAdmin})
      : super(const TramitesState()) {
    _sub = _repo.watchTramites(uid: uid, esAdmin: esAdmin).listen(
      (lista) => emit(TramitesState(cargando: false, tramites: lista)),
      onError: (_) =>
          emit(state.copyWith(cargando: false, error: 'No se pudieron cargar los trámites.')),
    );
  }

  final TramitesRepository _repo;
  final String uid;
  final bool esAdmin;
  late final StreamSubscription<List<Tramite>> _sub;

  Future<void> crear({
    required DateTime fecha,
    required String placa,
    required String tramite,
    required String cliente,
    required String sitio,
    required int valor,
    required int recibido,
    required String estado,
    required String obs,
  }) =>
      _repo.crear(
        fecha: fecha,
        placa: placa,
        tramite: tramite,
        cliente: cliente,
        sitio: sitio,
        valor: valor,
        recibido: recibido,
        estado: estado,
        obs: obs,
      );

  Future<void> abonar(String id, int monto) => _repo.registrarAbono(id, monto);
  Future<void> pagoCompleto(String id) => _repo.pagoCompleto(id);
  Future<void> cambiarEstado(String id, String estado) =>
      _repo.cambiarEstado(id, estado);
  Future<void> reasignar(String id, String ownerUid, String nombre) =>
      _repo.reasignar(id, ownerUid, nombre);
  Future<int> moverTodos(String fromUid, String toUid, String toNombre) =>
      _repo.moverTodos(fromUid, toUid, toNombre);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
