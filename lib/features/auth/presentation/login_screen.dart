import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/validators.dart';
import 'package:eyes_school/core/widgets/monster_mascot.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _errorText;

  /// Field-level messages coming from a 422 `HTTPValidationError`.
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorText = null;
      _fieldErrors = const {};
    });
    try {
      await ref.read(sessionProvider.notifier).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // A successful login flips the session to data(session); go_router's
      // redirect picks it up and lands on the role shell automatically.
    } on ValidationFailure catch (e) {
      if (mounted) {
        setState(() {
          _fieldErrors = e.fieldErrors;
          _errorText = e.fieldErrors.isEmpty ? e.message : null;
        });
        _formKey.currentState!.validate();
      }
    } on UnauthorizedFailure {
      if (mounted) setState(() => _errorText = 'Correo o contraseña incorrectos.');
    } on AppFailure catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.headerGradient,
                  ),
                ),
                child: Column(
                  children: [
                    const MonsterMascot(height: 132),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        children: [
                          TextSpan(text: 'Eye', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'School', style: TextStyle(color: AppColors.teal)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                transform: Matrix4.translationValues(0, -24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bienvenido', style: AppTextStyles.h1),
                      const SizedBox(height: 6),
                      Text('Ingresa a tu cuenta para continuar', style: AppTextStyles.bodyMuted),
                      const SizedBox(height: 28),
                      Text('Correo electrónico', style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          hintText: 'tu@correo.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) =>
                            _fieldErrors['correo'] ?? Validators.email(value),
                      ),
                      const SizedBox(height: 18),
                      Text('Contraseña', style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (value) =>
                            _fieldErrors['password'] ?? Validators.password(value),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 18, color: AppColors.pink),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: AppTextStyles.body.copyWith(color: AppColors.pink),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text('¿Olvidaste tu contraseña?', style: AppTextStyles.link),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryGradientButton(
                        label: 'Entrar',
                        icon: Icons.arrow_forward_rounded,
                        loading: _submitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.divider)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('o', style: AppTextStyles.caption),
                          ),
                          const Expanded(child: Divider(color: AppColors.divider)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // A Wrap, not a Row: the pair has to survive a narrow
                      // screen and a large text scale.
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('¿No tienes cuenta? ', style: AppTextStyles.body),
                          GestureDetector(
                            onTap: () => context.push('/registro'),
                            child: Text('Regístrate', style: AppTextStyles.link),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
