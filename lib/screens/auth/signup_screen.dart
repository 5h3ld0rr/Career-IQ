import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/core/theme.dart';
import 'package:careeriq/widgets/google_sign_in_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'Job Seeker'; // Default role

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to safely access the route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? roleArgument = ModalRoute.of(context)?.settings.arguments as String?;
      if (roleArgument != null) {
        setState(() {
          _selectedRole = roleArgument;
        });
      }
    });
  }

  void _handleSignUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        (_selectedRole == 'Recruiter' && _companyController.text.isEmpty)) {
      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).showNotification("Please fill all fields", isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).showNotification("Passwords do not match", isError: true);
      return;
    }

    final password = _passwordController.text;

    // Complex validation: 8+ chars, 1 lower, 1 upper, 1 digit, 1 special
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    if (!hasMinLength ||
        !hasUppercase ||
        !hasLowercase ||
        !hasDigits ||
        !hasSpecialCharacters) {
      Provider.of<AuthProvider>(context, listen: false).showNotification(
        "Password needs: 8+ chars, uppercase, lowercase, number, and special character",
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      role: _selectedRole,
      companyName: _selectedRole == 'Recruiter' ? _companyController.text : null,
    );

    if (success && mounted) {
      // Return to login screen
      Navigator.pop(context);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildGlassBox(
                    context,
                    borderRadius: 50,
                    padding: const EdgeInsets.all(4),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your journey to find your dream job.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRoleSwitcher(),
                  const SizedBox(height: 32),
                  _buildGlassBox(
                    context,
                    child: Column(
                      children: [
                        _buildTextField(
                          context,
                          _nameController,
                          'Full Name',
                          Icons.person_outline_rounded,
                        ),
                        _buildTextField(
                          context,
                          _emailController,
                          'Email Address',
                          Icons.email_outlined,
                        ),
                        if (_selectedRole == 'Recruiter')
                          _buildTextField(
                            context,
                            _companyController,
                            'Company Name',
                            Icons.business_rounded,
                          ),
                        _buildTextField(
                          context,
                          _passwordController,
                          'Password',
                          Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        _buildTextField(
                          context,
                          _confirmPasswordController,
                          'Confirm Password',
                          Icons.lock_reset_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 12),
                        _buildPrimaryButton(
                          isLoading,
                          _handleSignUp,
                          'Register',
                        ),
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
                ],
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
      label: 'Google Sign Up',
    );
  }

  Widget _buildRoleSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSwitcherTab('Job Seeker')),
          Expanded(child: _buildSwitcherTab('Recruiter')),
        ],
      ),
    );
  }

  Widget _buildSwitcherTab(String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF03A9F4) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF03A9F4).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          role,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
