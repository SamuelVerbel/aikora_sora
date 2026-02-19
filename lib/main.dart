import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lnyxsafivjihrcnscdgr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxueXhzYWZpdmppaHJjbnNjZGdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4MjY4NjMsImV4cCI6MjA4NTQwMjg2M30.15lS3QpUdfwtCXQyxwtW-ejI0rkhCE6_bJR9OHhK8LY',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AikoraSoraApp(),
    ),
  );
}

class AikoraSoraApp extends StatelessWidget {
  const AikoraSoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Aikōra Sora',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: AppRoutes.authGate,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
