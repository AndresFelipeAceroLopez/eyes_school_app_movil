import 'package:eyes_school/app.dart';
import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:eyes_school/domain/entities/role.dart';
import 'package:eyes_school/domain/entities/session.dart';
import 'package:eyes_school/domain/entities/app_user.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Boot smoke test: it exercises the whole widget tree — theme, router and
/// provider graph — and pins the two things the router must get right on a
/// cold start.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // `flutter_secure_storage` talks to the Keystore through a platform
    // channel that does not exist in a test host.
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('sin sesión guardada la app aterriza en el login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(TokenStorage()),
        ],
        child: const EyeSchoolApp(),
      ),
    );

    // First frame: the splash, while the stored tokens are being checked.
    expect(find.text('EyeSchool'), findsNothing);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('la sesión expone el estudiante sobre el que consulta cada rol',
      (tester) async {
    // Not a widget assertion, but the invariant every student and guardian
    // screen depends on: `subjectStudentId` is the student themself, or the
    // guardian's linked child.
    const student = AppSession(
      user: _user,
      studentId: 41,
    );
    const guardian = AppSession(
      user: _guardian,
      parentId: 3,
      childId: 41,
    );

    expect(student.subjectStudentId, 41);
    expect(guardian.subjectStudentId, 41);
  });
}

const _user = AppUserFixture.student;
const _guardian = AppUserFixture.parent;

/// Small fixtures kept out of the test bodies so the assertions stay readable.
abstract final class AppUserFixture {
  static const student = AppUser(
    userId: 88,
    name: 'Ana Gómez',
    email: 'ana@eyes.edu.co',
    role: Role.student,
  );

  static const parent = AppUser(
    userId: 90,
    name: 'Carlos Gómez',
    email: 'carlos@eyes.edu.co',
    role: Role.parent,
  );
}
