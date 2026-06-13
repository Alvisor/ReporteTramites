// Exporta todas las colecciones de Firestore a un archivo JSON.
// Uso (local o en GitHub Actions):
//   GOOGLE_APPLICATION_CREDENTIALS=clave.json node export_firestore.mjs
// Requiere una cuenta de servicio de Firebase con permiso de lectura.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const keyJson = process.env.FIREBASE_SERVICE_ACCOUNT;
if (keyJson) {
  initializeApp({ credential: cert(JSON.parse(keyJson)) });
} else {
  // Usa GOOGLE_APPLICATION_CREDENTIALS apuntando a un archivo de clave.
  initializeApp();
}

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
