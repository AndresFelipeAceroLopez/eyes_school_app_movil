import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:eyes_school/core/constants/app_constants.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';


// ConsumerStatefulWidget: se necesita StatefulWidget por el
// MobileScannerController (tiene ciclo de vida propio, hay que
// disponerlo), y a la vez acceso a Riverpod para leer los repositorios.

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  AttendanceKind _tipo = AttendanceKind.entry;
  String? _lastCode;
  DateTime? _lastScanAt;
  bool _sheetOpen = false;
  bool _torchOn = false;
  int _sessionCount = 0;

  @override
  void initState() {
    super.initState();
    // Warm the student catalog so the first scan resolves instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceRepositoryProvider).warmUp().ignore();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Debounced so a code held in front of the lens registers once, not three
  /// times.
  bool _isDebounced(String code) {
    final now = DateTime.now();
    if (_lastCode == code &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < AppConstants.scanDebounce) {
      return true;
    }
    _lastCode = code;
    _lastScanAt = now;
    return false;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_sheetOpen) return;
    final code = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;
    if (_isDebounced(code)) return;

    // resolve() primero busca el código en el catálogo local de estudiantes
    // (para funcionar sin señal); solo si hace falta consulta el backend
    // mediante Dio.

    final repo = ref.read(attendanceRepositoryProvider);
    final result = await repo.resolve(code, kind: _tipo);
    if (!mounted) return;

    switch (result) {
      case ScanUnknownCode(:final code):
        HapticFeedback.heavyImpact();
        _toast('Código no reconocido: $code', error: true);
      case ScanInactiveStudent(:final student):
        HapticFeedback.heavyImpact();
        _toast('${student.displayName} no está activo (${student.status}).',
            error: true);
      case ScanResolved():
        HapticFeedback.mediumImpact();
        await _confirm(result, code);
    }
  }

  Future<void> _confirm(ScanResolved result, String rawCode) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) return;

    setState(() => _sheetOpen = true);
    final registered = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConfirmSheet(
        studentName: result.student.displayName.isEmpty
            ? result.student.code
            : result.student.displayName,
        studentCode: result.student.code,
        courseName: ref
            .read(coursesProvider)
            .valueOrNull
            ?.where((c) => c.id == result.student.courseId)
            .map((c) => c.name)
            .firstOrNull,
        initialState: result.suggested,
        kind: _tipo,
        onSubmit: (state, observacion) async {
          final outcome = await ref.read(attendanceRepositoryProvider).record(
                studentId: result.student.studentId,
                studentName: result.student.displayName,
                state: state,
                kind: _tipo,
                registeredBy: session.user.userId,
                qrCode: rawCode,
                observation: observacion,
              );
          ref.invalidate(todayAttendanceProvider);
          return outcome;
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _sheetOpen = false;
      _lastCode = null;
      _lastScanAt = null;
    });
    if (registered == true) setState(() => _sessionCount++);
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.pink : AppColors.tealDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
  }

  @override
  Widget build(BuildContext context) {

    // attendanceQueueProvider expone la cola de registros que aún no se han
    // sincronizado con el backend; se usa para el badge de "pendientes".

    final queue = ref.watch(attendanceQueueProvider);

    // connectivityProvider también es un AsyncValue; con valueOrNull se evita
    // mostrar loading/error de conectividad y se asume "en línea" por defecto.

    final online = ref.watch(connectivityProvider).valueOrNull ?? true;
    final pending = queue.pendingCount;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, _) => _CameraError(error: error),
          ),
          const _ScannerOverlay(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  torchOn: _torchOn,
                  online: online,
                  pending: pending,
                  onToggleTorch: () async {
                    await _controller.toggleTorch();
                    if (mounted) setState(() => _torchOn = !_torchOn);
                  },
                  onOpenPending: () => context.push('/admin/qr/pendientes'),
                ),
                const Spacer(),
                _BottomPanel(
                  kind: _tipo,
                  sessionCount: _sessionCount,
                  onKindChanged: (kind) => setState(() => _tipo = kind),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.torchOn,
    required this.online,
    required this.pending,
    required this.onToggleTorch,
    required this.onOpenPending,
  });

  final bool torchOn;
  final bool online;
  final int pending;
  final VoidCallback onToggleTorch;
  final VoidCallback onOpenPending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text('Escanear código', style: AppTextStyles.h3.copyWith(color: Colors.white)),
          ),
          if (!online)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Sin conexión',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          // The pending badge is always visible: the user must be able to see
          // at a glance that work is still owed to the server.
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.cloud_sync_rounded, color: Colors.white),
                onPressed: onOpenPending,
                tooltip: 'Pendientes por sincronizar',
              ),
              if (pending > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pending',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: torchOn ? AppColors.teal : Colors.white,
            ),
            onPressed: onToggleTorch,
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.kind,
    required this.sessionCount,
    required this.onKindChanged,
  });

  final AttendanceKind kind;
  final int sessionCount;
  final ValueChanged<AttendanceKind> onKindChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            'Apunta la cámara al código QR del estudiante',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final option in [AttendanceKind.entry, AttendanceKind.exit])
                Expanded(
                  child: GestureDetector(
                    onTap: () => onKindChanged(option),
                    child: Container(
                      margin: EdgeInsets.only(right: option == AttendanceKind.entry ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: kind == option
                            ? const LinearGradient(colors: AppColors.primaryGradient)
                            : null,
                        color: kind == option ? null : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        option.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (sessionCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$sessionCount registro(s) en esta sesión',
              style: AppTextStyles.caption.copyWith(color: AppColors.teal),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet shown after each successful resolution: who it is, what will
/// be recorded, and the chance to correct it before it is queued.
class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({
    required this.studentName,
    required this.studentCode,
    required this.courseName,
    required this.initialState,
    required this.kind,
    required this.onSubmit,
  });

  final String studentName;
  final String studentCode;
  final String? courseName;
  final AttendanceState initialState;
  final AttendanceKind kind;
  final Future<bool> Function(AttendanceState estado, String? observacion) onSubmit;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  late AttendanceState _state = widget.initialState;
  final _observacion = TextEditingController();
  bool _saving = false;

  static const _options = [
    AttendanceState.present,
    AttendanceState.late,
    AttendanceState.absent,
    AttendanceState.excused,
  ];

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final queued = await widget.onSubmit(
        _state,
        _observacion.text.trim().isEmpty ? null : _observacion.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(queued);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(queued
              ? '${widget.studentName}: ${_state.label} registrado.'
              : '${widget.studentName} ya tenía registro de ${widget.kind.label.toLowerCase()} hoy.'),
          backgroundColor: queued ? AppColors.tealDark : AppColors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              AvatarCircle(name: widget.studentName, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.studentName, style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(
                      [widget.studentCode, widget.courseName]
                          .whereType<String>()
                          .join(' · '),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.roleStudentBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.kind.label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.roleStudent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Estado', style: AppTextStyles.caption),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((option) {
              final selected = _state == option;
              return GestureDetector(
                onTap: () => setState(() => _state = option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.indigo : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    option.label,
                    style: AppTextStyles.body.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _observacion,
            decoration: const InputDecoration(
              hintText: 'Observación (opcional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryGradientButton(
            label: 'Registrar',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar', style: AppTextStyles.link),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.teal, width: 3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 44),
              const SizedBox(height: 16),
              Text(
                denied
                    ? 'Necesitamos acceso a la cámara para leer los códigos QR de '
                        'los estudiantes. Actívalo desde los ajustes del teléfono.'
                    : 'No pudimos abrir la cámara en este dispositivo.',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
