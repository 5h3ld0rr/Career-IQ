import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/core/theme.dart';
import 'package:careeriq/widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(_emailController.text, _passwordController.text);
    if (authProvider.isAuthenticated && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.googleLogin();
    if (authProvider.isAuthenticated && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: Stack(
        children: [
          _buildBaseLayer(context),
          ..._buildBackgroundDecor(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGlassBox(
                      context,
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.work_rounded,
                        color: Color(0xFF03A9F4),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to continue your career journey.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildGlassBox(
                      context,
                      child: Column(
                        children: [
                          _buildTextField(
                            context,
                            _emailController,
                            'Email Address',
                            Icons.email_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            context,
                            _passwordController,
                            'Password',
                            Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).showNotification(
                                    "Enter your email to reset password",
                                    isError: true,
                                  );
                                } else {
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).resetPassword(email);
                                }
                              },
                              child: const Text(
                                'Forgot?',
                                style: TextStyle(
                                  color: Color(0xFF03A9F4),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPrimaryButton(isLoading, _handleLogin, 'LOGIN'),
                          const SizedBox(height: 24),
                          Text(
                            'OR',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildGoogleButton(isLoading),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'First time here?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            'Join Now',
                            style: TextStyle(
                              color: Color(0xFF0288D1),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseLayer(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFE1F5FE)
                : const Color(0xFF1E293B),
            AppTheme.getScaffoldColor(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundDecor() {
    return [
      Positioned(
        top: -150,
        right: -100,
        child: Container(
          width: 500,
          height: 500,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF81D4FA).withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -200,
        left: -150,
        child: Container(
          width: 600,
          height: 600,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF03A9F4).withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildGlassBox(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 30,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.light
                  ? 0.04
                  : 0.2,
            ),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.35),
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF03A9F4), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    bool isLoading,
    VoidCallback onPressed,
    String label,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF03A9F4).withValues(alpha: 0.1),
          foregroundColor: const Color(0xFF03A9F4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF03A9F4), width: 1.5),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF03A9F4),
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return GoogleSignInButton(
      isLoading: isLoading,
      onPressed: _handleGoogleLogin,
      label: 'Continue with Google',
    );
  }
}
