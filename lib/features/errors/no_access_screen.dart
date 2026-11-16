import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/eye_logo.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// Reached in two situations: a route that belongs to another role, and an
/// inactive account (`MeResponse.estado` is false). The API sends the same
/// `false` for an account still awaiting validation and for one an admin
/// deactivated (N-31), so the text has to be true for both.
class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final inactive = session != null && !session.user.isActive;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.headerGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EyeLogo(size: 84),
                const SizedBox(height: 28),
                Text(
                  inactive ? 'Cuenta inactiva' : 'Sin acceso',
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  inactive
                      ? 'Tu cuenta no está activa. Si te registraste hace poco, '
                            'un administrador debe aprobarla; si ya la usabas, '
                            'comunícate con la institución.'
                      : 'Esta sección no está disponible para tu rol.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                if (!inactive && session != null)
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryGradientButton(
                      label: 'Volver a mi inicio',
                      icon: Icons.home_rounded,
                      onPressed: () => context.go(session.role.homePath),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.read(sessionProvider.notifier).logout(),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  label: Text(
                    'Cerrar sesión',
                    style: AppTextStyles.body.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
