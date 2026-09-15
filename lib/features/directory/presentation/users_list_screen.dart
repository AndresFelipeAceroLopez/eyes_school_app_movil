import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/status_badge.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/providers/data_providers.dart';

/// The admin directory: quick lookup of students, teachers and guardians.
///
/// Read-only by design. Creating, editing and deactivating users stays in the
/// web panel — this is the screen someone uses standing in a hallway to answer
/// "who is this student and what course are they in".
class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchController = TextEditingController();
  DirectoryTab _tab = DirectoryTab.students;
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Typing hits the API on the teachers and guardians tabs, so the query is
  /// debounced rather than fired on every keystroke.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync =
        ref.watch(directorySearchProvider((query: _query, tab: _tab)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.headerGradient,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/admin'),
                    ),
                    Text('Directorio',
                        style: AppTextStyles.h2.copyWith(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: switch (_tab) {
                      DirectoryTab.students => 'Buscar por nombre o código',
                      DirectoryTab.teachers => 'Buscar docente',
                      DirectoryTab.guardians => 'Buscar acudiente',
                    },
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: Colors.white,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _tabChip('Estudiantes', DirectoryTab.students),
                    const SizedBox(width: 8),
                    _tabChip('Profesores', DirectoryTab.teachers),
                    const SizedBox(width: 8),
                    _tabChip('Acudientes', DirectoryTab.guardians),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(directorySearchProvider),
              child: resultsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ListView(children: [
                  ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(directorySearchProvider),
                  ),
                ]),
                data: (users) {
                  if (users.isEmpty) {
                    return ListView(children: [
                      EmptyState(
                        icon: Icons.person_search_rounded,
                        title: _query.isEmpty ? 'Sin registros' : 'Sin resultados',
                        message: _query.isEmpty
                            ? 'No hay personas para mostrar en esta solapa.'
                            : 'No encontramos a nadie con «$_query».',
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: users.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${users.length} resultado(s)',
                              style: AppTextStyles.caption),
                        );
                      }
                      final user = users[index - 1];
                      return _PersonCard(
                        user: user,
                        onTap: () => _open(user),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _open(AppUser user) {
    if (user.studentId != null && _tab != DirectoryTab.guardians) {
      context.push('/students/${user.studentId}');
      return;
    }
    if (user.teacherId != null) {
      context.push('/teachers/${user.teacherId}');
      return;
    }
    // A guardian's card is their child's card: that is what an admin is
    // actually looking for when they open one.
    if (user.studentId != null) context.push('/students/${user.studentId}');
  }

  Widget _tabChip(String label, DirectoryTab tab) {
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? AppColors.headerGradient.first : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.user, required this.onTap});

  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            AvatarCircle(name: user.name, radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    [user.code, user.grade, user.subject, user.email]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .take(2)
                        .join(' · '),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RoleBadge(role: user.role),
                      const SizedBox(width: 8),
                      StatusBadge(active: user.isActive),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
