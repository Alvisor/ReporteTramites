import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/tramites/data/catalogos_repository.dart';
import '../../features/tramites/data/tramites_repository.dart';
import '../../features/usuarios/data/usuarios_repository.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton(() => AuthRepository(getIt(), getIt()))
    ..registerLazySingleton(() => CatalogosRepository(getIt()))
    ..registerLazySingleton(() => UsuariosRepository(getIt()))
    ..registerLazySingleton(() => TramitesRepository(getIt(), getIt()));
}
