import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/core/providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';

import 'package:careeriq/features/profile/screens/edit_profile_screen.dart';
import 'package:careeriq/features/recruiter/screens/billing_subscription_screen.dart';
import '../../recruiter/screens/organization_settings_screen.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final isRecruiter = authProvider.isRecruiter;
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
                    automaticallyImplyLeading: false,
                    title: const Text('Profile'),
                    actions: const [],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProfileHeader(context, authProvider),
                        const SizedBox(height: 24),
                        if (true) ...[
                          if (!authProvider.isRecruiter) ...[
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
                              onSync: authProvider.resumeUrl != null
                                  ? () => authProvider.syncSkillsFromResume()
                                  : null,
                            ),
                            _buildSkillsSection(context, authProvider),
                            const SizedBox(height: 32),
                          ],
                          _buildSectionTitle(
                            context,
                            isRecruiter ? 'Company Description' : 'About',
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          _buildGlassBox(
                            context,
                            child: Text(
                              (isRecruiter
                                      ? (authProvider.companyDescription ??
                                          authProvider.bio)
                                      : authProvider.bio) ??
                                  (isRecruiter
                                      ? 'Add a short description about your company.'
                                      : 'Add a short bio about yourself to stand out to employers.'),
                              style: TextStyle(
                                color: (isRecruiter
                                            ? (authProvider.companyDescription ??
                                                authProvider.bio)
                                            : authProvider.bio) !=
                                        null
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
                        ],
                        if (authProvider.isRecruiter) ...[
                          _buildSectionTitle(context, 'Hiring Tools'),
                          _buildGlassBox(
                            context,
                            padding: const EdgeInsets.all(8),
                            child: _buildFeaturesMenu(context, authProvider),
                          ),
                          const SizedBox(height: 32),
                        ],
                        _buildSectionTitle(context, 'System'),
                        _buildGlassBox(
                          context,
                          padding: const EdgeInsets.all(8),
                          child: _buildSystemMenu(context, authProvider),
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
    if (auth.resumeUrl != null) percentage += 20;
    if (auth.skills.isNotEmpty) percentage += 20;
    if (auth.bio != null && auth.bio!.isNotEmpty) percentage += 20;
    if (auth.isEmailVerified) percentage += 20;
    if (auth.isPhoneVerified) percentage += 20;

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
          behavior: HitTestBehavior.opaque,
          onTap: () => _showImagePickerOptions(context, auth),
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
                                auth.userName?.substring(0, 1).toUpperCase() ??
                                    'U',
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showImagePickerOptions(context, auth),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          auth.userName ?? (auth.isRecruiter ? 'Company Name' : 'User Name'),
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
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
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
    VoidCallback? onSync,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onSync != null)
                IconButton(
                  tooltip: "Sync from CV",
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  onPressed: onSync,
                  visualDensity: VisualDensity.compact,
                  color: AppTheme.primaryBlue,
                ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
            ],
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                      : Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
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

  Widget _buildFeaturesMenu(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        if (auth.isRecruiter) ...[
          _buildMenuTile(
            context,
            Icons.credit_card_rounded,
            'Billing & Subscription',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BillingSubscriptionScreen(),
                ),
              );
            },
          ),
          _buildMenuTile(
            context,
            Icons.business_rounded,
            'Organization Settings',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrganizationSettingsScreen()),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSystemMenu(BuildContext context, AuthProvider auth) {
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
          Icons.refresh_rounded,
          'Reset System Data',
          () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset Everything?'),
                content: const Text(
                  'This will clear your applications, saved jobs, CV and profile details. This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Reset', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirmed == true && auth.userId != null) {
              final jobProvider = Provider.of<JobProvider>(
                context,
                listen: false,
              );
              await jobProvider.seedDatabase(
                auth.userId!,
                isRecruiter: auth.isRecruiter,
              );
              auth.resetLocalData();
              if (context.mounted) {
                AppSnackBar.show('System data reset successfully!');
              }
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

  void _showImagePickerOptions(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Update Profile Picture',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    context,
                    Icons.camera_alt_rounded,
                    'Camera',
                    () => _pickImage(context, ImageSource.camera, auth),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerOption(
                    context,
                    Icons.photo_library_rounded,
                    'Gallery',
                    () => _pickImage(context, ImageSource.gallery, auth),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
    AuthProvider auth,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        await auth.updateProfilePicture(bytes, image.name);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }
}
