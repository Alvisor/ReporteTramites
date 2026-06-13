import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/injection.dart';
import 'core/settings/settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/tramites/presentation/tramites_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final prefs = await SharedPreferences.getInstance();

  String? errorInit;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    configureDependencies();
  } catch (e) {
    errorInit = e.toString();
  }

  runApp(MyApp(errorInit: errorInit, prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.errorInit, required this.prefs});
  final String? errorInit;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(prefs),
      child: MaterialApp(
        title: 'Mis Trámites',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) {
          final escala = context.watch<SettingsCubit>().state;
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(escala)),
            child: child!,
          );
        },
        home: errorInit != null
            ? _ErrorInicio(mensaje: errorInit!)
            : BlocProvider(
                create: (_) => AuthCubit(getIt<AuthRepository>()),
                child: const _Gate(),
              ),
      ),
    );
  }
}

/// Decide entre login y la app según el estado de autenticación.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.authenticated:
            if (state.perfil == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return TramitesPage(perfil: state.perfil!);
          case AuthStatus.unauthenticated:
            return const LoginPage();
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }
}

class _ErrorInicio extends StatelessWidget {
  const _ErrorInicio({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Firebase aún no está configurado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Ejecuta `firebase login` y luego `flutterfire configure` '
                '(ver README) y vuelve a abrir la app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(mensaje,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
