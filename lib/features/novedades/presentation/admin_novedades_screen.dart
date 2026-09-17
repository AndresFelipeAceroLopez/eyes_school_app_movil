import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_card.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/data_providers.dart';

/// Institution-wide news tray, read-only for the mobile admin.
class AdminNovedadesScreen extends ConsumerWidget {
  const AdminNovedadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novedadesAsync = ref.watch(adminNovedadesProvider);

    return SimpleHeaderScaffold(
      title: 'Novedades',
      showBack: true,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminNovedadesProvider),
        child: novedadesAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(children: [
            ErrorView(error: error, onRetry: () => ref.invalidate(adminNovedadesProvider)),
          ]),
          data: (novedades) {
            if (novedades.isEmpty) {
              return ListView(children: const [
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Sin novedades',
                  message: 'No hay incidencias registradas en el colegio.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: novedades.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final novedad = novedades[index];
                return NovedadCard(
                  novedad: novedad,
                  onTap: novedad.studentId == null
                      ? null
                      : () => context.push('/students/${novedad.studentId}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
