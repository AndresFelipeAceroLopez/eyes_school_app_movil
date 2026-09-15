import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_card.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/novedades/domain/novedad.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_form_screen.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:eyes_school/core/utils/formatters.dart';

/// The teacher's news tray, filterable by state. Resolving a novedad is the
/// one write it offers beyond creating a new one.
class TeacherNovedadesScreen extends ConsumerStatefulWidget {
  const TeacherNovedadesScreen({super.key});

  @override
  ConsumerState<TeacherNovedadesScreen> createState() => _TeacherNovedadesScreenState();
}

class _TeacherNovedadesScreenState extends ConsumerState<TeacherNovedadesScreen> {
  NovedadStatus? _estado = NovedadStatus.pending;

  @override
  Widget build(BuildContext context) {
    final novedadesAsync = ref.watch(teacherNovedadesProvider(_estado));

    return SimpleHeaderScaffold(
      title: 'Novedades',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NovedadFormScreen()),
          );
          ref.invalidate(teacherNovedadesProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                _filterChip('Pendientes', NovedadStatus.pending),
                const SizedBox(width: 8),
                _filterChip('Completadas', NovedadStatus.done),
                const SizedBox(width: 8),
                _filterChip('Todas', null),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(teacherNovedadesProvider),
              child: novedadesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ListView(children: [
                  ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(teacherNovedadesProvider),
                  ),
                ]),
                data: (novedades) {
                  if (novedades.isEmpty) {
                    return ListView(children: [
                      EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: _estado == NovedadStatus.pending
                            ? 'No hay novedades pendientes'
                            : 'Sin novedades',
                        message: 'Registra una novedad con el botón «Nueva».',
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                    itemCount: novedades.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => NovedadCard(
                      novedad: novedades[index],
                      onTap: () => _openDetail(novedades[index]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, NovedadStatus? value) {
    final selected = _estado == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _estado = value),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.indigo : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(Novedad novedad) async {
    final action = TextEditingController(text: novedad.action ?? '');
    final resolve = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(novedad.title, style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text('${novedad.studentName} · ${Formatters.timeAgo(novedad.date)}',
                style: AppTextStyles.caption),
            const SizedBox(height: 16),
            if (novedad.description != null)
              Text(novedad.description!, style: AppTextStyles.body),
            const SizedBox(height: 18),
            if (!novedad.resolved) ...[
              Text('Acción tomada', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: action,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '¿Qué se hizo al respecto?'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Marcar como completada'),
                ),
              ),
            ] else
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.tealDark),
                  const SizedBox(width: 8),
                  Text('Novedad completada', style: AppTextStyles.body),
                ],
              ),
          ],
        ),
      ),
    );

    if (resolve != true || novedad.novedadId == null) {
      action.dispose();
      return;
    }
    try {
      await ref.read(academicRepositoryProvider).resolveNovedad(
            novedad.novedadId!,
            action: action.text.trim().isEmpty ? null : action.text.trim(),
          );
      ref.invalidate(teacherNovedadesProvider);
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      action.dispose();
    }
  }
}
