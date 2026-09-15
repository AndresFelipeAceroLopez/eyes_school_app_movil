import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/validators.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/status_badge.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// One profile screen for the four roles.
///
/// The document is deliberately not editable — the same rule the web panel
/// applies — and neither is the role: both are administrative facts, not user
/// preferences.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loadingDetails = true;
  AppUser? _detailed;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  /// `/auth/me` does not carry phone, address or document; `/usuarios/{id}`
  /// does, so the card is completed with one extra read.
  Future<void> _loadDetails() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() {
      _loadingDetails = true;
      _error = null;
    });
    try {
      final full = await ref.read(authRepositoryProvider).loadFullProfile(user);
      if (!mounted) return;
      setState(() {
        _detailed = full;
        _loadingDetails = false;
      });
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final user = _detailed ?? session?.user;

    if (user == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sessionProvider.notifier).refresh();
          await _loadDetails();
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text('Perfil', style: AppTextStyles.h1),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AvatarCircle(name: user.name, radius: 36),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: InkWell(
                            onTap: _changeAvatar,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: AppColors.primaryGradient),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(user.name, style: AppTextStyles.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    RoleBadge(role: user.role),
                    const SizedBox(height: 8),
                    StatusBadge(
                      active: user.isActive,
                      inactiveLabel: 'Pendiente de validación',
                    ),
                    if (user.subject != null) ...[
                      const SizedBox(height: 8),
                      Text(user.subject!,
                          style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
                    ],
                    if (user.grade != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [user.grade, user.jornada].whereType<String>().join(' · '),
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                    if (user.code != null) ...[
                      const SizedBox(height: 8),
                      _CodeChip(code: user.code!),
                    ],
                  ],
                ),
              ),
              if (user.role == Role.student) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.indigo,
                    side: const BorderSide(color: AppColors.indigo),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.push('/my-qr'),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('Ver mi carné QR'),
                ),
              ],
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child:
                                Text('Información de la cuenta', style: AppTextStyles.h3)),
                        if (_loadingDetails)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            tooltip: 'Editar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.indigo),
                            onPressed: () => _editProfile(user),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Correo',
                        value: user.email.isEmpty ? '—' : user.email),
                    const Divider(height: 24, color: AppColors.divider),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Teléfono',
                        value: user.phone ?? '—'),
                    const Divider(height: 24, color: AppColors.divider),
                    _InfoRow(
                        icon: Icons.home_outlined,
                        label: 'Dirección',
                        value: user.address ?? '—'),
                    const Divider(height: 24, color: AppColors.divider),
                    // Locked on purpose: identity documents are changed by an
                    // administrator, not by their owner.
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Documento',
                      value: user.document ?? '—',
                      locked: true,
                    ),
                    if (user.institution != null) ...[
                      const Divider(height: 24, color: AppColors.divider),
                      _InfoRow(
                          icon: Icons.school_outlined,
                          label: 'Nivel de acceso',
                          value: user.institution!),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorView(error: _error!, compact: true, onRetry: _loadDetails),
              ],
              const SizedBox(height: 16),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.textSecondary),
                        title: Text('Cambiar contraseña', style: AppTextStyles.body),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                        onTap: () => _changePassword(user),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.pink,
                    side: const BorderSide(color: AppColors.pink),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final pending = ref.read(attendanceQueueProvider).pendingCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cerrar sesión', style: AppTextStyles.h3),
        content: Text(
          pending == 0
              ? '¿Quieres salir de tu cuenta?'
              : 'Tienes $pending registro(s) de asistencia sin sincronizar. '
                  'Si cierras sesión ahora se perderán.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Salir', style: AppTextStyles.link.copyWith(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(sessionProvider.notifier).logout();
  }

  Future<void> _changeAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
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
            Text('Foto de perfil', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Tomar foto', style: AppTextStyles.body),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Elegir de la galería', style: AppTextStyles.body),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).uploadAvatar(picked.path);
      await _loadDetails();
      messenger.showSnackBar(const SnackBar(
        content: Text('Foto actualizada.'),
        backgroundColor: AppColors.tealDark,
      ));
    } on AppFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editProfile(AppUser user) async {
    final phone = TextEditingController(text: user.phone ?? '');
    final address = TextEditingController(text: user.address ?? '');
    final email = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EditSheet(
        formKey: formKey,
        phone: phone,
        address: address,
        email: email,
        onSave: () async {
          await ref.read(authRepositoryProvider).updateProfile(
                userId: user.userId,
                phone: phone.text.trim(),
                address: address.text.trim(),
                email: email.text.trim(),
              );
        },
      ),
    );

    phone.dispose();
    address.dispose();
    email.dispose();

    if (saved == true) {
      await _loadDetails();
      await ref.read(sessionProvider.notifier).refresh();
    }
  }

  Future<void> _changePassword(AppUser user) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PasswordSheet(
        formKey: formKey,
        password: password,
        confirm: confirm,
        onSave: () async {
          await ref.read(authRepositoryProvider).changePassword(
                userId: user.userId,
                password: password.text,
              );
        },
      ),
    );

    password.dispose();
    confirm.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Contraseña actualizada.'),
        backgroundColor: AppColors.tealDark,
      ));
    }
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({
    required this.formKey,
    required this.phone,
    required this.address,
    required this.email,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phone;
  final TextEditingController address;
  final TextEditingController email;
  final Future<void> Function() onSave;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};
  String? _errorText;

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorText = null;
      _fieldErrors = const {};
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.of(context).pop(true);
    } on ValidationFailure catch (e) {
      if (mounted) {
        setState(() {
          _fieldErrors = e.fieldErrors;
          _saving = false;
        });
        widget.formKey.currentState!.validate();
      }
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar datos', style: AppTextStyles.h2),
            const SizedBox(height: 18),
            Text('Correo', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (v) => _fieldErrors['correo'] ?? Validators.email(v),
            ),
            const SizedBox(height: 16),
            Text('Teléfono', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
              validator: (_) => _fieldErrors['telefono'],
            ),
            const SizedBox(height: 16),
            Text('Dirección', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.address,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.home_outlined)),
              validator: (_) => _fieldErrors['direccion'],
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 14),
              Text(_errorText!, style: AppTextStyles.body.copyWith(color: AppColors.pink)),
            ],
            const SizedBox(height: 22),
            PrimaryGradientButton(
              label: 'Guardar cambios',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({
    required this.formKey,
    required this.password,
    required this.confirm,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController password;
  final TextEditingController confirm;
  final Future<void> Function() onSave;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  bool _saving = false;
  bool _obscure = true;
  String? _errorText;

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cambiar contraseña', style: AppTextStyles.h2),
            const SizedBox(height: 18),
            Text('Nueva contraseña', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.password,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 16),
            Text('Confirmar contraseña', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded)),
              validator: (v) =>
                  v == widget.password.text ? null : 'Las contraseñas no coinciden.',
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 14),
              Text(_errorText!, style: AppTextStyles.body.copyWith(color: AppColors.pink)),
            ],
            const SizedBox(height: 22),
            PrimaryGradientButton(
              label: 'Guardar contraseña',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        code,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (locked)
          const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.textSecondary),
      ],
    );
  }
}
