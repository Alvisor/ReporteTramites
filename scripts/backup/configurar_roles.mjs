// Configura los perfiles/roles en Firestore (colección 'usuarios') y migra los
// trámites existentes que no tengan dueño, asignándoselos al admin.
// Uso: GOOGLE_APPLICATION_CREDENTIALS=clave.json node configurar_roles.mjs
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync } from 'node:fs';

initializeApp({
  credential: cert(JSON.parse(readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'))),
});
const auth = getAuth();
const db = getFirestore();

const perfiles = [
  { email: 'alvisor.max@gmail.com', nombre: 'Manuel', rol: 'admin' },
  { email: 'manurodrigues1705@gmail.com', nombre: 'Papá', rol: 'normal' },
  { email: 'sofiro0829@gmail.com', nombre: 'Mamá', rol: 'normal' },
];

let adminUid = null;
for (const p of perfiles) {
  const u = await auth.getUserByEmail(p.email);
  await db.collection('usuarios').doc(u.uid).set(
    { nombre: p.nombre, rol: p.rol, email: p.email },
    { merge: true },
  );
  if (p.rol === 'admin') adminUid = u.uid;
  console.log(`Perfil: ${p.nombre} (${p.rol}) -> uid ${u.uid}`);
}

// Migración: trámites sin ownerUid pasan a ser del admin.
const snap = await db.collection('tramites').get();
let migrados = 0;
for (const doc of snap.docs) {
  if (!doc.data().ownerUid) {
    await doc.ref.update({ ownerUid: adminUid, gestor: 'Manuel' });
    migrados++;
  }
}
console.log(`Trámites migrados al admin: ${migrados}`);
console.log('Listo.');
