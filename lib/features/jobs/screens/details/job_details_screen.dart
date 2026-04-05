import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/interview/screens/mock_interview_screen.dart';
import 'package:careeriq/features/jobs/screens/details/ai_cover_letter_screen.dart';
import 'package:careeriq/features/jobs/screens/details/apply_job_screen.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:careeriq/features/cv_analysis/screens/skills_gap_analysis_screen.dart';
import 'package:careeriq/features/cv_analysis/data/resume_text_service.dart';
import 'package:careeriq/features/ai_assistant/providers/ai_provider.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;
  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildCompanyHeader(context),
                    const SizedBox(height: 48),
                    _buildSectionHeader(context, 'Job Description'),
                    const SizedBox(height: 12),
                    Text(
                      job.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildAISection(context),
                    const SizedBox(height: 40),
                    _buildSectionHeader(context, 'Responsibilities'),
                    const SizedBox(height: 20),
                    ...job.responsibilities.map(
                      (res) => _buildListItem(context, res),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'Requirements'),
                    const SizedBox(height: 20),
                    ...job.requirements.map(
                      (req) => _buildListItem(context, req),
                    ),
                    const SizedBox(height: 140),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomApplyAction(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
          child: Consumer2<AuthProvider, JobProvider>(
            builder: (context, auth, jobs, _) => _buildGlassIconButton(
              context,
              icon: job.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: job.isSaved ? Colors.orangeAccent : null,
              onTap: () {
                if (auth.userId != null) {
                  jobs.toggleSaveJob(auth.userId!, job);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
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
          child: IconButton(
            icon: Icon(icon, size: 18, color: color),
            onPressed: onTap,
          ),
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
            fontSize: 18,
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
          top: 100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
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
        Positioned(
          top: 400,
          left: -150,
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

  Widget _buildGlassBox({
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 24,
  }) {
    return Builder(
      builder: (context) {
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
      },
    );
  }

  Widget _buildCompanyHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _buildGlassBox(
            borderRadius: 100,
            padding: const EdgeInsets.all(20),
            child: CachedNetworkImage(
              imageUrl: job.logoUrl,
              width: 60,
              height: 60,
              placeholder: (context, url) =>
                  const CircularProgressIndicator(strokeWidth: 2),
              errorWidget: (context, url, error) => Icon(
                Icons.business_rounded,
                size: 40,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          job.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${job.companyName} • ${job.location}',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassPill(
              context,
              job.jobType,
              Theme.of(context).colorScheme.primary,
              Icons.work_outline_rounded,
            ),
            const SizedBox(width: 12),
            _buildGlassPill(
              context,
              job.salary,
              const Color(0xFF00BFA5),
              Icons.payments_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassPill(
    BuildContext context,
    String text,
    Color color,
    IconData icon,
  ) {
    return _buildGlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Smart Career Tools'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildAICard(
                context,
                icon: Icons.auto_awesome_outlined,
                title: 'Apply with AI',
                subtitle: 'Generate specialized Cover Letter',
                color: const Color(0xFF673AB7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AICoverLetterScreen(
                        jobTitle: job.title,
                        jobDescription: job.description,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAICard(
                context,
                icon: Icons.interpreter_mode_outlined,
                title: 'Mock Interview',
                subtitle: 'Practice for this specific role',
                color: const Color(0xFF0091EA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MockInterviewScreen(
                        initialRole: job.title,
                        initialLevel:
                            job.requirements.any(
                              (r) => r.toLowerCase().contains('senior'),
                            )
                            ? 'Senior'
                            : 'Junior',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAICard(
          context,
          icon: Icons.query_stats_rounded,
          title: 'Detailed Skills Gap',
          subtitle: 'Compare your profile against this role',
          color: const Color(0xFF00BFA5),
          onTap: () => _handleSkillsGapAnalysis(context),
        ),
      ],
    );
  }

  Future<void> _handleSkillsGapAnalysis(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    if (auth.resumeUrl == null) {
      AppSnackBar.show(
        'Please upload your resume in Profile first to check fit',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.getGlassColor(
                      context,
                    ).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3 * value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1 * value),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.onSurface,
                  highlightColor: Theme.of(context).colorScheme.primary,
                  child: const Text(
                    'AI Skill Scan...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Comparing profile with ${job.companyName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final resumeText = await ResumeTextService.extractTextFromUrl(
        auth.resumeUrl!,
      );

      await aiProvider.analyzeSkillsGap(
        resumeContent: resumeText.isNotEmpty
            ? resumeText
            : "Profile content for ${auth.userName}. Analyze based on available data.",
        jobDescription: job.description,
      );

      if (context.mounted) Navigator.pop(context);

      if (context.mounted && aiProvider.skillsGap != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SkillsGapAnalysisScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      AppSnackBar.show('Analysis failed. Please try again later.');
    }
  }

  Widget _buildAICard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _buildGlassBox(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  height: 1.1,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'GENERATE',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomApplyAction(BuildContext context) {
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
                return Row(
                  children: [
                    Expanded(
                      child: _isApplied(context, auth, jobProv)
                          ? _buildAppliedState()
                          : _buildApplyButton(context, auth),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _isApplied(
    BuildContext context,
    AuthProvider auth,
    JobProvider jobProv,
  ) {
    if (auth.userId == null) return false;
    return jobProv.isJobApplied(job.id);
  }

  Widget _buildApplyButton(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF03A9F4), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03A9F4).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (auth.userId == null) {
            AppSnackBar.show('Please login to apply', isError: true);
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ApplyJobScreen(job: job)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'APPLY NOW',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildAppliedState() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'APPLIED',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
