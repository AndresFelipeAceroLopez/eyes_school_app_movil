import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// The student's ID card.
///
/// The QR encodes exactly what the web panel encodes: the plain
/// `codigo_estudiante`. It is rendered on the device rather than fetched as an
/// image, so it works with no signal — which is the whole point of carrying it
/// on a phone.
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final code = session?.studentCode ?? session?.user.code;

    return Scaffold(
      backgroundColor: AppColors.headerGradient.first,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Mi carné'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Center(
        child: code == null || code.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: EmptyState(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Sin código asignado',
                  message: session?.bootstrapWarning ??
                      'Tu cuenta todavía no tiene un código de estudiante.',
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: code,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.textPrimary,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(session?.user.name ?? '',
                              style: AppTextStyles.h3, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(code, style: AppTextStyles.bodyMuted),
                          if (session?.user.grade != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              [session!.user.grade, session.user.jornada]
                                  .whereType<String>()
                                  .join(' · '),
                              style: AppTextStyles.caption,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Muestra este código para registrar tu asistencia.',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 44),
                      child: Row(
                        children: [
                          const Icon(Icons.brightness_6_rounded,
                              size: 16, color: Colors.white54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sube el brillo de la pantalla para que el escáner '
                              'lea el código más rápido.',
                              style: AppTextStyles.caption.copyWith(color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
