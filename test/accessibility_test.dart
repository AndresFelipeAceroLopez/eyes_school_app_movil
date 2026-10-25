import 'dart:async';

import 'package:eyes_school/app.dart';
import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/theme/app_theme.dart';
import 'package:eyes_school/features/auth/presentation/forgot_password_screen.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Accessibility guidelines (MC-01, capacidad de interacción / inclusividad).
///
/// Lighthouse only audits web pages, so the mobile app is measured with the
/// guidelines Flutter ships: tap targets of at least 48×48 dp (Android) and
/// 44×44 pt (iOS), a label on every tappable element, and WCAG contrast for
/// text. Each public screen counts as one check in the metric.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // The test host has no network, so the Google Fonts download fails and
    // its error would land in the middle of an assertion. The font is loaded
    // once, when the shared text style is first built: build it here, in a
    // zone that drops that failure. Text then renders in the test font, which
    // does not change colors, sizes or semantics.
    GoogleFonts.config.allowRuntimeFetching = false;
    runZonedGuarded(() => AppTextStyles.h1, (_, _) {});
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> expectGuidelines(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  }

  testWidgets('login cumple las pautas de accesibilidad', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(TokenStorage())],
        child: const EyeSchoolApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);

    await expectGuidelines(tester);
  });

  testWidgets('recuperar contraseña cumple las pautas de accesibilidad', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await expectGuidelines(tester);
  });
}
