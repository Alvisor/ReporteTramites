import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Niveles de tamaño de fuente disponibles (accesibilidad).
class NivelFuente {
  final String label;
  final double escala;
  const NivelFuente(this.label, this.escala);
}

const nivelesFuente = <NivelFuente>[
  NivelFuente('Normal', 1.0),
  NivelFuente('Grande', 1.2),
  NivelFuente('Muy grande', 1.45),
  NivelFuente('Máxima', 1.7),
];

/// Maneja la escala de texto elegida por el usuario, persistida en el dispositivo.
class SettingsCubit extends Cubit<double> {
  SettingsCubit(this._prefs) : super(_prefs.getDouble(_key) ?? 1.2);

  final SharedPreferences _prefs;
  static const _key = 'text_scale';

  void setEscala(double escala) {
    _prefs.setDouble(_key, escala);
    emit(escala);
  }
}
