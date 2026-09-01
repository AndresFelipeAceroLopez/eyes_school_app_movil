import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/roster_student.dart';
import '../../providers/data_providers.dart';

class GradeEntryScreen extends ConsumerStatefulWidget {
  const GradeEntryScreen({super.key, required this.group, required this.subject});

  final String group;
  final String subject;

  @override
  ConsumerState<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends ConsumerState<GradeEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String studentId) =>
      _controllers.putIfAbsent(studentId, () => TextEditingController());

  Future<void> _save(List<RosterStudent> roster) async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _saving = false);
    final graded = roster.where((s) => (_controllers[s.id]?.text ?? '').isNotEmpty).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notas guardadas para $graded de ${roster.length} estudiantes.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(rosterForGroupProvider(widget.group));

    return SimpleHeaderScaffold(
      title: '${widget.subject} · ${widget.group}',
      body: rosterAsync.when(
        data: (roster) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                itemCount: roster.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final student = roster[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        AvatarCircle(name: student.name, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(student.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(
                          width: 64,
                          child: TextField(
                            controller: _controllerFor(student.id),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,1}$'))],
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '0.0',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              fillColor: AppColors.background,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryGradientButton(
                label: 'Guardar notas',
                loading: _saving,
                onPressed: () => _save(roster),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudo cargar el listado.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}
