import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:elitehire/providers/auth_provider.dart';
import 'package:elitehire/core/theme.dart';
import 'package:elitehire/providers/theme_provider.dart';
import 'ai_tips_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildGlassBox(
                    borderRadius: 50,
                    padding: const EdgeInsets.all(4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                title: const Text('Profile'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildGlassBox(
                      borderRadius: 50,
                      padding: const EdgeInsets.all(4),
                      child: IconButton(
                        icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
                        onPressed: () => themeProvider.toggleTheme(),
                      ),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileHeader(authProvider),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Resume'),
                    _buildGlassBox(child: _buildResumeSection()),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Skills'),
                    _buildSkillsSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Elite Actions'),
                    _buildGlassBox(padding: const EdgeInsets.all(8), child: _buildActionsMenu(context, authProvider)),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: 150,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [const Color(0xFF81D4FA).withOpacity(0.35), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child, EdgeInsets? padding, double borderRadius = 24}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider auth) {
    return Column(
      children: [
        _buildGlassBox(
          borderRadius: 100,
          padding: const EdgeInsets.all(4),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              auth.userName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF03A9F4)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(auth.userName ?? 'User Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const Text('Senior Product Designer', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
    );
  }

  Widget _buildResumeSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.description_rounded, color: Color(0xFF03A9F4), size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My_Resume.pdf', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              Text('Uploaded on Mar 12, 2024', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const Icon(Icons.file_upload_outlined, color: Colors.black45),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final List<String> skills = ['UI Design', 'UX Research', 'Flutter', 'Figma', 'Prototyping'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skills.map((s) => _buildGlassBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 12,
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black87)),
      )).toList(),
    );
  }

  Widget _buildActionsMenu(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        _buildMenuTile(Icons.psychology_rounded, 'AI Resume Analysis', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIResumeTipsScreen()))),
        _buildMenuTile(Icons.history_rounded, 'Application History', () {}),
        _buildMenuTile(Icons.notifications_none_rounded, 'Notifications', () {}),
        _buildMenuTile(Icons.logout_rounded, 'Logout', () {
          auth.logout();
          Navigator.pushReplacementNamed(context, '/login');
        }, isDestructive: true),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : const Color(0xFF03A9F4), size: 22),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDestructive ? Colors.redAccent : Colors.black87)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
    );
  }
}
