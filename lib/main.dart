import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/theme_provider.dart';

void main() async {
  // Asegura que el motor de Flutter esté listo antes de llamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Supabase usando las variables seguras
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
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
          themeMode: ThemeMode.system,
          initialRoute: AppRoutes.authGate,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
