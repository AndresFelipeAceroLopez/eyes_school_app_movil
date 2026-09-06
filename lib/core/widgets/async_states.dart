import 'package:flutter/material.dart';

import '../../domain/failures/app_failure.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_gradient_button.dart';

/// Every data screen shows the same three states. These keep that consistent
/// without any screen having to know what a `DioException` is.

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.padding = const EdgeInsets.symmetric(vertical: 48)});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.indigo),
        ),
      ),
    );
  }
}

/// An error is never a dead end: it says what happened and offers the retry.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  static String messageOf(Object error) {
    if (error is AppFailure) return error.message;
    return 'No pudimos cargar la información. Intenta de nuevo.';
  }

  static IconData iconOf(Object error) => switch (error) {
        NetworkFailure() => Icons.wifi_off_rounded,
        ForbiddenFailure() => Icons.lock_outline_rounded,
        NotFoundFailure() => Icons.search_off_rounded,
        ServerFailure() => Icons.cloud_off_rounded,
        _ => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 20 : 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(iconOf(error), color: AppColors.textSecondary, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            messageOf(error),
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: PrimaryGradientButton(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 18, offset: Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

/// A thin bar the scanner and other write screens show while the device has
/// no connection, so the user knows their work is being queued, not lost.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.pendingCount = 0});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.orange.withValues(alpha: 0.16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pendingCount > 0
                  ? 'Sin conexión · $pendingCount registro(s) en cola'
                  : 'Sin conexión · los registros se guardan en el dispositivo',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
