import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_home_screen.dart';
import '../../features/admin/admin_novedades_screen.dart';
import '../../features/admin/management_screen.dart';
import '../../features/admin/users_list_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/parent/children_screen.dart';
import '../../features/parent/parent_attendance_screen.dart';
import '../../features/parent/parent_grades_screen.dart';
import '../../features/parent/parent_home_screen.dart';
import '../../features/shared/my_qr_screen.dart';
import '../../features/shared/profile_screen.dart';
import '../../features/shared/qr_scan_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/student/student_grades_screen.dart';
import '../../features/student/student_home_screen.dart';
import '../../features/student/student_novedades_screen.dart';
import '../../features/student/student_schedule_screen.dart';
import '../../features/student_profile/student_profile_screen.dart';
import '../../features/teacher/teacher_classes_screen.dart';
import '../../features/teacher/teacher_grades_screen.dart';
import '../../features/teacher/teacher_home_screen.dart';
import '../../models/role.dart';
import '../../providers/session_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/role_shell_scaffold.dart';

const _shellPrefixes = ['/teacher', '/student', '/parent', '/admin'];

/// Bridges Riverpod session changes into go_router's `refreshListenable`
/// without recreating the GoRouter (and losing the nav stack) on every
/// rebuild.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<Object?>>(sessionProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onAuth = loc == '/login' || loc == '/forgot-password';
      final session = ref.read(sessionProvider);

      return session.when(
        loading: () => onSplash ? null : '/splash',
        error: (_, _) => onAuth ? null : '/login',
        data: (user) {
          if (user == null) {
            return onAuth ? null : '/login';
          }
          if (onSplash || onAuth) return user.role.homePath;

          final ownPrefix = user.role.homePath;
          final onOwnShell = loc == ownPrefix || loc.startsWith('$ownPrefix/');
          final onAnyShell = _shellPrefixes.any((p) => loc == p || loc.startsWith('$p/'));
          if (onAnyShell && !onOwnShell) return ownPrefix;
          return null;
        },
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/my-qr',
        builder: (context, state) => const MyQrScreen(),
      ),
      GoRoute(
        path: '/admin/management/users',
        builder: (context, state) => const UsersListScreen(),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (context, state) =>
            StudentProfileScreen(studentId: state.pathParameters['id']!),
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
            GoRoute(path: '/teacher', builder: (context, state) => const TeacherHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/classes', builder: (context, state) => const TeacherClassesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/qr', builder: (context, state) => const QrScanScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/notes', builder: (context, state) => const TeacherGradesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/profile', builder: (context, state) => const ProfileScreen()),
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
            GoRoute(path: '/student', builder: (context, state) => const StudentHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/notes', builder: (context, state) => const StudentGradesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/schedule', builder: (context, state) => const StudentScheduleScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/news', builder: (context, state) => const StudentNovedadesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/profile', builder: (context, state) => const ProfileScreen()),
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
            GoRoute(path: '/parent/children', builder: (context, state) => const ChildrenScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/attendance', builder: (context, state) => const ParentAttendanceScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/notes', builder: (context, state) => const ParentGradesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/parent/more', builder: (context, state) => const ProfileScreen()),
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
            GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/management', builder: (context, state) => const ManagementScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/qr', builder: (context, state) => const QrScanScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/news', builder: (context, state) => const AdminNovedadesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
