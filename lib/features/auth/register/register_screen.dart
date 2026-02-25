import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();
  final _authService        = AuthService();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Registro con email ──────────────────────────────────────────────────────
  Future<void> _registerWithEmail() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _showErrorSnackBar('Completa todos los campos');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showErrorSnackBar('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      _showSuccessSnackBar('¡Cuenta creada! Revisa tu email para confirmar.');
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Registro con Google ─────────────────────────────────────────────────────
  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _showErrorSnackBar('Error con Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 🔑 CLAVE: leemos el tema actual en cada rebuild
    final theme      = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark     = theme.brightness == Brightness.dark;

    return Scaffold(
      // El Scaffold ya hereda el color de fondo del tema (claro u oscuro)
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // En dark mode fondo muy oscuro; en light el azul original
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFF0B1C2D), const Color(0xFF0F2744)],
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 16),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white70),
                        ),
                      ),
                    ),
                    Image.asset('assets/logo/app_icon.png',
                        height: 70, width: 70),
                    const SizedBox(height: 16),
                    const Text(
                      'Crea tu cuenta',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Únete y empieza a explorar el mundo',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ── Formulario ────────────────────────────────────────────────
              Container(
                // 🔑 ANTES era Colors.white fijo → ahora usa el color del tema
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildTextField(
                      context: context,
                      controller: _nameController,
                      label: 'Nombre completo',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context: context,
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context: context,
                      controller: _passwordController,
                      label: 'Contraseña (mínimo 6 caracteres)',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          // 🔑 color adaptable al tema
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón registrarse
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Registrarse',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Separador
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o continúa con',
                              // 🔑 color adaptable
                              style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 13)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón Google
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _registerWithGoogle,
                        style: OutlinedButton.styleFrom(
                          // 🔑 borde adaptable al tema
                          side: BorderSide(color: colorScheme.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google.png',
                                height: 22, width: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Continuar con Google',
                              // 🔑 texto adaptable al tema
                              style: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Link a login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿Ya tienes cuenta? ',
                            // 🔑 adaptable
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6))),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context, AppRoutes.login),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget helper ────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required BuildContext context,       // 🔑 nuevo parámetro
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      // 🔑 ESTO es lo que faltaba: el color del texto sigue al tema
      style: TextStyle(color: colorScheme.onSurface),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        // 🔑 label visible en ambos modos
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          // 🔑 borde usa el color del tema
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        filled: true,
        // 🔑 fondo del field usa la superficie del tema
        fillColor: colorScheme.surface,
      ),
    );
  }
}
