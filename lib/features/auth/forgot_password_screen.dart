import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/failures/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../../providers/repository_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// The API answers neutrally on purpose: it never reveals whether the
  /// address exists. The UI keeps that promise and always reports success.
  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_emailController.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } on AppFailure catch (e) {
      // Only transport problems surface; a 404 would leak account existence.
      if (mounted) {
        setState(() => _errorText = e is NetworkFailure ? e.message : null);
        if (_errorText == null) setState(() => _sent = true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerGradient.first,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                  ),
                  Text('Recuperar contraseña',
                      style: AppTextStyles.h3.copyWith(color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.roleAdminBg,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.mark_email_read_outlined,
                              size: 36, color: AppColors.tealDark),
                        ),
                        const SizedBox(height: 20),
                        Text('Revisa tu correo', style: AppTextStyles.h1),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                          style: AppTextStyles.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Correo electrónico', style: AppTextStyles.caption),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'tu@correo.com',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 20),
                        PrimaryGradientButton(
                          label: 'Enviar enlace',
                          loading: _sending,
                          onPressed: _send,
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorText!,
                            style: AppTextStyles.body.copyWith(color: AppColors.pink),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (_sent) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.statusActiveBg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.tealDark),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Enlace enviado',
                                          style: AppTextStyles.body
                                              .copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Si existe una cuenta con ese correo, recibirás '
                                        'las instrucciones para restablecer tu contraseña.',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                          child: Text('Volver al inicio de sesión', style: AppTextStyles.link),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
