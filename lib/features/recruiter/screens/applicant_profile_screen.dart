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

    // ── Correct Firestore field names ──
    final String name = user['name'] ?? user['fullName'] ?? 'Unknown Applicant';
    final String headline = user['role'] ?? user['currentRole'] ?? '';
    final String email = user['email'] ?? '';
    final String phone = user['phoneNumber'] ?? user['phone'] ?? '';
    final String location = user['location'] ?? '';
    final String bio = user['bio'] ?? user['about'] ?? '';
    final String exp = user['experience'] ?? ''; // stored as plain text string
    final String resumeUrl =
        candidateData['resumeUrl'] ?? user['resumeUrl'] ?? '';
    final String stage = candidateData['status'] ?? 'New Applied';

    final List<String> skills = List<String>.from(user['skills'] ?? []);

    // Initials
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
          // ── Fixed app bar (no flexible space, no overflow) ──
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
    ThemeData theme,
  ) {
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
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
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
                    const SizedBox(width: 10),
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
    switch (stage) {
      case 'Hired':
        return Colors.green;
      case 'Shortlisted':
        return Colors.blue;
      case 'Interviewing':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
