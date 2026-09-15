import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';

/// Creates a `NovedadOut`.
///
/// The student is picked from the local catalog rather than typed, because
/// the API needs an `id_estudiante` and a free-text name would not resolve.
/// The severity is not chosen here: it comes from the selected type
/// (`TipoNovedadOut.nivel_gravedad`), which is where the institution defines
/// it.
class NovedadFormScreen extends ConsumerStatefulWidget {
  const NovedadFormScreen({super.key, this.studentId, this.studentName});

  final int? studentId;
  final String? studentName;

  @override
  ConsumerState<NovedadFormScreen> createState() => _NovedadFormScreenState();
}

class _NovedadFormScreenState extends ConsumerState<NovedadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _actionController = TextEditingController();

  int? _studentId;
  String? _studentName;
  int? _typeId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId;
    _studentName = widget.studentName;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_studentId == null) {
      setState(() => _errorText = 'Selecciona el estudiante.');
      return;
    }
    if (_typeId == null) {
      setState(() => _errorText = 'Selecciona el tipo de novedad.');
      return;
    }
    final session = ref.read(currentSessionProvider);
    if (session == null) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await ref.read(academicRepositoryProvider).createNovedad(
            studentId: _studentId!,
            typeId: _typeId!,
            date: _date,
            description: _descriptionController.text.trim(),
            registeredBy: session.user.userId,
            action: _actionController.text.trim().isEmpty
                ? null
                : _actionController.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(teacherNovedadesProvider);
      ref.invalidate(adminNovedadesProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Novedad registrada para ${_studentName ?? 'el estudiante'}.'),
        backgroundColor: AppColors.tealDark,
      ));
      Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(novedadTypesProvider);

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
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickStudent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (_studentName != null)
                        AvatarCircle(name: _studentName!, radius: 16)
                      else
                        const Icon(Icons.person_search_rounded,
                            color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _studentName ?? 'Buscar estudiante',
                          style: _studentName == null
                              ? AppTextStyles.bodyMuted
                              : AppTextStyles.body,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Tipo de novedad', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              typesAsync.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (_, _) => Text(
                  'No pudimos cargar los tipos de novedad.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.pink),
                ),
                data: (types) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types
                      .map((t) => ChoiceChip(
                            label: Text(t.name),
                            selected: _typeId == t.id,
                            onSelected: (_) =>
                                setState(() => _typeId = t.id),
                            selectedColor: AppColors.indigo,
                            labelStyle: AppTextStyles.caption.copyWith(
                              color: _typeId == t.id
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              // Severity is a property of the type, not a free choice: this
              // mirrors what the institution configured in `/tipos-novedad`.
              typesAsync.maybeWhen(
                data: (types) {
                  final selected =
                      types.where((t) => t.id == _typeId).firstOrNull;
                  if (selected == null) return const SizedBox.shrink();
                  final severity = _severityColor(selected.severity);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: severity.$2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(color: severity.$1, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Gravedad ${selected.severity.label}'
                            '${selected.requiresAction ? ' · requiere acción' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: severity.$1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 18),
              Text('Fecha', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 180)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(Formatters.todayLong(_date), style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Descripción', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Detalla lo ocurrido...'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Describe la novedad.' : null,
              ),
              const SizedBox(height: 18),
              Text('Acción tomada (opcional)', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextFormField(
                controller: _actionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '¿Qué se hizo al respecto?'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(_errorText!, style: AppTextStyles.body.copyWith(color: AppColors.pink)),
              ],
              const SizedBox(height: 24),
              PrimaryGradientButton(
                label: 'Guardar novedad',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _severityColor(NovedadSeverity nivel) => switch (nivel) {
        NovedadSeverity.low => (AppColors.blue, AppColors.roleStudentBg),
        NovedadSeverity.medium => (AppColors.orange, const Color(0xFFFCEEDD)),
        NovedadSeverity.high => (AppColors.pink, const Color(0xFFFFE7EC)),
        NovedadSeverity.critical => (AppColors.pink, const Color(0xFFFFD9E1)),
      };

  Future<void> _pickStudent() async {
    final picked = await showModalBottomSheet<StudentIdentity>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _StudentPicker(),
    );
    if (picked != null) {
      setState(() {
        _studentId = picked.studentId;
        _studentName = picked.displayName.isEmpty
            ? picked.code
            : picked.displayName;
        _errorText = null;
      });
    }
  }
}

/// Searches the local student catalog, so it works without signal too.
class _StudentPicker extends ConsumerStatefulWidget {
  const _StudentPicker();

  @override
  ConsumerState<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends ConsumerState<_StudentPicker> {
  final _controller = TextEditingController();
  List<StudentIdentity> _results = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final catalog = ref.read(studentCatalogProvider);
    try {
      await catalog.ensureReady();
    } catch (_) {
      // Fall through: whatever is cached is still searchable.
    }
    if (!mounted) return;
    setState(() {
      _results = catalog.search(query);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buscar estudiante', style: AppTextStyles.h2),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'Nombre o código',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text('Sin resultados.', style: AppTextStyles.bodyMuted),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final student = _results[index];
                          final name = student.displayName.isEmpty
                              ? student.code
                              : student.displayName;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: AvatarCircle(name: name, radius: 20),
                            title: Text(name, style: AppTextStyles.body),
                            subtitle:
                                Text(student.code, style: AppTextStyles.caption),
                            onTap: () => Navigator.of(context).pop(student),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
