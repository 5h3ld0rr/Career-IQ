import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../core/theme.dart';

class SkillsGapAnalysisScreen extends StatelessWidget {
  const SkillsGapAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final gapData = aiProvider.skillsGap;

    if (aiProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.getScaffoldColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              const Text(
                'Deep Scan in progress...',
                style: TextStyle(
                  color: AppTheme.mediumSlate,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI is comparing your skills with industry standards',
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
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
              Icon(Icons.analytics_outlined, size: 80, color: Colors.blue.withValues(alpha: 0.2)),
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

    final int matchPercentage = gapData['matchPercentage'] ?? 0;
    final List<String> currentSkills = List<String>.from(
      gapData['currentSkills'] ?? [],
    );
    final List<String> missingSkills = List<String>.from(
      gapData['missingSkills'] ?? [],
    );
    final List<String> recommendations = List<String>.from(
      gapData['recommendations'] ?? [],
    );

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
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGlassBox(child: _buildMatchPercentageSection(matchPercentage)),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Your Strengths'),
                    const SizedBox(height: 16),
                    _buildSkillList(currentSkills, isMissing: false),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Critical Gaps'),
                    const SizedBox(height: 16),
                    _buildSkillList(missingSkills, isMissing: true),
                    const SizedBox(height: 32),
                    _buildSectionTitle('AI Recommendations'),
                    const SizedBox(height: 16),
                    ...recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGlassBox(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF03A9F4), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF03A9F4).withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
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

  Widget _buildMatchPercentageSection(int percentage) {
    return Column(
      children: [
        const Text(
          'Target Role Fit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 10,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 70 ? const Color(0xFF00E676) : const Color(0xFF03A9F4),
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillList(List<String> skills, {required bool isMissing}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => _buildSkillBadge(skill, isMissing)).toList(),
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
            isMissing ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
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
