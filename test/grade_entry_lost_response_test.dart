// CP-ACE-060 (16/11/2026): el docente guarda 4.1, la nota llega al servidor
// pero la respuesta se pierde (sin red). La planilla volvía a mostrar el valor
// viejo (3.2) y un nuevo «Guardar» lo escribía encima del 4.1 del servidor.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/academic/domain/roster_student.dart';
import 'package:eyes_school/features/academic/domain/teacher_class.dart';
import 'package:eyes_school/features/academic/presentation/grade_entry_screen.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// The server: one grade (id 4) for student 2. Saving changes it and then
/// loses the answer, as when the signal drops mid-request.
class _Server implements AcademicRepository {
  double score = 3.2;
  final saved = <double>[];

  @override
  Future<List<Grade>> gradeSheet({
    required int subjectId,
    required int period,
  }) async => [
    Grade(
      subject: 'Matemáticas',
      score: score,
      period: '1',
      gradeId: 4,
      studentId: 2,
    ),
  ];

  @override
  Future<void> saveGrade({
    required int studentId,
    required int subjectId,
    required int period,
    required double score,
    required int registeredBy,
    int? gradeId,
    String? observation,
  }) async {
    saved.add(score);
    this.score = score;
    throw const NetworkFailure();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets('tras perder la respuesta, la planilla muestra lo del servidor '
      'y no lo vuelve a pisar', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(600 * 3, 1000 * 3);
    addTearDown(tester.view.reset);
    final server = _Server();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academicRepositoryProvider.overrideWithValue(server),
          teacherClassProvider(1).overrideWith(
            (ref) async => const TeacherClass(
              assignmentId: 1,
              courseId: 1,
              subjectId: 1,
              courseName: 'Sexto A',
              subjectName: 'Matemáticas',
              active: true,
            ),
          ),
          rosterProvider(1).overrideWith(
            (ref) async => const [RosterStudent(id: 2, name: 'Juan Pérez')],
          ),
          currentSessionProvider.overrideWithValue(
            const AppSession(
              user: AppUser(
                userId: 2,
                name: 'Carlos Jiménez',
                email: 'carlos@example.com',
                role: Role.teacher,
              ),
              teacherId: 1,
            ),
          ),
        ],
        child: const MaterialApp(home: GradeEntryScreen(assignmentId: 1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '3.2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4.1');
    await tester.tap(find.text('Guardar notas'));
    await tester.pumpAndSettle();

    // El servidor quedó con 4.1 y la planilla lo muestra (antes: 3.2).
    expect(server.score, 4.1);
    expect(find.widgetWithText(TextField, '4.1'), findsOneWidget);
    expect(find.widgetWithText(TextField, '3.2'), findsNothing);
    expect(find.textContaining('no sabemos si la última nota llegó'), findsOne);

    // Guardar otra vez no reescribe el valor viejo.
    await tester.tap(find.text('Guardar notas'));
    await tester.pumpAndSettle();
    // Solo se envió el 4.1 del primer intento: nada pisó al servidor.
    expect(server.saved, [4.1]);
    expect(server.score, 4.1);
  });
}
