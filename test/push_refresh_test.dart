// N-33: al tocar una notificación, la app abría las novedades sin la nueva
// (había que recargar a mano). Ahora una notificación dispara la recarga.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/core/domain/usecases.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/features/directory/domain/linked_child.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/notifications/providers/push_provider.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';

final _refProvider = Provider<Ref>((ref) => ref);

/// Rosa (DS-03): two children, Sofía (1) active.
class _Guardian implements AuthRepository {
  @override
  Future<bool> hasStoredSession() async => true;

  @override
  Future<AppSession> restoreSession() async => AppSession(
    user: const AppUser(
      userId: 4,
      name: 'Rosa Pérez',
      email: 'rosa@example.com',
      role: Role.parent,
    ),
    childId: 1,
    children: const [
      LinkedChild(id: 1, name: 'Sofía Rodríguez'),
      LinkedChild(id: 3, name: 'Santiago López'),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('recibir una notificación con la app abierta recarga los datos', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    refreshAfterPush(container.read(_refProvider));

    expect(container.read(dataRefreshProvider), 1);
  });

  test('tocar la notificación recarga antes de abrir la pantalla', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Sin sesión ni router: la navegación falla en silencio, la recarga no.
    openFromNotification({'type': 'novedad'}, container.read(_refProvider));

    expect(container.read(dataRefreshProvider), 1);
  });

  // P-07 (propuesta): con dos hijos, la notificación abre al hijo de la
  // novedad, no al que estaba activo.
  test('la notificación de Santiago lo deja como hijo activo', () async {
    final container = ProviderContainer(
      overrides: [
        restoreSessionProvider.overrideWithValue(RestoreSession(_Guardian())),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider);
    for (var i = 0; i < 50 && container.read(sessionProvider).isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.read(currentSessionProvider)?.childId, 1);

    openFromNotification({
      'type': 'novedad',
      'id_estudiante': '3',
    }, container.read(_refProvider));

    expect(container.read(currentSessionProvider)?.childId, 3);
  });

  test('un id que no es de sus hijos no cambia el hijo activo', () async {
    final container = ProviderContainer(
      overrides: [
        restoreSessionProvider.overrideWithValue(RestoreSession(_Guardian())),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider);
    for (var i = 0; i < 50 && container.read(sessionProvider).isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    openFromNotification({
      'type': 'novedad',
      'id_estudiante': '99',
    }, container.read(_refProvider));

    expect(container.read(currentSessionProvider)?.childId, 1);
  });
}
