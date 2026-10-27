import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/activities/presentation/activity_list_page.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/notes/presentation/note_detail_page.dart';
import '../../features/notes/presentation/note_form_page.dart';
import '../../features/notes/presentation/note_list_page.dart';
import '../../features/schedules/presentation/schedule_detail_page.dart';
import '../../features/schedules/presentation/schedule_form_page.dart';
import '../../features/schedules/presentation/schedule_list_page.dart';
import '../../features/tasks/presentation/task_detail_page.dart';
import '../../features/tasks/presentation/task_form_page.dart';
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

final _rootKey = GlobalKey<NavigatorState>();

typedef _PageBuilder = Widget Function(GoRouterState state);

/// Builds the sub-routes (`new`, `:id`, `:id/edit`) of a CRUD feature.
/// [form] serves both `new` and `:id/edit`; missing builders fall back to a
/// placeholder. Sub-routes open on the root navigator, full-screen above the
/// navigation bar.
GoRoute _crudRoute(
  String path,
  String title,
  Widget Function() list, {
  _PageBuilder? form,
  _PageBuilder? detail,
}) {
  return GoRoute(
    path: path,
    builder: (_, _) => list(),
    routes: [
      GoRoute(
        path: 'new',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            form?.call(state) ?? PlaceholderPage(title: 'Tambah $title'),
      ),
      GoRoute(
        path: ':id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            detail?.call(state) ??
            PlaceholderPage(
              title: 'Detail $title',
              subtitle: 'ID: ${state.pathParameters['id']}',
            ),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootKey,
            builder: (_, state) =>
                form?.call(state) ?? PlaceholderPage(title: 'Edit $title'),
          ),
        ],
      ),
    ],
  );
}

GoRouter createRouter(AuthRepository auth) {
  const guestPaths = {'/login', '/register'};

  return GoRouter(
    navigatorKey: _rootKey,
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
          _crudRoute(
            '/tasks',
            'Tugas',
            () => const TaskListPage(),
            form: (state) => TaskFormPage(id: state.pathParameters['id']),
            detail: (state) => TaskDetailPage(id: state.pathParameters['id']!),
          ),
          _crudRoute(
            '/schedules',
            'Jadwal',
            () => const ScheduleListPage(),
            form: (state) => ScheduleFormPage(
              id: state.pathParameters['id'],
              initialDay: int.tryParse(state.uri.queryParameters['day'] ?? ''),
            ),
            detail: (state) =>
                ScheduleDetailPage(id: state.pathParameters['id']!),
          ),
          _crudRoute(
            '/notes',
            'Catatan',
            () => const NoteListPage(),
            form: (state) => NoteFormPage(id: state.pathParameters['id']),
            detail: (state) => NoteDetailPage(id: state.pathParameters['id']!),
          ),
          _crudRoute('/activities', 'Kegiatan', () => const ActivityListPage()),
        ],
      ),
    ],
  );
}
