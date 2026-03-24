import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin/admin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/theme_provider.dart';
import '../auth/services/auth_service.dart';
import 'profile_controller.dart';
import 'widgets/edit_profile_modal.dart';
import 'widgets/privacy_info_sheet.dart';
import 'widgets/profile_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late final ProfileController _ctrl;
  late AnimationController _saveAnimationController;

  @override
  void initState() {
    super.initState();
    _ctrl = ProfileController();
    _ctrl.addListener(_onControllerChanged);
    _ctrl.loadData();
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false);
      }
    }
  }

  Future<void> _showSaveConfirmationAnimation() async {
    _saveAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _saveAnimationController.reverse();
  }

  Future<void> _handleSavePreferences() async {
    setState(() {});

    final success = await _ctrl.savePreferences();

    if (!mounted) return;

    if (success) {
      // Mostrar toast animado
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => _PremiumToast(
          message: '✨ Preferencias guardadas correctamente',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
      );

      overlay.insert(overlayEntry);
      Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());

      await _showSaveConfirmationAnimation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Error al guardar. Intenta de nuevo.'),
          ]),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleEditProfile() {
    EditProfileModal.show(
      context,
      currentName: _ctrl.fullName,
      onSave: (newName) => _ctrl.updateProfileName(newName),
    ).then((saved) {
      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Perfil actualizado'),
            ]),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  void _handleEditAvatar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb 
                  ? 'Selecciona una imagen desde tu computadora'
                  : 'Elige una imagen desde tu dispositivo',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Opción: Cámara (solo en móvil, no web)
                  if (!kIsWeb)
                    _AvatarPickerOption(
                      icon: Icons.camera_alt,
                      title: 'Tomar foto',
                      subtitle: 'Usa la cámara del dispositivo',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  
                  if (!kIsWeb) const SizedBox(height: 12),
                  
                  // Opción: Galería / Archivos
                  _AvatarPickerOption(
                    icon: kIsWeb ? Icons.cloud_upload : Icons.photo_library,
                    title: kIsWeb ? 'Subir imagen' : 'Elegir de la galería',
                    subtitle: kIsWeb 
                        ? 'Selecciona un archivo desde tu computadora'
                        : 'Selecciona una imagen existente',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Opción: URL (avanzada)
                  _AvatarPickerOption(
                    icon: Icons.link,
                    title: 'Usar URL',
                    subtitle: 'Pega una URL de imagen',
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showUrlInputDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      
      // En web, solo gallery funciona (cámara no soportada)
      if (kIsWeb && source == ImageSource.camera) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cámara no está disponible en la versión web'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        _showImagePreview(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Previsualización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.file(
                imageFile,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text('¿Usar esta imagen como foto de perfil?'),
            if (_ctrl.isUploadingAvatar) ...[
              const SizedBox(height: 12),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Subiendo...', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _ctrl.isUploadingAvatar ? null : () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _ctrl.isUploadingAvatar
                ? null
                : () async {
                    Navigator.pop(ctx); // Cerrar preview
                    
                    // Mostrar diálogo de carga
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Subiendo foto de perfil...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    
                    // Subir imagen
                    final success = await _ctrl.uploadAvatar(imageFile);
                    
                    if (mounted) {
                      Navigator.pop(context); // Cerrar diálogo de carga
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Foto de perfil actualizada'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al subir la imagen'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Usar esta foto'),
          ),
        ],
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlCtrl = TextEditingController(text: _ctrl.avatarUrl ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('URL de imagen'),
        content: TextField(
          controller: urlCtrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://ejemplo.com/mi-foto.jpg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              
              Navigator.pop(ctx);
              
              final success = await _ctrl.updateAvatar(url);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Foto actualizada'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (_ctrl.errorMessage != null && !_ctrl.isLoadingProfile) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(_ctrl.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _ctrl.loadData,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _ctrl.isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildHeader(isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats rápidas mejoradas
                        _buildStatsRow(isDark),
                        const SizedBox(height: 28),

                        // Banner cambios sin guardar con animación
                        if (_ctrl.hasUnsavedChanges) _buildUnsavedBanner(),

                        // Estilo de viaje con animación
                        _buildTravelStyleCard(isDark),
                        const SizedBox(height: 28),

                        // Apariencia
                        _sectionLabel('Apariencia'),
                        SettingsCard(
                          children: [
                            SwitchListTile(
                              title: const Text('Modo oscuro',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                isDark ? 'Activado' : 'Desactivado',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isDark ? Icons.dark_mode : Icons.light_mode,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              value: isDark,
                              activeColor: AppColors.accent,
                              onChanged: themeProvider.toggleTheme,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Idioma
                        _sectionLabel('Idioma'),
                        SettingsCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: DropdownButtonFormField<String>(
                                value: _ctrl.selectedLanguage,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.language,
                                      color: AppColors.accent, size: 20),
                                ),
                                items: ProfileController.languages.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) _ctrl.setLanguage(v);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 56, right: 16, bottom: 12),
                              child: Text(
                                '🌐 Traducción automática en desarrollo. Tu preferencia queda guardada para cuando esté disponible en v1.1',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Preferencias de viaje
                        _sectionLabel('Preferencias de viaje'),
                        SettingsCard(
                          children: [
                            PrefTile(
                              icon: Icons.forest_outlined,
                              label: 'Naturaleza',
                              value: _ctrl.likesNature,
                              onChanged: _ctrl.setNature,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.museum_outlined,
                              label: 'Cultura e historia',
                              value: _ctrl.likesCulture,
                              onChanged: _ctrl.setCulture,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.restaurant_outlined,
                              label: 'Gastronomía',
                              value: _ctrl.likesFood,
                              onChanged: _ctrl.setFood,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.hiking_outlined,
                              label: 'Aventura',
                              value: _ctrl.likesAdventure,
                              onChanged: _ctrl.setAdventure,
                            ),
                            const SettingsDivider(),
                            PrefTile(
                              icon: Icons.beach_access_outlined,
                              label: 'Playa y relax',
                              value: _ctrl.likesBeach,
                              onChanged: _ctrl.setBeach,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Presupuesto
                        _sectionLabel('Presupuesto por noche'),
                        SettingsCard(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Máximo por noche',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withAlpha(25),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '\$${_ctrl.budget.toInt()} USD',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Slider(
                              min: 50,
                              max: 3000,
                              divisions: 118,
                              value: _ctrl.budget,
                              activeColor: AppColors.accent,
                              onChanged: _ctrl.setBudget,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('\$50',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12)),
                                  Text('\$3,000',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Botón guardar mejorado
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              icon: _ctrl.isSavingPrefs
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : _ctrl.hasUnsavedChanges
                                      ? const Icon(Icons.save_outlined,
                                          color: Colors.white)
                                      : const Icon(Icons.check_circle,
                                          color: Colors.white),
                              label: Text(
                                _ctrl.isSavingPrefs
                                    ? 'Guardando preferencias...'
                                    : _ctrl.hasUnsavedChanges
                                        ? 'Guardar cambios'
                                        : 'Todo sincronizado',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _ctrl.hasUnsavedChanges
                                    ? AppColors.accent
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: (_ctrl.isSavingPrefs ||
                                      !_ctrl.hasUnsavedChanges)
                                  ? null
                                  : _handleSavePreferences,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Cuenta
                        _sectionLabel('Cuenta'),
                        SettingsCard(
                          children: [
                            // Admin — solo admins
                            FutureBuilder<bool>(
                              future: AdminService().isAdmin(),
                              builder: (context, snapshot) {
                                if (snapshot.data != true)
                                  return const SizedBox.shrink();
                                return Column(children: [
                                  ActionTile(
                                    icon:
                                        Icons.admin_panel_settings_outlined,
                                    label: 'Panel de administración',
                                    color: Colors.purple,
                                    onTap: () => Navigator.pushNamed(
                                        context, AppRoutes.admin),
                                  ),
                                  const SettingsDivider(),
                                ]);
                              },
                            ),
                            ActionTile(
                              icon: Icons.person_outline,
                              label: 'Editar perfil',
                              color: AppColors.accent,
                              onTap: _handleEditProfile,
                            ),
                            const SettingsDivider(),
                            ActionTile(
                              icon: Icons.shield_outlined,
                              label: 'Privacidad y datos',
                              color: AppColors.accent,
                              onTap: () => PrivacyInfoSheet.show(context),
                            ),
                            const SettingsDivider(),
                            ActionTile(
                              icon: Icons.logout,
                              label: 'Cerrar sesión',
                              color: Colors.red,
                              onTap: _signOut,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        Center(
                          child: Text(
                            'Aikōra Sora v1.0.0 · Hecho con ❤️ en Cartagena',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Widgets internos mejorados

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      );

  Widget _buildUnsavedBanner() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -20, end: 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.15),
              Colors.amber.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.info_outline, color: Colors.amber, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tienes cambios sin guardar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _handleSavePreferences,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Guardar ahora',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final activePrefs = [
      _ctrl.likesNature,
      _ctrl.likesCulture,
      _ctrl.likesFood,
      _ctrl.likesAdventure,
      _ctrl.likesBeach,
    ].where((v) => v).length;

    return Row(
      children: [
        Expanded(
          child: _PremiumStatChip(
            icon: Icons.favorite_outline,
            label: 'Intereses activos',
            value: '$activePrefs / 5',
            isDark: isDark,
            gradientColors: [const Color(0xFFE91E63), const Color(0xFFFF9800)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PremiumStatChip(
            icon: Icons.attach_money,
            label: 'Presupuesto diario',
            value: '\$${_ctrl.budget.toInt()}',
            isDark: isDark,
            gradientColors: [const Color(0xFF4CAF50), const Color(0xFF009688)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PremiumStatChip(
            icon: Icons.language,
            label: 'Idioma',
            value: ProfileController
                    .languages[_ctrl.selectedLanguage]
                    ?.split(' ')
                    .last ??
                'ES',
            isDark: isDark,
            gradientColors: [const Color(0xFF2196F3), const Color(0xFF9C27B0)],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelStyleCard(bool isDark) {
    final style = _ctrl.buildTravelStyle();
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withOpacity(0.2),
              AppColors.accent.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accent.withOpacity(0.7)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Tu perfil de viajero',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    style.isNotEmpty ? style : 'Viajero equilibrado',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Basado en tus preferencias de viaje',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 340, // Aumentado ligeramente
      pinned: true,
      backgroundColor: const Color(0xFF0B1C2D),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0B1C2D),
                const Color(0xFF0F2744),
                AppColors.accent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center( // ← IMPORTANTE: Centrar todo el contenido
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar con animación
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: _handleEditAvatar,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: AppColors.accent.withOpacity(0.2),
                              backgroundImage: _ctrl.avatarUrl != null
                                  ? NetworkImage(_ctrl.avatarUrl!)
                                  : null,
                              child: _ctrl.avatarUrl == null
                                  ? Text(
                                      _ctrl.initials,
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nombre
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _ctrl.fullName,
                      key: ValueKey(_ctrl.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _ctrl.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Badge miembro desde
                  if (_ctrl.memberSince.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            _ctrl.memberSince,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Premium Stat Chip
class _PremiumStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final List<Color> gradientColors;

  const _PremiumStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors.first.withOpacity(0.15),
            gradientColors.last.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradientColors.first.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para opciones de selección de avatar (colocar fuera de la clase)
class _AvatarPickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AvatarPickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// Premium Toast
class _PremiumToast extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _PremiumToast({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Particle Background
class ParticleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1);
    for (int i = 0; i < 50; i++) {
      final x = (i * 73) % size.width;
      final y = (i * 37) % size.height;
      final radius = (i % 3 + 1).toDouble();
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}