import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';

/// Downloads and opens the PDF report card.
///
/// The endpoint requires the bearer header, so `url_launcher` cannot fetch it:
/// the bytes come down through Dio, land in the temp directory and are then
/// handed to the system viewer (or to the share sheet, which is how a guardian
/// forwards it).
class ReportCardDownloader {
  const ReportCardDownloader._();

  static Future<void> run(
    BuildContext context,
    WidgetRef ref, {
    required int studentId,
    required String studentName,
    bool share = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final progress = ValueNotifier<double?>(null);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProgressDialog(progress: progress),
    );

    try {
      final directory = await getTemporaryDirectory();
      final safeName = studentName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final path = '${directory.path}/boletin_$safeName.pdf';

      await ref.read(academicRepositoryProvider).downloadReportCard(
            studentId: studentId,
            savePath: path,
            onProgress: (received, total) {
              progress.value = total <= 0 ? null : received / total;
            },
          );

      if (context.mounted) Navigator.of(context).pop();

      if (share) {
        await Share.shareXFiles(
          [XFile(path, mimeType: 'application/pdf')],
          text: 'Boletín de $studentName',
        );
        return;
      }

      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        messenger.showSnackBar(SnackBar(
          content: Text(
            'El boletín se descargó pero no encontramos una app para abrir PDF.',
          ),
          backgroundColor: AppColors.orange,
        ));
      }
    } on AppFailure catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppColors.pink,
      ));
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('No pudimos guardar el boletín en este dispositivo.'),
        backgroundColor: AppColors.pink,
      ));
    } finally {
      progress.dispose();
    }
  }
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog({required this.progress});

  final ValueNotifier<double?> progress;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (context, value, _) => Column(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 3,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Descargando boletín…', style: AppTextStyles.body),
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${(value * 100).round()}%',
                        style: AppTextStyles.caption),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
