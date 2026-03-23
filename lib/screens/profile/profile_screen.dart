import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/core/theme.dart';
import 'package:careeriq/providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:careeriq/providers/job_provider.dart';
import 'ai_tips_screen.dart';
import '../tracker/application_tracker_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
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
                    context,
                    borderRadius: 50,
                    padding: const EdgeInsets.all(4),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                title: const Text('Profile'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildGlassBox(
                      context,
                      borderRadius: 50,
                      padding: const EdgeInsets.all(4),
                      child: IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 20,
                        ),
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
                    _buildProfileHeader(context, authProvider),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Resume'),
                    _buildGlassBox(
                      context,
                      child: _buildResumeSection(context, authProvider),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Skills'),
                    _buildSkillsSection(context),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Elite Actions'),
                    _buildGlassBox(
                      context,
                      padding: const EdgeInsets.all(8),
                      child: _buildActionsMenu(context, authProvider),
                    ),
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
          gradient: RadialGradient(
            colors: [
              const Color(0xFF81D4FA).withValues(alpha: 0.35),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBox(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 24,
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
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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

  Widget _buildProfileHeader(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              withData: true,
            );
            if (result != null && result.files.single.bytes != null) {
              await auth.updateProfilePicture(
                result.files.single.bytes,
                result.files.single.name,
              );
            }
          },
          child: Stack(
            children: [
              _buildGlassBox(
                context,
                borderRadius: 100,
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  backgroundImage: auth.profilePictureUrl != null
                      ? NetworkImage(auth.profilePictureUrl!)
                      : null,
                  child: auth.profilePictureUrl == null
                      ? Text(
                          auth.userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              auth.userName ?? 'User Name',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 18),
              onPressed: () => _showEditNameDialog(context, auth),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(text: auth.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await auth.updateName(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildResumeSection(BuildContext context, AuthProvider auth) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.description_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.resumeFileName ?? 'No resume uploaded',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                auth.resumeUploadedAt != null
                    ? 'Uploaded on ${auth.resumeUploadedAt!.day}/${auth.resumeUploadedAt!.month}/${auth.resumeUploadedAt!.year}'
                    : 'Upload your resume to get started',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            auth.resumeUrl != null
                ? Icons.cloud_done_rounded
                : Icons.file_upload_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx'],
              withData: true,
            );
            if (result != null && result.files.single.bytes != null) {
              await auth.uploadResume(
                result.files.single.bytes,
                result.files.single.name,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final List<String> skills = [
      'UI Design',
      'UX Research',
      'Flutter',
      'Figma',
      'Prototyping',
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skills
          .map(
            (s) => _buildGlassBox(
              context,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 12,
              child: Text(
                s,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionsMenu(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        _buildMenuTile(
          context,
          Icons.psychology_rounded,
          'AI Resume Analysis',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIResumeTipsScreen()),
          ),
        ),
        _buildMenuTile(
          context,
          Icons.history_rounded,
          'Application History',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApplicationTrackerScreen()),
          ),
        ),
        _buildMenuTile(
          context,
          Icons.refresh_rounded,
          'Reset System Data',
          () async {
            final jobProvider = Provider.of<JobProvider>(context, listen: false);
            await jobProvider.seedDatabase(auth.userId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database seeded with new categories!')),
              );
            }
          },
        ),
        _buildMenuTile(context, Icons.logout_rounded, 'Logout', () {
          auth.logout();
          Navigator.pushReplacementNamed(context, '/login');
        }, isDestructive: true),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.redAccent
            : Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: isDestructive
              ? Colors.redAccent
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
