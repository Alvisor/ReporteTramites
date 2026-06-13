// Crea/actualiza los usuarios de la app en Firebase Auth con su displayName.
// Uso: GOOGLE_APPLICATION_CREDENTIALS=clave.json node crear_usuarios.mjs
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'node:fs';

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
initializeApp({ credential: cert(JSON.parse(readFileSync(keyPath, 'utf8'))) });
const auth = getAuth();

const usuarios = [
  { email: 'alvisor.max@gmail.com', password: 'AppClave2026', displayName: 'Manuel' },
  { email: 'manurodrigues1705@gmail.com', password: 'AppClave2026', displayName: 'Papá' },
  { email: 'sofiro0829@gmail.com', password: 'AppClave2026', displayName: 'Mamá' },
];

for (const u of usuarios) {
  try {
    const existing = await auth.getUserByEmail(u.email).catch(() => null);
    if (existing) {
      await auth.updateUser(existing.uid, {
        password: u.password,
        displayName: u.displayName,
      });
      console.log(`Actualizado: ${u.displayName} <${u.email}>`);
    } else {
      await auth.createUser({
        email: u.email,
        password: u.password,
        displayName: u.displayName,
        emailVerified: true,
      });
      console.log(`Creado: ${u.displayName} <${u.email}>`);
    }
  } catch (e) {
    console.error(`Error con ${u.email}: ${e.message}`);
  }
}
console.log('Listo.');
