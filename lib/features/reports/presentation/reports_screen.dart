import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/dashboard/domain/dashboard.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';

/// Reports, read-only: list, state and authenticated download.
///
/// Generating a report is a desktop flow and stays in the web panel; what a
/// phone is good for is checking whether one finished and opening it.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportesProvider);

    return SimpleHeaderScaffold(
      title: 'Reportes',
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reportesProvider),
        child: reportsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(children: [
            ErrorView(error: error, onRetry: () => ref.invalidate(reportesProvider)),
          ]),
          data: (reports) {
            if (reports.isEmpty) {
              return ListView(children: const [
                EmptyState(
                  icon: Icons.description_outlined,
                  title: 'Sin reportes generados',
                  message: 'Los reportes se generan desde el panel web y '
                      'aparecerán aquí para consulta y descarga.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: reports.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Los reportes se generan desde el panel web.',
                      style: AppTextStyles.caption,
                    ),
                  );
                }
                return _ReportCard(report: reports[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});

  final Report report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _downloading = false;

  (Color, Color) get _stateColors {
    final report = widget.report;
    if (report.isReady) return (AppColors.tealDark, AppColors.statusActiveBg);
    if (report.isFailed) return (AppColors.pink, const Color(0xFFFFE7EC));
    return (AppColors.orange, const Color(0xFFFCEEDD));
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/reporte_${widget.report.id}.pdf';
      await ref.read(reportesApiProvider).downloadFile(
            reportId: widget.report.id,
            savePath: path,
          );
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        messenger.showSnackBar(const SnackBar(
          content: Text('El archivo se descargó pero no pudimos abrirlo.'),
        ));
      }
    } on AppFailure catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppColors.pink,
      ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final (color, background) = _stateColors;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title ?? 'Reporte ${report.id}',
                      style: AppTextStyles.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        report.type,
                        if (report.generatedAt != null)
                          Formatters.dateShort(report.generatedAt!),
                      ].join(' · '),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status,
                  style: AppTextStyles.caption
                      .copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (report.description != null) ...[
            const SizedBox(height: 10),
            Text(report.description!,
                style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (report.isReady) ...[
            const Divider(height: 22, color: AppColors.divider),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _downloading ? null : _download,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_downloading ? 'Descargando…' : 'Descargar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
