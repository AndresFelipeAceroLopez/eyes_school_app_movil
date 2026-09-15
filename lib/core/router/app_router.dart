import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/features/dashboard/presentation/admin_home_screen.dart';
import 'package:eyes_school/features/novedades/presentation/admin_novedades_screen.dart';
import 'package:eyes_school/features/attendance/presentation/bulk_attendance_screen.dart';
import 'package:eyes_school/features/directory/presentation/management_screen.dart';
import 'package:eyes_school/features/attendance/presentation/pending_attendance_screen.dart';
import 'package:eyes_school/features/attendance/presentation/today_attendance_screen.dart';
import 'package:eyes_school/features/directory/presentation/users_list_screen.dart';
import 'package:eyes_school/features/auth/presentation/forgot_password_screen.dart';
import 'package:eyes_school/features/auth/presentation/login_screen.dart';
import 'package:eyes_school/features/auth/presentation/register_screen.dart';
import 'package:eyes_school/features/auth/presentation/reset_password_screen.dart';
import 'package:eyes_school/features/errors/no_access_screen.dart';
import 'package:eyes_school/features/directory/presentation/children_screen.dart';
import 'package:eyes_school/features/attendance/presentation/parent_attendance_screen.dart';
import 'package:eyes_school/features/academic/presentation/parent_grades_screen.dart';
import 'package:eyes_school/features/dashboard/presentation/parent_home_screen.dart';
import 'package:eyes_school/features/directory/presentation/my_qr_screen.dart';
import 'package:eyes_school/features/directory/presentation/profile_screen.dart';
import 'package:eyes_school/features/directory/presentation/qr_scan_screen.dart';
import 'package:eyes_school/features/splash/splash_screen.dart';
import 'package:eyes_school/features/attendance/presentation/student_attendance_screen.dart';
import 'package:eyes_school/features/academic/presentation/student_grades_screen.dart';
import 'package:eyes_school/features/dashboard/presentation/student_home_screen.dart';
import 'package:eyes_school/features/novedades/presentation/student_novedades_screen.dart';
import 'package:eyes_school/features/academic/presentation/student_schedule_screen.dart';
import 'package:eyes_school/features/directory/presentation/student_profile_screen.dart';
import 'package:eyes_school/features/academic/presentation/class_roster_screen.dart';
import 'package:eyes_school/features/academic/presentation/grade_entry_screen.dart';
import 'package:eyes_school/features/academic/presentation/teacher_classes_screen.dart';
import 'package:eyes_school/features/academic/presentation/teacher_grades_screen.dart';
import 'package:eyes_school/features/dashboard/presentation/teacher_home_screen.dart';
import 'package:eyes_school/features/directory/presentation/teacher_profile_screen.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/core/widgets/app_bottom_nav.dart';
import 'package:eyes_school/core/widgets/role_shell_scaffold.dart';

const _shellPrefixes = ['/teacher', '/student', '/parent', '/admin'];

/// Routes reachable without a session.
const _publicRoutes = {'/login', '/forgot-password', '/registro', '/reset-password'};

/// Translates `eyesschool://<host>` links into an in-app location. Returns
/// `null` for ordinary navigation, which is everything that already has a path.
String? _deepLinkTarget(Uri uri) {
  if (uri.host != 'reset' || uri.path.isNotEmpty) return null;
  final token = uri.queryParameters['token'];
  return token == null ? '/reset-password' : '/reset-password?token=$token';
}

/// Bridges Riverpod session changes into go_router's `refreshListenable`
/// without recreating the GoRouter (and losing the nav stack) on every
/// rebuild.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AppSession?>>(sessionProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // A custom-scheme deep link (`eyesschool://reset?token=...`) arrives
      // with the target in the URI *host*, not the path, so it has to be
      // rewritten before any guard looks at the location.
      final deepLink = _deepLinkTarget(state.uri);
      if (deepLink != null) return deepLink;

      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onPublic = _publicRoutes.contains(loc);
      final session = ref.read(sessionProvider);

      return session.when(
        // Still restoring the stored tokens.
        loading: () => onSplash ? null : '/splash',
        error: (_, _) => onPublic ? null : '/login',
        data: (session) {
          if (session == null) {
            return onPublic ? null : '/login';
          }

          // An account still awaiting an admin's validation has a session but
          // no access: the web panel calls this "Validación pendiente".
          if (!session.user.isActive) {
            return loc == '/error/sin-permiso' ? null : '/error/sin-permiso';
          }

          final ownPrefix = session.role.homePath;
          if (onSplash || onPublic) return ownPrefix;

          // Namespace guard: a deep link or a restored process can never land
          // a student inside a teacher screen.
          final onOwnShell = loc == ownPrefix || loc.startsWith('$ownPrefix/');
          final onAnyShell =
              _shellPrefixes.any((p) => loc == p || loc.startsWith('$p/'));
          if (onAnyShell && !onOwnShell) return '/error/sin-permiso';
          return null;
        },
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        // Deep link: eyesschool://reset?token=…
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/error/sin-permiso',
        builder: (context, state) => const NoAccessScreen(),
      ),
      GoRoute(path: '/my-qr', builder: (context, state) => const MyQrScreen()),
      GoRoute(
        path: '/admin/management/users',
        builder: (context, state) => const UsersListScreen(),
      ),
      GoRoute(
        // Every id travels as a typed path param, never inside `extra`, so
        // deep links and process restore both work.
        path: '/students/:id',
        builder: (context, state) => StudentProfileScreen(
          studentId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/teachers/:id',
        builder: (context, state) => TeacherProfileScreen(
          teacherId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),

      // ---------------- Teacher shell ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShellScaffold(
          navigationShell: shell,
          elevatedIndex: 2,
          items: const [
            NavItem(icon: Icons.grid_view_rounded, label: 'Inicio'),
            NavItem(icon: Icons.menu_book_rounded, label: 'Clases'),
            NavItem(icon: Icons.qr_code_scanner_rounded, label: 'QR'),
            NavItem(icon: Icons.bar_chart_rounded, label: 'Notas'),
            NavItem(icon: Icons.person_rounded, label: 'Perfil'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/teacher',
              builder: (context, state) => const TeacherHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/teacher/classes',
              builder: (context, state) => const TeacherClassesScreen(),
              routes: [
                GoRoute(
                  path: ':idAsignacion/asistencia',
                  builder: (context, state) => ClassRosterScreen(
                    assignmentId:
                        int.tryParse(state.pathParameters['idAsignacion'] ?? '') ?? 0,
                  ),
                ),
                GoRoute(
                  path: ':idAsignacion/notas',
                  builder: (context, state) => GradeEntryScreen(
                    assignmentId:
                        int.tryParse(state.pathParameters['idAsignacion'] ?? '') ?? 0,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/qr', builder: (context, state) => const QrScanScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/teacher/notes',
              builder: (context, state) => const TeacherGradesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/teacher/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ---------------- Student shell ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShellScaffold(
          navigationShell: shell,
          items: const [
            NavItem(icon: Icons.grid_view_rounded, label: 'Inicio'),
            NavItem(icon: Icons.bar_chart_rounded, label: 'Notas'),
            NavItem(icon: Icons.calendar_month_rounded, label: 'Horario'),
            NavItem(icon: Icons.notifications_rounded, label: 'Novedades'),
            NavItem(icon: Icons.person_rounded, label: 'Perfil'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student',
              builder: (context, state) => const StudentHomeScreen(),
              routes: [
                GoRoute(
                  path: 'asistencia',
                  builder: (context, state) => const StudentAttendanceScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/notes',
              builder: (context, state) => const StudentGradesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/schedule',
              builder: (context, state) => const StudentScheduleScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/news',
              builder: (context, state) => const StudentNovedadesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ---------------- Parent shell ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShellScaffold(
          navigationShell: shell,
          items: const [
            NavItem(icon: Icons.grid_view_rounded, label: 'Inicio'),
            NavItem(icon: Icons.diversity_3_rounded, label: 'Hijos'),
            NavItem(icon: Icons.fact_check_rounded, label: 'Asistencia'),
            NavItem(icon: Icons.bar_chart_rounded, label: 'Notas'),
            NavItem(icon: Icons.more_horiz_rounded, label: 'Más'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent', builder: (context, state) => const ParentHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/parent/children',
              builder: (context, state) => const ChildrenScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/parent/attendance',
              builder: (context, state) => const ParentAttendanceScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/parent/notes',
              builder: (context, state) => const ParentGradesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/parent/more',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ---------------- Admin shell ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShellScaffold(
          navigationShell: shell,
          elevatedIndex: 2,
          items: const [
            NavItem(icon: Icons.grid_view_rounded, label: 'Inicio'),
            NavItem(icon: Icons.school_rounded, label: 'Gestión'),
            NavItem(icon: Icons.qr_code_scanner_rounded, label: 'QR'),
            NavItem(icon: Icons.notifications_rounded, label: 'Novedades'),
            NavItem(icon: Icons.person_rounded, label: 'Perfil'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminHomeScreen(),
              routes: [
                GoRoute(
                  path: 'masivo',
                  builder: (context, state) => const BulkAttendanceScreen(),
                ),
                GoRoute(
                  path: 'dia',
                  builder: (context, state) => const TodayAttendanceScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/management',
              builder: (context, state) => const ManagementScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/qr',
              builder: (context, state) => const QrScanScreen(),
              routes: [
                GoRoute(
                  path: 'pendientes',
                  builder: (context, state) => const PendingAttendanceScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/news',
              builder: (context, state) => const AdminNovedadesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
