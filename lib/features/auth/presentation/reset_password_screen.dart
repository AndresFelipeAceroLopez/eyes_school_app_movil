import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/validators.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/providers/repository_providers.dart';

/// Entered through the deep link `eyesschool://reset?token=…`. The token can
/// also be pasted by hand, because a mail client that strips custom schemes
/// would otherwise leave the user stranded.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController =
      TextEditingController(text: widget.token ?? '');
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  bool _done = false;
  String? _errorText;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: _tokenController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (mounted) setState(() => _done = true);
    } on AppFailure catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                    onPressed: () => context.go('/login'),
                  ),
                  Text('Nueva contraseña',
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
                  child: _done ? _successBody() : _formBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.roleTeacherBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.violet),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Text('Restablecer contraseña', style: AppTextStyles.h1)),
          const SizedBox(height: 8),
          Text(
            'Pega el código que recibiste por correo y elige tu nueva contraseña.',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Text('Código de recuperación', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            validator: (v) => Validators.required(v, 'el código'),
          ),
          const SizedBox(height: 18),
          Text('Nueva contraseña', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: Validators.newPassword,
          ),
          const SizedBox(height: 18),
          Text('Confirmar contraseña', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded)),
            validator: (v) =>
                v == _passwordController.text ? null : 'Las contraseñas no coinciden.',
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Text(_errorText!, style: AppTextStyles.body.copyWith(color: AppColors.pink)),
          ],
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: 'Guardar contraseña',
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _successBody() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.statusActiveBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.check_rounded, size: 40, color: AppColors.tealDark),
        ),
        const SizedBox(height: 20),
        Text('Contraseña actualizada', style: AppTextStyles.h1, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Ya puedes ingresar con tu nueva contraseña.',
          style: AppTextStyles.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        PrimaryGradientButton(
          label: 'Ir al inicio de sesión',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
