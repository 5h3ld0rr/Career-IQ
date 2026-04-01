import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/ai_assistant/providers/ai_provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:shimmer/shimmer.dart';

class SkillsGapAnalysisScreen extends StatelessWidget {
  const SkillsGapAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final gapData = aiProvider.skillsGap;

    if (aiProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.getScaffoldColor(context),
        body: Stack(
          children: [
            _buildBackgroundDecor(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.2),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 36,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Shimmer.fromColors(
                    baseColor: AppTheme.mediumSlate,
                    highlightColor: AppTheme.primaryBlue,
                    child: const Text(
                      'Deep Scan in progress...',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI is mapping your skills to industry standards',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (gapData == null) {
      return Scaffold(
        backgroundColor: AppTheme.getScaffoldColor(context),
        appBar: AppBar(
          title: const Text('Skills Analysis'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Colors.blue.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              const Text(
                'Starting analysis...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'We are processing your CV data.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    final List<String> currentSkills = List<String>.from(
      gapData['currentSkills'] ?? [],
    );
    final List<String> missingSkills = List<String>.from(
      gapData['missingSkills'] ?? [],
    );
    final List<String> recommendations = List<String>.from(
      gapData['recommendations'] ?? [],
    );
    final String summary =
        gapData['summary'] ??
        "Analyzing how your trajectory aligns with this role's requirements...";

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
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
                title: const Text('Career Match IQ'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGlassBox(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'AI INSIGHT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: AppTheme.primaryBlue,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            summary,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.4,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Your Strengths'),
                    const SizedBox(height: 16),
                    _buildSkillList(currentSkills, isMissing: false),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Critical Gaps'),
                    const SizedBox(height: 16),
                    _buildSkillList(missingSkills, isMissing: true),
                    const SizedBox(height: 48),

                    _buildSectionTitle('AI Strategy Plan'),
                    const SizedBox(height: 20),
                    ...recommendations.asMap().entries.map(
                      (entry) => _buildRecommendationCard(
                        index: entry.key + 1,
                        text: entry.value,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({required int index, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildGlassBox(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '0$index',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -100,
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
          bottom: 200,
          left: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF9800).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSkillList(List<String> skills, {required bool isMissing}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map((skill) => _buildSkillBadge(skill, isMissing))
          .toList(),
    );
  }

  Widget _buildSkillBadge(String skill, bool isMissing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMissing
            ? Colors.red.withValues(alpha: 0.05)
            : Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMissing
              ? Colors.red.withValues(alpha: 0.15)
              : Colors.green.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMissing
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            size: 14,
            color: isMissing ? Colors.redAccent : Colors.greenAccent[700],
          ),
          const SizedBox(width: 8),
          Text(
            skill,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isMissing ? Colors.red[900] : Colors.green[900],
            ),
          ),
        ],
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
            color: Colors.black.withValues(alpha: 0.03),
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
            padding: padding ?? const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
