import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/novedad.dart';

class NovedadFormScreen extends StatefulWidget {
  const NovedadFormScreen({super.key});

  @override
  State<NovedadFormScreen> createState() => _NovedadFormScreenState();
}

class _NovedadFormScreenState extends State<NovedadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'Retraso académico';
  NovedadSeverity _severity = NovedadSeverity.medium;
  bool _saving = false;

  static const _types = [
    'Retraso académico',
    'Inasistencia injustificada',
    'Comportamiento',
    'Reconocimiento',
    'Otro',
  ];

  @override
  void dispose() {
    _studentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Novedad registrada para ${_studentController.text}.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleHeaderScaffold(
      title: 'Registrar novedad',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estudiante', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentController,
                decoration: const InputDecoration(hintText: 'Nombre del estudiante'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del estudiante.' : null,
              ),
              const SizedBox(height: 18),
              Text('Tipo de novedad', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types
                    .map((t) => ChoiceChip(
                          label: Text(t),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                          selectedColor: AppColors.indigo,
                          labelStyle: AppTextStyles.caption.copyWith(
                            color: _type == t ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              Text('Severidad', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SeverityChip(
                    label: 'Baja',
                    color: AppColors.blue,
                    selected: _severity == NovedadSeverity.low,
                    onTap: () => setState(() => _severity = NovedadSeverity.low),
                  ),
                  const SizedBox(width: 8),
                  _SeverityChip(
                    label: 'Media',
                    color: AppColors.orange,
                    selected: _severity == NovedadSeverity.medium,
                    onTap: () => setState(() => _severity = NovedadSeverity.medium),
                  ),
                  const SizedBox(width: 8),
                  _SeverityChip(
                    label: 'Alta',
                    color: AppColors.pink,
                    selected: _severity == NovedadSeverity.high,
                    onTap: () => setState(() => _severity = NovedadSeverity.high),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Descripción', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Detalla lo ocurrido...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe la novedad.' : null,
              ),
              const SizedBox(height: 24),
              PrimaryGradientButton(label: 'Guardar novedad', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.label, required this.color, required this.selected, required this.onTap});

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
