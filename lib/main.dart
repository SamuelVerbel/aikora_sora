import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // [IMPORTANTE]

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/theme_provider.dart';

void main() async {
  // Asegura que el motor de Flutter esté listo antes de llamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carga las variables de entorno desde el archivo .env
  //    Si el archivo no existe (ej. olvidaste crearlo), lanzará error.
  await dotenv.load(fileName: ".env");

  // 2. Inicializa Supabase usando las variables seguras
  await Supabase.initialize(
    // dotenv.env['NOMBRE_VAR'] lee el string del archivo .env
    // Si no encuentra la variable, usamos '' para evitar crash inmediato (aunque fallará la conexión)
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
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
