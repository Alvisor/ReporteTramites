// Exporta todas las colecciones de Firestore a un archivo JSON.
// Uso (local o en GitHub Actions):
//   GOOGLE_APPLICATION_CREDENTIALS=clave.json node export_firestore.mjs
// Requiere una cuenta de servicio de Firebase con permiso de lectura.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync } from 'node:fs';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// Credenciales: secreto FIREBASE_SERVICE_ACCOUNT (CI) o
// GOOGLE_APPLICATION_CREDENTIALS apuntando a un archivo de clave (local).
const keyJson = process.env.FIREBASE_SERVICE_ACCOUNT;
const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
let sa = null;
if (keyJson) sa = JSON.parse(keyJson);
else if (keyPath) sa = JSON.parse(readFileSync(keyPath, 'utf8'));

if (!sa) {
  console.error(
    'Falta la credencial. Define el secreto FIREBASE_SERVICE_ACCOUNT en GitHub ' +
    '(o GOOGLE_APPLICATION_CREDENTIALS en local).',
  );
  process.exit(1);
}

initializeApp({ credential: cert(sa), projectId: sa.project_id });

const db = getFirestore();

async function dumpCollection(ref) {
  const snap = await ref.get();
  const out = {};
  for (const doc of snap.docs) {
    out[doc.id] = { data: doc.data() };
    // Incluye subcolecciones (p.ej. tramites/{id}/eventos).
    const subs = await doc.ref.listCollections();
    if (subs.length) {
      out[doc.id].subcollections = {};
      for (const sub of subs) {
        out[doc.id].subcollections[sub.id] = await dumpCollection(sub);
      }
    }
  }
  return out;
}

async function main() {
  const root = await db.listCollections();
  const backup = { exportedAt: new Date().toISOString(), collections: {} };
  for (const col of root) {
    backup.collections[col.id] = await dumpCollection(col);
  }

  const date = backup.exportedAt.slice(0, 10);
  const dir = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'backups');
  await mkdir(dir, { recursive: true });
  const file = join(dir, `firestore-${date}.json`);
  await writeFile(file, JSON.stringify(backup, null, 2), 'utf8');
  console.log(`Respaldo escrito en ${file}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
