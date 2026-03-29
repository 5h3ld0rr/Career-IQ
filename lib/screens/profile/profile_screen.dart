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
                    actions: const [],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProfileHeader(context, authProvider),
                        const SizedBox(height: 24),
                        _buildCompletenessCheck(context, authProvider),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'Resume'),
                        _buildGlassBox(
                          context,
                          child: _buildResumeSection(context, authProvider),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle(
                          context,
                          'Skills',
                          onEdit: () =>
                              _showEditSkillsDialog(context, authProvider),
                        ),
                        _buildSkillsSection(context, authProvider),
                        const SizedBox(height: 32),
                        _buildSectionTitle(
                          context,
                          'About',
                          onEdit: () =>
                              _showEditProfileDialog(context, authProvider),
                        ),
                        _buildGlassBox(
                          context,
                          child: Text(
                            authProvider.bio ??
                                'Add a short bio about yourself to stand out to employers.',
                            style: TextStyle(
                              color: authProvider.bio != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                        const SizedBox(height: 120),
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

  Widget _buildCompletenessCheck(BuildContext context, AuthProvider auth) {
    int percentage = 0;
    if (auth.resumeUrl != null) percentage += 40;
    if (auth.skills.isNotEmpty) percentage += 30;
    if (auth.bio != null && auth.bio!.isNotEmpty) percentage += 30;

    return _buildGlassBox(
      context,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Strength',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: percentage == 100
                      ? Colors.green
                      : AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Theme.of(context).colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage == 100 ? Colors.green : AppTheme.primaryBlue,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Text(
            percentage == 100
                ? 'Your profile is perfect! You are 2x more likely to be hired.'
                : 'Complete your profile to increase your visibility to recruiters.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
                child: auth.isLoading && auth.profilePictureUrl == null
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : CircleAvatar(
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
              if (auth.isLoading && auth.profilePictureUrl != null)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Current Role / Experience',
                ),
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
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                children: tempSkills
                    .map(
                      (s) => Chip(
                        label: Text(s),
                        onDeleted: () =>
                            setDialogState(() => tempSkills.remove(s)),
                      ),
                    )
                    .toList(),
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

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    VoidCallback? onEdit,
  }) {
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
    return _buildGlassBox(
      context,
      padding: const EdgeInsets.all(16),
      child: auth.isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: 12),
                    Text(
                      "Uploading to Cloud...",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                _buildIconBox(
                  context,
                  auth.resumeUrl != null
                      ? Icons.article_rounded
                      : Icons.upload_file_rounded,
                  auth.resumeUrl != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.resumeFileName ?? "Upload Professional CV",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.resumeUploadedAt != null
                            ? "Last updated: ${auth.resumeUploadedAt!.toString().split(' ')[0]}"
                            : "Supported: PDF, DOC, DOCX",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
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
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        auth.resumeUrl != null
                            ? Icons.edit_document
                            : Icons.cloud_upload_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIconBox(BuildContext context, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
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
            (s) =>
                _buildGlassPill(context, s, isPlaceholder: auth.skills.isEmpty),
          )
          .toList(),
    );
  }

  Widget _buildGlassPill(
    BuildContext context,
    String text, {
    bool isPlaceholder = false,
  }) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            themeProvider.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          title: Text(
            'Dark Mode',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Transform.scale(
            scale: 0.8,
            child: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(),
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
          indent: 50,
        ),

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
            final jobProvider = Provider.of<JobProvider>(
              context,
              listen: false,
            );
            await jobProvider.seedDatabase(auth.userId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database seeded with new categories!'),
                ),
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
