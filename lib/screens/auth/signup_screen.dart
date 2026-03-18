import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/core/theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _handleSignUp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signUp(_nameController.text, _emailController.text, _passwordController.text);
    if (authProvider.isAuthenticated) {
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } else if (authProvider.error != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error!), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
    }
  }

  void _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.googleLogin();
    if (authProvider.isAuthenticated) {
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } else if (authProvider.error != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error!), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildGlassBox(
                    borderRadius: 50,
                    padding: const EdgeInsets.all(4),
                    child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16), onPressed: () => Navigator.pop(context)),
                  ),
                  const SizedBox(height: 40),
                  const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('Start your journey to find your dream job.', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 40),
                  _buildGlassBox(
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Full Name', Icons.person_outline_rounded),
                        const SizedBox(height: 16),
                        _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
                        const SizedBox(height: 16),
                        _buildTextField(_passwordController, 'Password', Icons.lock_outline_rounded, isPassword: true),
                        const SizedBox(height: 32),
                        _buildPrimaryButton(isLoading, _handleSignUp, 'JOIN ELITE'),
                        const SizedBox(height: 24),
                        const Text('OR', style: TextStyle(color: Colors.black26, fontWeight: FontWeight.w900, fontSize: 12)),
                        const SizedBox(height: 24),
                        _buildGoogleButton(isLoading),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      bottom: -100,
      left: -100,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF81D4FA).withOpacity(0.3), Colors.transparent])),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child, EdgeInsets? padding, double borderRadius = 30}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(padding: padding ?? const EdgeInsets.all(24), child: child),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.35), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.black38),
          suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black38), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isLoading, VoidCallback onPressed, String label) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03A9F4).withOpacity(0.1), foregroundColor: const Color(0xFF03A9F4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF03A9F4), width: 1.5))),
        child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF03A9F4))) : Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.3), foregroundColor: Colors.black, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        icon: const Icon(Icons.g_mobiledata, size: 30),
        label: const Text('GOOGLE SIGN UP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }
}
