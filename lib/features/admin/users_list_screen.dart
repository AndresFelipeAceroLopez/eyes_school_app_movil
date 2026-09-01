import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/role.dart';
import '../../models/user.dart';
import '../../providers/data_providers.dart';

enum _RoleFilter { all, admin, teacher, student }

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  _RoleFilter _filter = _RoleFilter.all;
  String _query = '';

  bool _matchesFilter(AppUser user) => switch (_filter) {
        _RoleFilter.all => true,
        _RoleFilter.admin => user.role == Role.admin,
        _RoleFilter.teacher => user.role == Role.teacher,
        _RoleFilter.student => user.role == Role.student,
      };

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: usersAsync.when(
        data: (users) {
          final filtered = users
              .where(_matchesFilter)
              .where((u) => u.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();
          final activeCount = users.where((u) => u.status.isActive).length;
          final inactiveCount = users.length - activeCount;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 20),
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
                          onPressed: () => context.pop(),
                        ),
                        Text('Usuarios', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar usuario...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todos',
                        selected: _filter == _RoleFilter.all,
                        onTap: () => setState(() => _filter = _RoleFilter.all),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Admin',
                        selected: _filter == _RoleFilter.admin,
                        onTap: () => setState(() => _filter = _RoleFilter.admin),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Docentes',
                        selected: _filter == _RoleFilter.teacher,
                        onTap: () => setState(() => _filter = _RoleFilter.teacher),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Estudiantes',
                        selected: _filter == _RoleFilter.student,
                        onTap: () => setState(() => _filter = _RoleFilter.student),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: _StatChip(value: '$activeCount', label: 'Activos', color: AppColors.tealDark, bg: AppColors.statusActiveBg)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatChip(value: '$inactiveCount', label: 'Inactivos', color: AppColors.pink, bg: const Color(0xFFFFE7EC))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatChip(value: '${users.length}', label: 'Total', color: AppColors.indigo, bg: AppColors.roleStudentBg)),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text('Sin resultados', style: AppTextStyles.bodyMuted))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(color: AppColors.divider, height: 1),
                        itemBuilder: (context, index) {
                          final u = filtered[index];
                          return _UserRow(
                            user: u,
                            onTap: u.role == Role.student
                                ? () => context.push('/students/${u.id}')
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudieron cargar los usuarios.', style: AppTextStyles.bodyMuted)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.indigo,
        onPressed: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Próximamente disponible.'))),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo usuario'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label, required this.color, required this.bg});

  final String value;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, this.onTap});

  final AppUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AvatarCircle(name: user.name, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  RoleBadge(role: user.role),
                ],
              ),
            ),
            StatusBadge(active: user.status.isActive),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
