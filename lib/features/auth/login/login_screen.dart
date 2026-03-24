// lib/features/auth/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'google_sign_in_button.dart';
import '../forgot_password/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.signInWithEmail (
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
        _showSnackBar('¡Bienvenido de vuelta! ✨', true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      String errorMessage = 'Error al iniciar sesión. Verifica tus credenciales.';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Correo o contraseña incorrectos.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Confirma tu correo electrónico antes de iniciar sesión.';
      }
      
      _showSnackBar(errorMessage, false);
    }
  }

  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070E17) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111D2E) : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.flight_takeoff_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Aikōra Sora',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Inicia sesión para continuar',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Formulario
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Correo electrónico',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'tu@email.com',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey[400],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppColors.error),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa tu correo electrónico';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Contraseña',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                ),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey[400],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppColors.error),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa tu contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Olvidé mi contraseña
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botón login
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Divisor
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'O continúa con',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Google Sign In
                        const GoogleSignInButton(),
                        
                        const SizedBox(height: 24),
                        
                        // Registro
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes una cuenta?',
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, AppRoutes.register);
                              },
                              child: Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Modo oscuro toggle
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode : Icons.light_mode,
                                size: 16,
                                color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => themeProvider.toggleTheme(!isDark),
                                child: Container(
                                  width: 44,
                                  height: 24,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: AnimatedAlign(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDark ? 'Modo oscuro' : 'Modo claro',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[500],
                                ),
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
          ),
        ),
      ),
    );
  }
}