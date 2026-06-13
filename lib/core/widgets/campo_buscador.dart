import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Campo tipo "select" que al tocarlo abre un buscador con la lista filtrable
/// y la opción de agregar un valor nuevo (autoalimentado).
class CampoBuscador extends StatelessWidget {
  const CampoBuscador({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Toca para elegir o buscar',
    this.requerido = false,
    this.permitirNuevo = true,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool requerido;
  final bool permitirNuevo;

  @override
  Widget build(BuildContext context) {
    final tieneValor = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, requerido),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final r = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.fondo,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => _BuscadorSheet(
                titulo: label,
                items: items,
                permitirNuevo: permitirNuevo,
              ),
            );
            if (r != null && r.isNotEmpty) onChanged(r);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tieneValor ? AppColors.oscuro : AppColors.bordeInput,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tieneValor ? value! : hint,
                    style: TextStyle(
                      fontSize: 16,
                      color: tieneValor ? AppColors.oscuro : AppColors.grisSuave,
                      fontWeight:
                          tieneValor ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(Icons.unfold_more, color: AppColors.grisTexto),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BuscadorSheet extends StatefulWidget {
  const _BuscadorSheet({
    required this.titulo,
    required this.items,
    required this.permitirNuevo,
  });
  final String titulo;
  final List<String> items;
  final bool permitirNuevo;

  @override
  State<_BuscadorSheet> createState() => _BuscadorSheetState();
}

class _BuscadorSheetState extends State<_BuscadorSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final filtrados = q.isEmpty
        ? widget.items
        : widget.items.where((e) => e.toLowerCase().contains(q)).toList();
    final hayExacto =
        widget.items.any((e) => e.toLowerCase() == q && q.isNotEmpty);
    final mostrarNuevo = widget.permitirNuevo && q.isNotEmpty && !hayExacto;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titulo, style: AppTheme.serif(size: 19)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _q = v),
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Buscar…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.bordeInput),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.bordeInput),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
                  if (mostrarNuevo)
                    Card(
                      elevation: 0,
                      color: AppColors.acento.withValues(alpha: 0.18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.add_circle,
                            color: AppColors.oscuro),
                        title: Text('Agregar: "${normalizar(_q)}"',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        onTap: () => Navigator.pop(context, normalizar(_q)),
                      ),
                    ),
                  for (final item in filtrados)
                    ListTile(
                      title: Text(item, style: const TextStyle(fontSize: 16)),
                      onTap: () => Navigator.pop(context, item),
                    ),
                  if (filtrados.isEmpty && !mostrarNuevo)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Sin resultados',
                            style: TextStyle(color: AppColors.grisTexto)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.requerido);
  final String text;
  final bool requerido;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF57534E),
        ),
        children: [
          if (requerido)
            const TextSpan(
                text: ' *', style: TextStyle(color: AppColors.rojo)),
        ],
      ),
    );
  }
}
