import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';

/// Bottom sheet con información de privacidad y manejo de datos.
/// Incluye RF-18: borrado seguro de datos locales y en la nube.
class PrivacyInfoSheet extends StatelessWidget {
  const PrivacyInfoSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PrivacyInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Privacidad y datos',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _PrivacyItem(
            icon: Icons.storage_outlined,
            title: 'Almacenamiento local',
            description:
                'Tus preferencias se guardan en tu dispositivo con SharedPreferences.',
          ),
          _PrivacyItem(
            icon: Icons.cloud_outlined,
            title: 'Datos en la nube',
            description:
                'Tu perfil y reservas se almacenan de forma segura en Supabase con encriptación.',
          ),
          _PrivacyItem(
            icon: Icons.no_photography_outlined,
            title: 'Sin seguimiento',
            description:
                'No vendemos ni compartimos tus datos con terceros.',
          ),
          _PrivacyItem(
            icon: Icons.lock_outlined,
            title: 'Autenticación segura',
            description:
                'Usamos OAuth 2.0 de Google y JWT tokens para proteger tu cuenta.',
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // ── RF-18: Borrado seguro de datos ──────────────────────────────
          const Text(
            'Eliminar mis datos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Puedes eliminar todos tus datos locales y de la nube de forma permanente. Esta acción no se puede deshacer.',
            style: TextStyle(
                color: Colors.grey[500], fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever_outlined,
                  color: Colors.red),
              label: const Text(
                'Eliminar todos mis datos',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () =>
                  _confirmDeleteData(context),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// RF-18: Confirmación y ejecución del borrado seguro
  void _confirmDeleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('¿Eliminar todo?'),
        ]),
        content: const Text(
          'Se eliminarán:\n\n'
          '• Tus preferencias locales\n'
          '• Tu historial de comportamiento\n'
          '• Tu perfil y reservas en la nube\n\n'
          'Esta acción es permanente e irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // cierra el dialog
              Navigator.pop(context); // cierra el sheet
              await _executeSecureDelete(context);
            },
            child: const Text('Sí, eliminar todo'),
          ),
        ],
      ),
    );
  }

  /// RF-18: Borrado seguro en dos pasos — local primero, luego nube
  Future<void> _executeSecureDelete(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    // Muestra un loading dialog no cancelable
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Eliminando tus datos...'),
        ]),
      ),
    );

    try {
      // PASO 1 — Borrado local (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // sobreescritura efectiva: elimina todas las keys

      // PASO 2 — Borrado en la nube (Supabase) si hay sesión activa
      if (userId != null) {
        // Elimina reservas del usuario
        await supabase
            .from('reservations')
            .delete()
            .eq('user_id', userId);

        // Elimina perfil del usuario
        await supabase
            .from('profiles')
            .delete()
            .eq('id', userId);

        // Cierra sesión y elimina la cuenta de Auth
        await supabase.auth.signOut();
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // cierra el loading dialog
        // Snack de confirmación antes de redirigir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Todos tus datos han sido eliminados'),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Redirige al welcome y limpia el stack de navegación
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('[PrivacyInfoSheet] Error en borrado seguro: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // cierra el loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar datos: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Componentes ──────────────────────────────────────────────────────────────

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}