import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/validators.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/core/domain/repositories.dart';

/// Public self-service sign-up. `POST /auth/register` takes one payload that
/// creates the user *and* its role profile, so the form asks for the role's
/// own fields in the last step.
///
/// The web panel does this in a single tall modal; on a phone that fights the
/// keyboard, so it is split into three steps: identity, contact, role.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _identityKey = GlobalKey<FormState>();
  final _contactKey = GlobalKey<FormState>();
  final _roleKey = GlobalKey<FormState>();

  final _numeroDocumento = TextEditingController();
  final _primerNombre = TextEditingController();
  final _segundoNombre = TextEditingController();
  final _primerApellido = TextEditingController();
  final _segundoApellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  // Role-specific fields.
  final _cargo = TextEditingController();
  final _titulo = TextEditingController();
  final _nivelEstudios = TextEditingController();
  final _idEstudianteVinculado = TextEditingController();
  final _parentesco = TextEditingController();

  String _tipoDocumento = 'CC';
  String? _genero;
  int _step = 0;
  Role _role = Role.student;
  int? _cursoId;
  bool _submitting = false;
  bool _obscure = true;
  String? _errorText;
  Map<String, String> _fieldErrors = const {};

  static const _documentTypes = {
    'CC': 'Cédula de ciudadanía',
    'TI': 'Tarjeta de identidad',
    'CE': 'Cédula de extranjería',
    'PAS': 'Pasaporte',
  };

  static const _genders = {'M': 'Masculino', 'F': 'Femenino', 'O': 'Otro'};

  @override
  void dispose() {
    for (final c in [
      _numeroDocumento,
      _primerNombre,
      _segundoNombre,
      _primerApellido,
      _segundoApellido,
      _correo,
      _telefono,
      _direccion,
      _password,
      _confirmPassword,
      _cargo,
      _titulo,
      _nivelEstudios,
      _idEstudianteVinculado,
      _parentesco,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  GlobalKey<FormState> get _currentKey =>
      switch (_step) { 0 => _identityKey, 1 => _contactKey, _ => _roleKey };

  void _next() {
    if (!_currentKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    _submit();
  }

  void _back() {
    if (_step == 0) {
      context.canPop() ? context.pop() : context.go('/login');
      return;
    }
    setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorText = null;
      _fieldErrors = const {};
    });
    try {
      await ref.read(authRepositoryProvider).register(RegistrationRequest(
            documentType: _tipoDocumento,
            documentNumber: _numeroDocumento.text.trim(),
            firstName: _primerNombre.text.trim(),
            middleName: _blank(_segundoNombre),
            lastName: _primerApellido.text.trim(),
            secondLastName: _blank(_segundoApellido),
            gender: _genero,
            address: _blank(_direccion),
            email: _correo.text.trim(),
            password: _password.text,
            phone: _blank(_telefono),
            roleId: _role.apiId,
            position: _role == Role.admin ? _blank(_cargo) : null,
            courseId: _role == Role.student ? _cursoId : null,
            linkedStudentId: _role == Role.parent
                ? int.tryParse(_idEstudianteVinculado.text.trim())
                : null,
            relationship: _role == Role.parent ? _blank(_parentesco) : null,
            title: _role == Role.teacher ? _blank(_titulo) : null,
            studyLevel: _role == Role.teacher ? _blank(_nivelEstudios) : null,
          ));
      if (!mounted) return;
      _showSuccess();
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.fieldErrors;
        _errorText = e.fieldErrors.isEmpty ? e.message : 'Revisa los datos marcados.';
      });
      _roleKey.currentState?.validate();
    } on AppFailure catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _blank(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _showSuccess() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cuenta creada', style: AppTextStyles.h2),
        content: Text(
          'Tu cuenta quedó registrada y está pendiente de validación por un '
          'administrador. Te avisaremos cuando puedas ingresar.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: Text('Entendido', style: AppTextStyles.link),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: _back,
                  ),
                  Text('Crear cuenta', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? AppColors.teal
                            : Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (_step) {
                          0 => 'Tu identidad',
                          1 => 'Tus datos de contacto',
                          _ => 'Tu rol en la institución',
                        },
                        style: AppTextStyles.h1,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Paso ${_step + 1} de 3',
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 24),
                      switch (_step) {
                        0 => _identityStep(),
                        1 => _contactStep(),
                        _ => _roleStep(),
                      },
                      if (_errorText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorText!,
                          style: AppTextStyles.body.copyWith(color: AppColors.pink),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PrimaryGradientButton(
                        label: _step == 2 ? 'Crear cuenta' : 'Continuar',
                        icon: _step == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        loading: _submitting,
                        onPressed: _next,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text('Ya tengo cuenta', style: AppTextStyles.link),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityStep() {
    return Form(
      key: _identityKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Tipo de documento'),
          DropdownButtonFormField<String>(
            initialValue: _tipoDocumento,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
            items: _documentTypes.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _tipoDocumento = v ?? 'CC'),
          ),
          const SizedBox(height: 18),
          _label('Número de documento'),
          TextFormField(
            controller: _numeroDocumento,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '1002003004',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            validator: (v) => _fieldErrors['numero_documento'] ??
                Validators.required(v, 'el número de documento'),
          ),
          const SizedBox(height: 18),
          _label('Primer nombre'),
          TextFormField(
            controller: _primerNombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
            validator: (v) =>
                _fieldErrors['primer_nombre'] ?? Validators.required(v, 'tu primer nombre'),
          ),
          const SizedBox(height: 18),
          _label('Segundo nombre (opcional)'),
          TextFormField(
            controller: _segundoNombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
          ),
          const SizedBox(height: 18),
          _label('Primer apellido'),
          TextFormField(
            controller: _primerApellido,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
            validator: (v) => _fieldErrors['primer_apellido'] ??
                Validators.required(v, 'tu primer apellido'),
          ),
          const SizedBox(height: 18),
          _label('Segundo apellido (opcional)'),
          TextFormField(
            controller: _segundoApellido,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
          ),
        ],
      ),
    );
  }

  Widget _contactStep() {
    return Form(
      key: _contactKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Correo electrónico'),
          TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'tu@correo.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (v) => _fieldErrors['correo'] ?? Validators.email(v),
          ),
          const SizedBox(height: 18),
          _label('Teléfono (opcional)'),
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 18),
          _label('Dirección (opcional)'),
          TextFormField(
            controller: _direccion,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.home_outlined)),
          ),
          const SizedBox(height: 18),
          _label('Género (opcional)'),
          DropdownButtonFormField<String>(
            initialValue: _genero,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.wc_outlined)),
            items: _genders.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _genero = v),
          ),
          const SizedBox(height: 18),
          _label('Contraseña'),
          TextFormField(
            controller: _password,
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
            validator: (v) => _fieldErrors['password'] ?? Validators.newPassword(v),
          ),
          const SizedBox(height: 18),
          _label('Confirmar contraseña'),
          TextFormField(
            controller: _confirmPassword,
            obscureText: _obscure,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded)),
            validator: (v) =>
                v == _password.text ? null : 'Las contraseñas no coinciden.',
          ),
        ],
      ),
    );
  }

  Widget _roleStep() {
    final coursesAsync = ref.watch(coursesProvider);

    return Form(
      key: _roleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('¿Cuál es tu rol?'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: Role.values.map((role) {
              final selected = _role == role;
              return GestureDetector(
                onTap: () => setState(() => _role = role),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.indigo : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    role.label,
                    style: AppTextStyles.body.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          if (_role == Role.student) ...[
            _label('Curso'),
            coursesAsync.when(
              data: (courses) => DropdownButtonFormField<int>(
                initialValue: _cursoId,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.class_outlined)),
                items: courses
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} · ${c.shiftLabel}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _cursoId = v),
                validator: (v) => v == null ? 'Selecciona tu curso.' : null,
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => Text(
                'No pudimos cargar los cursos. Podrás asignarlo más tarde.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
          if (_role == Role.teacher) ...[
            _label('Título'),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                hintText: 'Licenciado en Matemáticas',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (v) => _fieldErrors['titulo'] ?? Validators.required(v, 'tu título'),
            ),
            const SizedBox(height: 18),
            _label('Nivel de estudios'),
            TextFormField(
              controller: _nivelEstudios,
              decoration: const InputDecoration(
                hintText: 'Pregrado / Especialización / Maestría',
                prefixIcon: Icon(Icons.workspace_premium_outlined),
              ),
              validator: (v) => _fieldErrors['nivel_estudios'] ??
                  Validators.required(v, 'tu nivel de estudios'),
            ),
          ],
          if (_role == Role.parent) ...[
            _label('Código o id del estudiante'),
            TextFormField(
              controller: _idEstudianteVinculado,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.family_restroom_outlined),
              ),
              validator: (v) => _fieldErrors['id_estudiante_vinculado'] ??
                  Validators.required(v, 'el estudiante vinculado'),
            ),
            const SizedBox(height: 18),
            _label('Parentesco'),
            TextFormField(
              controller: _parentesco,
              decoration: const InputDecoration(
                hintText: 'Padre / Madre / Tutor',
                prefixIcon: Icon(Icons.diversity_3_outlined),
              ),
              validator: (v) =>
                  _fieldErrors['parentesco'] ?? Validators.required(v, 'el parentesco'),
            ),
          ],
          if (_role == Role.admin) ...[
            _label('Cargo'),
            TextFormField(
              controller: _cargo,
              decoration: const InputDecoration(
                hintText: 'Coordinador académico',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
              validator: (v) => _fieldErrors['cargo'] ?? Validators.required(v, 'tu cargo'),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu cuenta quedará pendiente de validación por un administrador.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.caption),
      );
}
