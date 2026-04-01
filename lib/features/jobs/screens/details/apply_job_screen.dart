import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/notifications/providers/notification_provider.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';
import 'package:careeriq/core/theme/theme.dart';


class ApplyJobScreen extends StatefulWidget {
  final Job job;
  const ApplyJobScreen({super.key, required this.job});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  File? _selectedResume;
  String? _resumeName;
  bool _useProfileResume = false;
  final TextEditingController _coverLetterController = TextEditingController();

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedResume = File(result.files.single.path!);
          _resumeName = result.files.single.name;
          _useProfileResume = false;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _submitApplication() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!_useProfileResume && _selectedResume == null) {
      AppSnackBar.show('Please upload your resume to continue', isError: true);
      return;
    }

    if (auth.userId == null) {
      AppSnackBar.show('Please login to apply', isError: true);
      return;
    }

    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);

      await jobProvider.submitApplication(
        userId: auth.userId!,
        jobId: widget.job.id,
        resumeFile: _useProfileResume ? null : _selectedResume,
        useProfileResume: _useProfileResume,
        coverLetter: _coverLetterController.text.trim(),
      );

      if (mounted) {
        final notifProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );

        final recruiterId = widget.job.postedBy;
        if (recruiterId != null && recruiterId.isNotEmpty) {
          final applicantName = auth.userName ?? 'A candidate';
          await notifProvider.pushService?.simulateNotification(
            'New Application!',
            '$applicantName applied for ${widget.job.title}',
            'recruiter_application',
            recruiterId,
            route: '/ats/${widget.job.id}',
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show('Failed to apply: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          child: _buildGlassIconButton(
            context,
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Submit Application',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJobSummaryCard(context),
                    const SizedBox(height: 48),
                    _buildSectionHeader(context, 'Your Resume'),
                    const SizedBox(height: 16),
                    if (auth.resumeUrl != null) ...[
                      _buildProfileResumeOption(auth),
                      const SizedBox(height: 16),
                    ],
                    if (!_useProfileResume) ...[_buildUploadArea(context)],
                    const SizedBox(height: 40),
                    _buildSectionHeader(context, 'Cover Letter (Optional)'),
                    const SizedBox(height: 16),
                    _buildCoverLetterField(context),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSubmitAction(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getGlassColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.getGlassBorderColor(context),
              width: 1.5,
            ),
          ),
          child: IconButton(icon: Icon(icon, size: 16), onPressed: onTap),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF03A9F4).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF81D4FA).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassBox(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 24,
    double? borderOpacity,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(
            context,
          ).withValues(alpha: borderOpacity ?? 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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

  Widget _buildJobSummaryCard(BuildContext context) {
    return _buildGlassBox(
      context,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Image.network(
              widget.job.logoUrl,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.business_rounded, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.job.companyName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileResumeOption(AuthProvider auth) {
    return GestureDetector(
      onTap: () => setState(() => _useProfileResume = !_useProfileResume),
      child: _buildGlassBox(
        context,
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        borderOpacity: _useProfileResume ? 1.0 : 0.4,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_pin_rounded,
                color: const Color(0xFF00BFA5),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Use Profile Resume',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Text(
                    auth.resumeFileName ?? 'Resume from your profile',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _useProfileResume,
                onChanged: (val) => setState(() => _useProfileResume = val),
                activeThumbColor: const Color(0xFF00BFA5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    return GestureDetector(
      onTap: _pickResume,
      child: _buildGlassBox(
        context,
        borderRadius: 20,
        borderOpacity: _selectedResume != null ? 1.0 : 0.4,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      (_selectedResume != null
                              ? const Color(0xFF03A9F4)
                              : Colors.grey)
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedResume != null
                      ? Icons.task_rounded
                      : Icons.cloud_upload_outlined,
                  size: 40,
                  color: _selectedResume != null
                      ? const Color(0xFF03A9F4)
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _selectedResume != null
                    ? _resumeName!
                    : 'Tap to upload or pick a file',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _selectedResume != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_selectedResume == null) ...[
                const SizedBox(height: 8),
                const Text(
                  'PDF, DOC, or DOCX (Max 5MB)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Tap to change file',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverLetterField(BuildContext context) {
    return _buildGlassBox(
      context,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _coverLetterController,
        maxLines: 6,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Write why you are a good fit for this role...',
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBottomSubmitAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.getGlassColor(context).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.getGlassBorderColor(context),
                width: 1.5,
              ),
            ),
            child: Consumer2<AuthProvider, JobProvider>(
              builder: (context, auth, jobProv, _) {
                final isSubmitting = jobProv.isLoading;
                return Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF03A9F4), Color(0xFF0288D1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF03A9F4).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'SUBMIT APPLICATION',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
