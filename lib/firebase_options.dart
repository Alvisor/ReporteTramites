// PLACEHOLDER — este archivo será SOBRESCRITO por `flutterfire configure`.
//
// Mientras no se configure Firebase, las constantes están vacías y la app
// mostrará un error al iniciar. Ejecuta (ver README) :
//   firebase login
//   flutterfire configure
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase aún no está configurado para esta plataforma. '
          'Ejecuta `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA-rw09_YQzdaJbgB5T1eVSAgBnwkeqJmA',
    appId: '1:448579551082:web:889d614b273c6d7211af13',
    messagingSenderId: '448579551082',
    projectId: 'mis-tramites-familia',
    authDomain: 'mis-tramites-familia.firebaseapp.com',
    storageBucket: 'mis-tramites-familia.firebasestorage.app',
    measurementId: 'G-CSS1D5GRWB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGewku3xVsr1T9cTnhAlVZsU025TWJ4UM',
    appId: '1:448579551082:android:9fa177226b7caa9d11af13',
    messagingSenderId: '448579551082',
    projectId: 'mis-tramites-familia',
    storageBucket: 'mis-tramites-familia.firebasestorage.app',
  );
}
