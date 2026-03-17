import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom sheet con información de privacidad y manejo de datos.
/// Extraído de profile_screen para mantener la pantalla limpia.
class PrivacyInfoSheet extends StatelessWidget {
  const PrivacyInfoSheet({super.key});

  /// Muestra el bottom sheet de privacidad.
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

          // Título con ícono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Privacidad y datos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
