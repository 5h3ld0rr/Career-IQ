import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/models/job.dart';
import 'package:careeriq/providers/job_provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/screens/interview/mock_interview_screen.dart';
import 'ai_cover_letter_screen.dart';
import 'apply_job_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;
  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildGlassBox(
                      borderRadius: 50,
                      padding: const EdgeInsets.all(4),
                      child: Consumer2<AuthProvider, JobProvider>(
                        builder: (context, auth, jobs, _) => IconButton(
                          icon: Icon(
                            job.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            size: 20,
                            color: job.isSaved
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onPressed: () {
                            if (auth.userId != null) {
                              jobs.toggleSaveJob(auth.userId!, job);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    Center(child: _buildCompanyHeader(context)),
                    const SizedBox(height: 40),
                    const Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildGlassBox(child: _buildAISection(context)),
                    const SizedBox(height: 32),
                    const Text(
                      'Responsibilities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...job.responsibilities.map((res) => _buildListItem(res)),
                    const SizedBox(height: 32),
                    const Text(
                      'Requirements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...job.requirements.map((req) => _buildListItem(req)),
                    const SizedBox(height: 120),
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

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: 100,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF81D4FA).withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBox({
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 24,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildCompanyHeader(BuildContext context) {
    return Column(
      children: [
        _buildGlassBox(
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
          child: CachedNetworkImage(
            imageUrl: job.logoUrl,
            width: 60,
            height: 60,
            placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
            errorWidget: (context, url, error) => Icon(
              Icons.business_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          job.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${job.companyName} • ${job.location}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassPill(job.jobType, Colors.blueAccent),
            const SizedBox(width: 12),
            _buildGlassPill(job.salary, Colors.cyan),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassPill(String text, Color color) {
    return _buildGlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
  Widget _buildAISection(BuildContext context) {
    return Column(
      children: [
        _buildActionRow(
          context,
          icon: Icons.description_rounded,
          title: 'AI Cover Letter',
          subtitle: 'Custom letter for this job.',
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
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(height: 1),
        ),
        _buildActionRow(
          context,
          icon: Icons.mic_rounded,
          title: 'Practice Interview',
          subtitle: 'AI-led mock session for this job.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MockInterviewScreen(
                  initialRole: job.title,
                  initialLevel: job.requirements.any((r) => r.toLowerCase().contains('senior')) ? 'Senior' : 'Junior',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF03A9F4),
          size: 32,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _buildGlassBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: 12,
          child: GestureDetector(
            onTap: onTap,
            child: const Text(
              'START',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Color(0xFF03A9F4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF03A9F4),
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
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
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Row(
                  children: [
                    Expanded(
                      child: _isApplied(context, auth)
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

  bool _isApplied(BuildContext context, AuthProvider auth) {
    if (auth.userId == null) return false;
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    return jobProvider.userApplications.any((app) => app['job']['id'] == job.id);
  }

  Widget _buildApplyButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (auth.userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login to apply')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplyJobScreen(job: job),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'APPLY NOW',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
              'ALREADY APPLIED',
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
