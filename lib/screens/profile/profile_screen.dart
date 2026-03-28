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
import 'package:flutter/services.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Stack(
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
                        _buildSectionTitle(context, 'Skills', onEdit: () => _showEditSkillsDialog(context, authProvider)),
                        _buildSkillsSection(context, authProvider),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'About', onEdit: () => _showEditProfileDialog(context, authProvider)),
                        _buildGlassBox(
                          context,
                          child: Text(
                            authProvider.bio ?? 'Add a short bio about yourself to stand out to employers.',
                            style: TextStyle(
                              color: authProvider.bio != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'Actions'),
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
          );
        },
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
        const SizedBox(height: 12),
        Text(
          auth.userName ?? 'User Name',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (auth.experience != null && auth.experience!.isNotEmpty)
          Text(
            auth.experience!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showEditProfileDialog(context, auth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final nameController = TextEditingController(text: auth.userName);
    final experienceController = TextEditingController(text: auth.experience);
    final bioController = TextEditingController(text: auth.bio);
    final locationController = TextEditingController(text: auth.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(labelText: 'Current Role / Experience'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // Show a brief loading indicator or just update immediately
                final scaffold = ScaffoldMessenger.of(context);
                
                if (nameController.text != auth.userName) {
                   await auth.updateName(nameController.text);
                }
                await auth.updateUserDetails(
                  bio: bioController.text,
                  experience: experienceController.text,
                  location: locationController.text,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditSkillsDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController();
    List<String> tempSkills = List.from(auth.skills);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Skills'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Add Skill',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_rounded),
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        setDialogState(() {
                          tempSkills.add(controller.text.trim());
                          controller.clear();
                        });
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  if (val.isNotEmpty) {
                    setDialogState(() {
                      tempSkills.add(val.trim());
                      controller.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tempSkills.map((s) => Chip(
                  label: Text(s),
                  onDeleted: () => setDialogState(() => tempSkills.remove(s)),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await auth.updateSkills(tempSkills);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
        ],
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

  Widget _buildSkillsSection(BuildContext context, AuthProvider auth) {
    final List<String> skills = auth.skills.isEmpty 
        ? ['Add Skills'] 
        : auth.skills;
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skills
          .map(
            (s) => _buildGlassPill(context, s, isPlaceholder: auth.skills.isEmpty),
          )
          .toList(),
    );
  }

  Widget _buildGlassPill(BuildContext context, String text, {bool isPlaceholder = false}) {
    return _buildGlassBox(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: isPlaceholder 
              ? Theme.of(context).colorScheme.onSurfaceVariant 
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
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
