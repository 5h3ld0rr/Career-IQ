import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';

class ApplicantProfileScreen extends StatelessWidget {
  final Map<String, dynamic> candidateData;

  const ApplicantProfileScreen({super.key, required this.candidateData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Map<String, dynamic>.from(candidateData['user'] ?? {});

    final String name = user['name'] ?? user['fullName'] ?? 'Unknown Applicant';
    final String headline = user['role'] ?? user['currentRole'] ?? '';
    final String email = user['email'] ?? '';
    final String phone = user['phoneNumber'] ?? user['phone'] ?? '';
    final String location = user['location'] ?? '';
    final String bio = user['bio'] ?? user['about'] ?? '';
    final String exp = user['experience'] ?? '';
    final String resumeUrl =
        candidateData['resumeUrl'] ?? user['resumeUrl'] ?? '';
    final String stage = candidateData['status'] ?? 'New Applied';

    final List<String> skills = List<String>.from(user['skills'] ?? []);

    final String? photoUrl = user['photoUrl'] ?? user['profilePictureUrl'];
    String initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (name.contains(' ')) {
      final parts = name.trim().split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials = parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
      }
    }

    final stageColor = _stageColor(stage);

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.getScaffoldColor(context),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero card ──
                  _heroCard(
                    context,
                    initials,
                    name,
                    headline,
                    stage,
                    stageColor,
                    resumeUrl,
                    theme,
                    photoUrl: photoUrl,
                  ),
                  const SizedBox(height: 20),

                  // ── Contact ──
                  if (email.isNotEmpty ||
                      phone.isNotEmpty ||
                      location.isNotEmpty)
                    _section(
                      context,
                      icon: Icons.contact_mail_rounded,
                      title: 'Contact',
                      child: Column(
                        children: [
                          if (email.isNotEmpty)
                            _infoRow(context, Icons.email_rounded, email),
                          if (phone.isNotEmpty)
                            _infoRow(context, Icons.phone_rounded, phone),
                          if (location.isNotEmpty)
                            _infoRow(
                              context,
                              Icons.location_on_rounded,
                              location,
                            ),
                        ],
                      ),
                    ),

                  if (email.isNotEmpty ||
                      phone.isNotEmpty ||
                      location.isNotEmpty)
                    const SizedBox(height: 16),

                  // ── About / Bio ──
                  if (bio.isNotEmpty) ...[
                    _section(
                      context,
                      icon: Icons.person_rounded,
                      title: 'About',
                      child: Text(
                        bio,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Experience (plain text) ──
                  if (exp.isNotEmpty) ...[
                    _section(
                      context,
                      icon: Icons.work_rounded,
                      title: 'Experience',
                      child: Text(
                        exp,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Skills ──
                  if (skills.isNotEmpty) ...[
                    _section(
                      context,
                      icon: Icons.workspace_premium_rounded,
                      title: 'Skills',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills
                            .map((s) => _skillChip(context, s))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── No data fallback ──
                  if (bio.isEmpty &&
                      exp.isEmpty &&
                      skills.isEmpty &&
                      email.isEmpty &&
                      phone.isEmpty &&
                      location.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 52,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This applicant has not filled their profile yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (resumeUrl.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _launchUrl(resumeUrl),
                                icon: const Icon(Icons.description_rounded),
                                label: const Text('View Resume Instead'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: (stage.toLowerCase() != 'rejected' &&
                stage.toLowerCase() != 'hired')
            ? _buildBottomAction(context, name, stage)
            : null,
      );
    }

  // ── Hero profile card ──
  Widget _heroCard(
    BuildContext context,
    String initials,
    String name,
    String headline,
    String stage,
    Color stageColor,
    String resumeUrl,
    ThemeData theme, {
    String? photoUrl,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getGlassColor(context).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.getGlassBorderColor(context)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              if (headline.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: stageColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: stageColor),
                        const SizedBox(width: 6),
                        Text(
                          stage,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: stageColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (resumeUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _launchUrl(resumeUrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'View CV',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, String name, String stage) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF9100),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: () => _showScheduleModal(
          context,
          name,
          stage,
          candidateData['applicationId'] ?? '',
        ),
        icon: const Icon(Icons.fact_check_rounded, size: 20),
        label: const Text(
          'Application Outcome',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  // ── Section card ──
  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.getGlassColor(context).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.getGlassBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: theme.colorScheme.primary),
                  const SizedBox(width: 7),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillChip(BuildContext context, String skill) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Color _stageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'hired':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'interviewing':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'pending':
      case 'new applied':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showScheduleModal(
    BuildContext context,
    String name,
    String currentStage,
    String applicationId,
  ) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    bool? passed;
    final remarksCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(ctx).padding.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Application Outcome',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'CV & APPLICATION OUTCOME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOutcomeToggle(
                            context,
                            label: 'Passed',
                            icon: Icons.check_circle_rounded,
                            color: Colors.green,
                            selected: passed == true,
                            onTap: () => setModalState(() => passed = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOutcomeToggle(
                            context,
                            label: 'Failed',
                            icon: Icons.cancel_rounded,
                            color: Colors.red,
                            selected: passed == false,
                            onTap: () => setModalState(() => passed = false),
                          ),
                        ),
                      ],
                    ),
                    if (passed == true) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'SCHEDULE INTERVIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildScheduleRow(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value:
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        color: const Color(0xFFFF9100),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildScheduleRow(
                        context,
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: selectedTime.format(context),
                        color: const Color(0xFF03A9F4),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                      ),
                    ],
                    if (passed != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'REMARKS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Add screening notes...',
                          filled: true,
                          fillColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                passed! ? Colors.green : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            final provider = Provider.of<JobProvider>(
                              context,
                              listen: false,
                            );
                            final data = {
                              if (passed!) ...{
                                'interviewDate': selectedDate,
                                'interviewTime':
                                    '${selectedTime.hour}:${selectedTime.minute}',
                              },
                              'remarks': remarksCtrl.text,
                              'lastResultAt': DateTime.now(),
                            };
                            provider.updateApplicationStatus(
                              applicationId,
                              passed! ? 'Interviewing' : 'Rejected',
                              data: data,
                            );
                            Navigator.pop(context);
                            AppSnackBar.show(
                              passed!
                                  ? 'Interview scheduled for $name'
                                  : 'Application rejected',
                              isError: !passed!,
                            );
                          },
                          child: Text(
                            passed! ? 'Confirm & Schedule' : 'Confirm Rejection',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutcomeToggle(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      AppSnackBar.show('No CV link available.', isError: true);
      return;
    }
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      AppSnackBar.show('Could not open CV. Try again.', isError: true);
    }
  }
}
