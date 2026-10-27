import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/courses/data/course_repository.dart';
import 'features/courses/providers/course_provider.dart';
import 'features/schedules/data/schedule_repository.dart';
import 'features/schedules/providers/schedule_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  try {
    await dotenv.load();
  } catch (_) {
    // Missing .env is reported below via SupabaseConfig.isConfigured.
  }

  if (!SupabaseConfig.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  final authRepo = AuthRepository();
  final courses = CourseProvider(CourseRepository());
  final schedules = ScheduleProvider(ScheduleRepository(), courses);

  // Drop cached rows on logout so the next account never sees them.
  authRepo.authChanges.listen((state) {
    if (state.event == AuthChangeEvent.signedOut) {
      courses.clear();
      schedules.clear();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider.value(value: courses),
        ChangeNotifierProvider.value(value: schedules),
      ],
      child: App(router: createRouter(authRepo)),
    ),
  );
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Konfigurasi Supabase belum diisi.\n'
              'Salin .env.example menjadi .env lalu isi SUPABASE_URL dan SUPABASE_ANON_KEY.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
