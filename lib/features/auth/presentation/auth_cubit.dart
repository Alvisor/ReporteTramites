import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserProfile? perfil;
  final bool cargando;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.perfil,
    this.cargando = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? perfil,
    bool? cargando,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user,
        perfil: perfil,
        cargando: cargando ?? this.cargando,
        error: error,
      );
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState()) {
    _sub = _repo.changes.listen(_onUser);
  }

  final AuthRepository _repo;
  late final StreamSubscription<User?> _sub;

  Future<void> _onUser(User? user) async {
    if (user == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }
    // Autenticado: cargamos el perfil/rol antes de dejar entrar.
    emit(AuthState(status: AuthStatus.authenticated, user: user));
    try {
      final perfil = await _repo.cargarPerfil();
      emit(AuthState(
          status: AuthStatus.authenticated, user: user, perfil: perfil));
    } catch (_) {
      // Si falla la carga del perfil, entra como usuario normal con su nombre.
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
        perfil: UserProfile(
          uid: user.uid,
          nombre: _repo.nombre,
          esAdmin: false,
        ),
      ));
    }
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(cargando: true, error: null));
    try {
      await _repo.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(cargando: false, error: _mensaje(e.code)));
    } catch (_) {
      emit(state.copyWith(
          cargando: false, error: 'Error inesperado. Intenta de nuevo.'));
    }
  }

  Future<void> logout() => _repo.signOut();

  String _mensaje(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Correo inválido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      default:
        return 'No se pudo iniciar sesión.';
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
