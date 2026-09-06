import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/attendance_queue.dart';
import '../../domain/entities/attendance_record.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../providers/repository_providers.dart';
import '../../domain/value_objects/attendance.dart';

/// The offline queue, made visible.
///
/// Nothing captured on this device disappears silently: what could not reach
/// the API is listed here so a person can retry it, correct it or discard it
/// on purpose.
class PendingAttendanceScreen extends ConsumerWidget {
  const PendingAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(attendanceQueueProvider);
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;

    final waiting = queue.items.where((i) => i.isWaiting).toList();
    final failed = queue.failed;
    final sent = queue.items.where((i) => i.sync == SyncState.sent).toList();

    return SimpleHeaderScaffold(
      title: 'Pendientes',
      actions: [
        if (queue.isFlushing)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            tooltip: 'Sincronizar ahora',
            onPressed: () => queue.flush(force: true),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: () => queue.flush(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            if (!online) ...[
              const OfflineBanner(),
              const SizedBox(height: 16),
            ],
            _Summary(waiting: waiting.length, failed: failed.length, sent: sent.length),
            if (failed.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Con error (${failed.length})',
                trailingText: 'Reintentar todos',
                onTrailingTap: queue.retryAll,
              ),
              const SizedBox(height: 12),
              for (final item in failed)
                _PendingTile(item: item, queue: queue),
            ],
            if (waiting.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(title: 'En cola (${waiting.length})'),
              const SizedBox(height: 12),
              for (final item in waiting) _PendingTile(item: item, queue: queue),
            ],
            if (sent.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Sincronizados (${sent.length})',
                trailingText: 'Limpiar',
                onTrailingTap: queue.pruneSettled,
              ),
              const SizedBox(height: 12),
              for (final item in sent.take(20)) _PendingTile(item: item, queue: queue),
            ],
            if (queue.items.isEmpty)
              const EmptyState(
                icon: Icons.cloud_done_rounded,
                title: 'Todo sincronizado',
                message: 'No hay registros de asistencia esperando envío.',
              ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.waiting, required this.failed, required this.sent});

  final int waiting;
  final int failed;
  final int sent;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          _Metric(value: waiting, label: 'En cola', color: AppColors.blue),
          _Metric(value: failed, label: 'Con error', color: AppColors.pink),
          _Metric(value: sent, label: 'Enviados', color: AppColors.tealDark),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: AppTextStyles.statValue.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.item, required this.queue});

  final PendingAttendance item;
  final AttendanceQueue queue;

  (Color, String) get _badge => switch (item.sync) {
        SyncState.sent => (AppColors.tealDark, 'Enviado'),
        SyncState.failed => (AppColors.pink, 'Error'),
        SyncState.sending => (AppColors.blue, 'Enviando'),
        SyncState.duplicate => (AppColors.orange, 'Duplicado'),
        SyncState.pending => (AppColors.textSecondary, 'En cola'),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.studentName.isEmpty ? 'Estudiante ${item.studentId}' : item.studentName,
                    style: AppTextStyles.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.caption
                        .copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.state.label} · ${item.kind.label} · '
              '${Formatters.dateNumeric(item.date)}',
              style: AppTextStyles.caption,
            ),
            if (item.lastError != null) ...[
              const SizedBox(height: 6),
              Text(
                item.lastError!,
                style: AppTextStyles.caption.copyWith(color: AppColors.pink),
              ),
            ],
            if (item.attempts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Intentos: ${item.attempts}/${AttendanceQueue.maxAttempts}',
                  style: AppTextStyles.caption,
                ),
              ),
            if (!item.isSettled || item.sync == SyncState.failed) ...[
              const Divider(height: 22, color: AppColors.divider),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => queue.retry(item.localId),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reintentar'),
                  ),
                  TextButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Descartar',
                    onPressed: () => _confirmDiscard(context),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.pink),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final state = await showModalBottomSheet<AttendanceState>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cambiar estado', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            for (final option in AttendanceState.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label, style: AppTextStyles.body),
                trailing: option == item.state
                    ? const Icon(Icons.check_rounded, color: AppColors.indigo)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (state != null) await queue.edit(item.localId, state: state);
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Descartar registro', style: AppTextStyles.h3),
        content: Text(
          'Este registro no se enviará al servidor y se borrará del dispositivo.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Descartar',
                style: AppTextStyles.link.copyWith(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (confirmed == true) await queue.discard(item.localId);
  }
}
