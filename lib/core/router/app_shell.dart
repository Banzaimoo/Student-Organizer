import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _Destination {
  const _Destination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

const _destinations = [
  _Destination('/', 'Beranda', Icons.dashboard_outlined),
  _Destination('/tasks', 'Tugas', Icons.task_alt_outlined),
  _Destination('/schedules', 'Jadwal', Icons.calendar_month_outlined),
  _Destination('/notes', 'Catatan', Icons.sticky_note_2_outlined),
  _Destination('/activities', 'Kegiatan', Icons.event_outlined),
  _Destination('/profile', 'Profil', Icons.person_outline),
];

/// Navigation shell: NavigationBar on phones, NavigationRail from 840 px.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(String location) {
    for (var i = 1; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _selectedIndex(location);
    void onSelect(int i) => context.go(_destinations[i].path);

    // Own messenger so a page's SnackBars render in that page's Scaffold
    // (above its FAB) rather than in this outer navigation Scaffold.
    final content = ScaffoldMessenger(child: child);

    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
