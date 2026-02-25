import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../services/auth_service.dart';

/// Pantalla de inicio de sesión. Soporta dos métodos: email/contraseña y Google OAuth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  // Controladores de texto para leer los valores del formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Servicio de auth inyectado directamente
  final _authService = AuthService();

  bool _isLoading = false; // bloquea botones mientras hay una llamada activa
  bool _obscurePassword = true; // controla si la contraseña se ve o no

  @override
  void dispose() {
    // Liberar controladores al salir para evitar memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Autenticar con email y contraseña. Si tiene éxito, AuthGate detecta el cambio de sesión y navega a Main.
  Future<void> _loginWithEmail() async {
    // Validación mínima antes de hacer llamada a Supabase
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Completa todos los campos');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(), // trim() elimina espacios accidentales
        _passwordController.text.trim(),
      );
      // No se navega aquí: AuthGate escucha onAuthStateChange y redirige solo
    } on AuthException catch (e) {
      // AuthException viene de Supabase con mensaje legible (ej: "Invalid login credentials")
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('Error inesperado: $e');
    } finally {
      // finally se ejecuta siempre, tanto si hubo error como si no
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Autenticar con Google (OAuth externo). Abre el navegador del dispositivo para el flujo de Google.
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      _showSuccessSnackBar('Redirigiendo a Google...');
    } on AuthException catch (e) {
      _showErrorSnackBar('Error: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Error inesperado: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D),
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView evita overflow cuando abre el teclado
          child: Column(
            children: [
              // ── Header oscuro con logo ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0B1C2D), Color(0xFF0F2744)],
                  ),
                ),
                child: Column(
                  children: [
                    // Botón volver (pop cierra el login y regresa al Welcome)
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
                    // ✅ Logo real
                    Image.asset(
                      'assets/logo/app_icon.png',
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bienvenido de vuelta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ── Formulario blanco (card flotante) ─────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  // Bordes redondeados arriba para efecto "sheet" sobre el header
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Campo email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Campo contraseña con toggle de visibilidad
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón principal de login
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        // null deshabilita el botón mientras carga
                        onPressed: _isLoading ? null : _loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            // Spinner mientras procesa la petición
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Ingresar',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divisor visual "o continúa con"
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o continúa con',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botón Google
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo de Google como asset local
                            Image.asset('assets/google.png',
                                height: 22, width: 22),
                            const SizedBox(width: 12),
                            const Text(
                              'Continuar con Google',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Enlace hacia la pantalla de registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿No tienes cuenta? ',
                            style: TextStyle(color: Colors.grey[600])),
                        GestureDetector(
                          // Deshabilitado si hay carga en curso
                          onTap: _isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context, AppRoutes.register),
                          child: const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
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

  /// Widget reutilizable para campos de texto del formulario. Centraliza estilos para que todos los campos se vean igual.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
