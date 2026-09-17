import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/services/update_service.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  final UpdateInfo updateInfo;

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Forzar a que elija una opción
      builder: (_) => UpdateDialog(updateInfo: info),
    );
  }

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      final service = ref.read(updateServiceProvider);
      await service.downloadAndInstallUpdate(
        downloadUrl: widget.updateInfo.downloadUrl!,
        onProgress: (p) {
          setState(() {
            _progress = p;
          });
        },
      );
      
      if (mounted) {
        context.pop(); // Close dialog on success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(Icons.system_update_rounded, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Actualización Disponible',
              style: AppTextStyles.h2,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'La versión ${widget.updateInfo.latestVersion} ya está lista para instalar.',
            style: AppTextStyles.body,
          ),
          if (widget.updateInfo.releaseNotes != null && widget.updateInfo.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.updateInfo.releaseNotes!,
                style: AppTextStyles.caption,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.pink),
            ),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.background,
              color: AppColors.teal,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${(_progress * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Más tarde',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Descargar e Instalar'),
          ),
        ],
      ],
    );
  }
}
