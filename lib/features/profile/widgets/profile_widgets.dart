import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Título de sección reutilizable en la pantalla de perfil.
class ProfileSectionTitle extends StatelessWidget {
  final String title;
  const ProfileSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Card contenedora para secciones de configuración con efecto glassmorphism.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool glassEffect;

  const SettingsCard({
    super.key,
    required this.children,
    this.glassEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: glassEffect
            ? (isDark ? Colors.white.withOpacity(0.05) : Colors.white)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: glassEffect && isDark
            ? Border.all(color: Colors.white.withOpacity(0.1), width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }
}

/// Tile de preferencia con switch y animación mejorada.
class PrefTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PrefTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: SwitchListTile(
        secondary: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: value
                ? LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.2),
                      AppColors.accent.withOpacity(0.1),
                    ],
                  )
                : null,
            color: value ? null : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: value ? AppColors.accent : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: value ? AppColors.accent : null,
          ),
        ),
        value: value,
        activeColor: AppColors.accent,
        activeTrackColor: AppColors.accent.withOpacity(0.3),
        onChanged: onChanged,
      ),
    );
  }
}

/// Tile de acción (editar perfil, cerrar sesión, etc.).
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: color),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}

/// Divisor sutil para separar items dentro de un SettingsCard.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 60,
      color: Colors.grey.withAlpha(38),
    );
  }
}