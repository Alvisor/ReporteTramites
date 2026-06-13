import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/settings/font_size_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _entrar() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(_email.text, _pass.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => mostrarTamanoFuente(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.grisTexto),
            icon: const Icon(Icons.format_size, size: 20),
            label: const Text('Letra'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.acento,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.directions_car,
                          color: AppColors.oscuro, size: 30),
                    ),
                    const SizedBox(height: 18),
                    Text('Mis Trámites',
                        style: AppTheme.serif(size: 26),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    const Text('Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grisTexto)),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: _dec('Correo', Icons.mail_outline),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: _dec('Contraseña', Icons.lock_outline),
                      onFieldSubmitted: (_) => _entrar(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                    ),
                    const SizedBox(height: 20),
                    BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state.error != null) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                                SnackBar(content: Text(state.error!)));
                        }
                      },
                      builder: (context, state) {
                        return FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.oscuro,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                          onPressed: state.cargando ? null : _entrar,
                          child: state.cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Entrar',
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.bordeInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.bordeInput),
        ),
      );
}
