import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/format.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/estados.dart';
import 'models/evento.dart';
import 'models/tramite.dart';

/// CRUD y lógica de negocio de los trámites sobre Firestore.
/// Cada acción que cambia el dinero o el estado deja un evento en el historial.
class TramitesRepository {
  TramitesRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final AuthRepository _auth;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('tramites');

  /// Trámites visibles: el admin ve todos; los demás solo los suyos.
  Stream<List<Tramite>> watchTramites({
    required String uid,
    required bool esAdmin,
  }) {
    Query<Map<String, dynamic>> q = _col;
    if (!esAdmin) q = q.where('ownerUid', isEqualTo: uid);
    return q.snapshots().map((s) {
      final lista = s.docs.map(Tramite.fromDoc).toList();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  Stream<List<Evento>> watchEventos(String tramiteId) => _col
      .doc(tramiteId)
      .collection('eventos')
      .orderBy('sello', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Evento.fromDoc).toList());

  Map<String, dynamic> _evento(String tipo, String texto, String ownerUid) =>
      Evento.toCreate(
        tipo: tipo,
        texto: texto,
        autorUid: _auth.uid,
        autorNombre: _auth.nombre,
        ownerUid: ownerUid,
      );

  /// Sufijo del texto de un abono según el saldo restante.
  String _sufijoSaldo(int valor, int saldo) {
    if (valor <= 0) return '';
    return saldo == 0 ? ' (pago completo)' : ' · queda debiendo ${cop(saldo)}';
  }

  /// Crea un trámite + evento de creación (+ abono inicial si aplica).
  /// El dueño es quien lo crea.
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
  }) async {
    final nombre = _auth.nombre;
    final owner = _auth.uid;
    final ref = _col.doc();
    final batch = _db.batch();

    batch.set(ref, {
      'fecha': Timestamp.fromDate(fecha),
      'placa': placa.toUpperCase().trim(),
      'tramite': tramite,
      'cliente': cliente.trim(),
      'sitio': sitio,
      'valor': valor,
      'recibido': recibido,
      'estado': estado,
      'obs': obs.trim(),
      'gestor': nombre,
      'ownerUid': owner,
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });

    final eventos = ref.collection('eventos');
    batch.set(eventos.doc(),
        _evento('creacion', 'Trámite creado por $nombre', owner));

    if (recibido > 0) {
      final saldo = math.max(0, valor - recibido);
      final texto =
          'Abono inicial de ${cop(recibido)}${_sufijoSaldo(valor, saldo)}';
      batch.set(eventos.doc(), _evento('pago', texto, owner));
    }

    await batch.commit();
  }

  /// Registra un abono sumándolo a lo recibido (transacción para evitar choques).
  Future<void> registrarAbono(String tramiteId, int monto) async {
    if (monto <= 0) return;
    final ref = _col.doc(tramiteId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final t = Tramite.fromDoc(snap);
      final nuevoRecibido = t.recibido + monto;
      final nuevoSaldo = math.max(0, t.valor - nuevoRecibido);
      final texto =
          'Abono de ${cop(monto)}${_sufijoSaldo(t.valor, nuevoSaldo)}';
      tx.update(ref, {
        'recibido': nuevoRecibido,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      tx.set(ref.collection('eventos').doc(),
          _evento('pago', texto, t.ownerUid));
    });
  }

  /// Marca el trámite como pagado por completo (recibido = valor).
  Future<void> pagoCompleto(String tramiteId) async {
    final ref = _col.doc(tramiteId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final t = Tramite.fromDoc(snap);
      if (t.saldo <= 0) return;
      tx.update(ref, {
        'recibido': t.valor,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      tx.set(
        ref.collection('eventos').doc(),
        _evento('pago', 'Pago completado · abono final de ${cop(t.saldo)}',
            t.ownerUid),
      );
    });
  }

  /// Cambia el estado dejando registro "Anterior → Nuevo".
  Future<void> cambiarEstado(String tramiteId, String nuevoEstado) async {
    final ref = _col.doc(tramiteId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final t = Tramite.fromDoc(snap);
      if (t.estado == nuevoEstado) return;
      final texto =
          '${estadoInfo(t.estado).label} → ${estadoInfo(nuevoEstado).label}';
      tx.update(ref, {
        'estado': nuevoEstado,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      tx.set(ref.collection('eventos').doc(),
          _evento('estado', texto, t.ownerUid));
    });
  }

  /// Reasigna un trámite a otro dueño (solo admin, validado por reglas).
  Future<void> reasignar(
      String tramiteId, String nuevoOwnerUid, String nuevoNombre) async {
    final ref = _col.doc(tramiteId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final t = Tramite.fromDoc(snap);
      if (t.ownerUid == nuevoOwnerUid) return;
      tx.update(ref, {
        'ownerUid': nuevoOwnerUid,
        'gestor': nuevoNombre,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      tx.set(
        ref.collection('eventos').doc(),
        _evento('reasignacion', 'Reasignado a $nuevoNombre', nuevoOwnerUid),
      );
    });
  }

  /// Mueve TODOS los trámites de un dueño a otro (caso "correo nuevo").
  /// Devuelve cuántos se movieron.
  Future<int> moverTodos(
      String fromUid, String toUid, String toNombre) async {
    if (fromUid == toUid) return 0;
    final snap = await _col.where('ownerUid', isEqualTo: fromUid).get();
    if (snap.docs.isEmpty) return 0;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'ownerUid': toUid,
        'gestor': toNombre,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      batch.set(
        doc.reference.collection('eventos').doc(),
        _evento('reasignacion', 'Reasignado a $toNombre', toUid),
      );
    }
    await batch.commit();
    return snap.docs.length;
  }
}
