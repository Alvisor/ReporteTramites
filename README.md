# Mis Trámites — App de trámites vehiculares

App **Flutter** para gestionar trámites vehiculares del negocio familiar (papá y mamá),
con base de datos en la nube **Firebase Firestore** (gratis), login compartido y respaldo
automático. Portada del prototipo en React.

## Qué hace

- Lista de trámites con resumen automático de **Recibido** y **Por cobrar**.
- Búsqueda (placa/cliente/trámite) y filtros por estado.
- Detalle con **Acciones** (abonos, pago completo, cambio de estado) e **Historial**
  inmutable (quién hizo qué y cuándo).
- Nuevo trámite con catálogos autoalimentados (tipos y sitios) compartidos.
- Login individual (papá/mamá) sobre los mismos datos; offline + sincronización.

## Arquitectura

- Flutter + `flutter_bloc` (Cubits) + `get_it`.
- Firebase: `firebase_auth`, `cloud_firestore` (offline integrado), `firebase_core`.
- Capas: `lib/core/` (tema, utils, DI) y `lib/features/` (auth, tramites).

### Modelo de datos (Firestore)

| Colección | Campos |
|---|---|
| `tramites/{id}` | fecha, placa, tramite, cliente, sitio, valor, recibido, estado, obs, gestor, creadoEn, actualizadoEn |
| `tramites/{id}/eventos/{id}` | tipo (creacion/pago/estado), texto, sello, autorUid, autorNombre — **inmutable** |
| `catalogos/{tramites\|sitios}` | items: string[] |
| `usuarios/{uid}` | nombre, rol (opcional; la atribución usa el displayName de Auth) |

---

## Puesta en marcha (una sola vez)

> Requiere tu cuenta de Google. Los comandos interactivos (login) ejecútalos tú; en
> Claude Code puedes usar el prefijo `!` para correrlos en la sesión.

### 1. Iniciar sesión en Firebase

```bash
firebase login
```

### 2. Crear el proyecto y conectarlo a la app

```bash
# Crea el proyecto (elige un ID único, p. ej. mis-tramites-familia)
firebase projects:create mis-tramites-familia --display-name "Mis Trámites"

# Genera lib/firebase_options.dart y registra las apps Android/Web
flutterfire configure --project=mis-tramites-familia --platforms=android,web
```

`flutterfire configure` **sobrescribe** el placeholder `lib/firebase_options.dart`.

### 3. Habilitar autenticación y crear los usuarios

En la **consola de Firebase** → *Authentication* → *Sign-in method*:
1. Habilita **Correo electrónico/contraseña**.
2. En *Users*, crea dos usuarios (papá y mamá) con su correo y contraseña.
3. En cada usuario, define el **Nombre para mostrar** como `Papá` / `Mamá`
   (eso es lo que aparece en el historial como autor).

### 4. Crear la base de datos y publicar las reglas

En la consola → *Firestore Database* → **Crear base de datos** (modo producción).
Luego, desde la raíz del repo:

```bash
firebase deploy --only firestore:rules --project=mis-tramites-familia
```

### 5. Correr la app

```bash
flutter pub get
flutter run            # en un emulador o teléfono conectado
```

---

## Compilar y distribuir el APK (sin tienda)

```bash
flutter build apk --release
# Resultado: build/app/outputs/flutter-apk/app-release.apk
```

Envía ese `.apk` por WhatsApp/Drive/enlace a los teléfonos de tus padres; lo instalan una
vez (Android pedirá permitir "instalar apps de orígenes desconocidos"). Para actualizar,
envías un APK nuevo. *(Opcional: usar **Firebase App Distribution** para gestionar testers
y avisos de versión nueva.)*

> Web (respaldo): `flutter build web --release`.

---

## Recuperación ante pérdida o formateo del teléfono

Los datos viven en Firestore, atados a la **cuenta**, no al teléfono. Si se pierde,
formatea o cambia un equipo: instala el APK en el nuevo, inicia sesión y **toda la
información vuelve sincronizada**. Como dueño del proyecto Firebase, puedes en cualquier
momento ver/editar/exportar datos en la consola, gestionar usuarios o conectar una app
nueva al mismo proyecto.

---

## Respaldo automático (gratis)

`scripts/backup/` + `.github/workflows/backup.yml` exportan Firestore a JSON a diario
mediante GitHub Actions (sin necesidad del plan Blaze de Firebase).

Configuración:
1. Consola Firebase → *Configuración del proyecto* → *Cuentas de servicio* →
   **Generar nueva clave privada** (descarga el JSON).
2. En el repo de GitHub → *Settings* → *Secrets and variables* → *Actions* → crea el
   secreto `FIREBASE_SERVICE_ACCOUNT` y pega **todo el contenido** del JSON.
3. Listo: corre cada día (o manualmente desde la pestaña *Actions*) y guarda los respaldos
   en `backups/`.

Respaldo manual local:

```bash
cd scripts/backup && npm install
GOOGLE_APPLICATION_CREDENTIALS=clave.json npm run export
```

---

## Pruebas y calidad

```bash
flutter analyze
flutter test
```
