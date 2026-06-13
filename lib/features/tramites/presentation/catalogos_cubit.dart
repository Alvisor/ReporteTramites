import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalogos_repository.dart';

class CatalogosState {
  final List<String> tramites;
  final List<String> sitios;
  const CatalogosState({this.tramites = const [], this.sitios = const []});

  CatalogosState copyWith({List<String>? tramites, List<String>? sitios}) =>
      CatalogosState(
        tramites: tramites ?? this.tramites,
        sitios: sitios ?? this.sitios,
      );
}

class CatalogosCubit extends Cubit<CatalogosState> {
  CatalogosCubit(this._repo) : super(const CatalogosState()) {
    _subT = _repo
        .watch('tramites')
        .listen((l) => emit(state.copyWith(tramites: l)));
    _subS =
        _repo.watch('sitios').listen((l) => emit(state.copyWith(sitios: l)));
  }

  final CatalogosRepository _repo;
  late final StreamSubscription<List<String>> _subT;
  late final StreamSubscription<List<String>> _subS;

  Future<void> agregarTramite(String v) => _repo.agregar('tramites', v);
  Future<void> agregarSitio(String v) => _repo.agregar('sitios', v);

  @override
  Future<void> close() {
    _subT.cancel();
    _subS.cancel();
    return super.close();
  }
}
