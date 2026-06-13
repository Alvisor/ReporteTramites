/// Perfil del usuario autenticado, incluyendo su rol.
class UserProfile {
  final String uid;
  final String nombre;
  final bool esAdmin;

  const UserProfile({
    required this.uid,
    required this.nombre,
    required this.esAdmin,
  });
}
