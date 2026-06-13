import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

/// Acceso a Firebase Auth. La atribución (quién hizo qué) usa el displayName
/// del usuario ("Papá" / "Mamá"); si no está configurado, cae al email.
class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get changes => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  String get uid => _auth.currentUser?.uid ?? '';

  String get nombre {
    final u = _auth.currentUser;
    if (u == null) return 'Desconocido';
    final dn = u.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    return u.email ?? 'Usuario';
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<void> signOut() => _auth.signOut();

  /// Carga el perfil (nombre + rol) desde la colección `usuarios`.
  Future<UserProfile> cargarPerfil() async {
    final u = _auth.currentUser!;
    final doc = await _db.collection('usuarios').doc(u.uid).get();
    final data = doc.data();
    final nombreDoc = (data?['nombre'] as String?)?.trim();
    return UserProfile(
      uid: u.uid,
      nombre: (nombreDoc != null && nombreDoc.isNotEmpty) ? nombreDoc : nombre,
      esAdmin: data?['rol'] == 'admin',
    );
  }
}
