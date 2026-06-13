import 'package:cloud_firestore/cloud_firestore.dart';

/// Un usuario de la app (para listar al reasignar trámites).
class Usuario {
  final String uid;
  final String nombre;
  final String rol;
  const Usuario({required this.uid, required this.nombre, required this.rol});

  bool get esAdmin => rol == 'admin';
}

class UsuariosRepository {
  UsuariosRepository(this._db);
  final FirebaseFirestore _db;

  /// Lista todos los usuarios registrados (papá, mamá, admin).
  Future<List<Usuario>> listar() async {
    final snap = await _db.collection('usuarios').get();
    final lista = snap.docs
        .map((d) => Usuario(
              uid: d.id,
              nombre: (d.data()['nombre'] as String?) ?? 'Usuario',
              rol: (d.data()['rol'] as String?) ?? 'normal',
            ))
        .toList();
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }
}
