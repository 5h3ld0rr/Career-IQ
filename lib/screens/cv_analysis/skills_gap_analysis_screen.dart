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
        backgroundColor: const Color(0xFFF2F8FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              Text('Analyzing your skills gap...', style: const TextStyle(color: AppTheme.mediumSlate, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (gapData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F8FF),
        appBar: AppBar(title: const Text('Skills Gap Analysis')),
        body: const Center(child: Text('No analysis data available.')),
      );
    }

    final int matchPercentage = gapData['matchPercentage'] ?? 0;
    final List<String> currentSkills = List<String>.from(gapData['currentSkills'] ?? []);
    final List<String> missingSkills = List<String>.from(gapData['missingSkills'] ?? []);
    final List<String> recommendations = List<String>.from(gapData['recommendations'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                title: const Text('Skills Gap Analysis'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGlassBox(
                      child: _buildMatchCard(context, matchPercentage),
                    ),
                    const SizedBox(height: 32),
                    _buildSkillSection(context, 'Core Skills You Possess', currentSkills, Colors.blueAccent),
                    const SizedBox(height: 32),
                    _buildSkillSection(context, 'Growth Opportunities', missingSkills, Colors.cyan),
                    const SizedBox(height: 32),
                    const Text(
                      'Expert Recommendations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    ...recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGlassBox(child: _buildRecommendationItem(rec)),
                    )).toList(),
                    const SizedBox(height: 48),
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
      top: -50,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [const Color(0xFF81D4FA).withOpacity(0.3), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child, EdgeInsets? padding, double borderRadius = 24}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
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

  Widget _buildMatchCard(BuildContext context, int percentage) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF03A9F4)),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(width: 24),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Matching Score', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
              SizedBox(height: 4),
              Text(
                'Based on your profile vs industry standards.',
                style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSection(BuildContext context, String title, List<String> skills, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: skills.map((skill) => _buildGlassBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 12,
            child: Text(
              skill,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF03A9F4), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
