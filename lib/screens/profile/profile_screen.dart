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
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.secondaryBlue,
              child: Text(
                authProvider.userName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.userName ?? 'User Name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Senior Product Designer',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            _buildProfileSection(
              context,
              title: 'Resume',
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.mediumGray.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.lightGray.withOpacity(0.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My_Resume.pdf',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Uploaded on Mar 12, 2024',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_upload_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileSection(
              context,
              title: 'Skills',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSkillChip('UI Design'),
                  _buildSkillChip('UX Research'),
                  _buildSkillChip('Flutter'),
                  _buildSkillChip('Figma'),
                  _buildSkillChip('Prototyping'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileSection(
              context,
              title: 'Account',
              child: Column(
                children: [
                  _buildMenuTile(
                    Icons.auto_awesome_rounded,
                    'AI Resume Tips',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AIResumeTipsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(Icons.history_rounded, 'Application History'),
                  _buildMenuTile(Icons.lock_outline_rounded, 'Change Password'),
                  _buildMenuTile(
                    Icons.logout_rounded,
                    'Logout',
                    isDestructive: true,
                    onTap: () {
                      authProvider.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.error : AppTheme.darkGray,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.error : AppTheme.darkGray,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.mediumGray,
      ),
    );
  }
}
