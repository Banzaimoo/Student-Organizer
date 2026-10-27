import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/activities/presentation/activity_list_page.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/notes/presentation/note_list_page.dart';
import '../../features/schedules/presentation/schedule_list_page.dart';
import '../../features/tasks/presentation/task_list_page.dart';
import '../widgets/placeholder_page.dart';
import 'app_shell.dart';

/// Re-evaluates router redirects whenever the auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Builds the sub-routes (`new`, `:id`, `:id/edit`) of a CRUD feature.
/// Feature owners replace the placeholders with their own pages.
GoRoute _crudRoute(String path, String title, Widget Function() list) {
  return GoRoute(
    path: path,
    builder: (_, _) => list(),
    routes: [
      GoRoute(
        path: 'new',
        builder: (_, _) => PlaceholderPage(title: 'Tambah $title'),
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) => PlaceholderPage(
          title: 'Detail $title',
          subtitle: 'ID: ${state.pathParameters['id']}',
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, _) => PlaceholderPage(title: 'Edit $title'),
          ),
        ],
      ),
    ],
  );
}

GoRouter createRouter(AuthRepository auth) {
  const guestPaths = {'/login', '/register'};

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefresh(auth.authChanges),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final isGuestPath = guestPaths.contains(state.uri.path);
      if (!loggedIn && !isGuestPath) return '/login';
      if (loggedIn && isGuestPath) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
          _crudRoute('/tasks', 'Tugas', () => const TaskListPage()),
          _crudRoute('/schedules', 'Jadwal', () => const ScheduleListPage()),
          _crudRoute('/notes', 'Catatan', () => const NoteListPage()),
          _crudRoute('/activities', 'Kegiatan', () => const ActivityListPage()),
        ],
      ),
    ],
  );
}
