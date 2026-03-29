import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../cv_analysis/cv_upload_screen.dart';
import '../interview/mock_interview_screen.dart';
import '../salary_roi/salary_roi_screen.dart';

class CareerToolsScreen extends StatelessWidget {
  const CareerToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient Circles
          Positioned(
            top: -100,
            right: -50,
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
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
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
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    'Career AI Hub',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'Unlock your potential with our advanced AI-driven tools',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildToolCard(
                        context,
                        title: 'CV Analysis',
                        subtitle: 'Upload your CV and get professional feedback and skill identification.',
                        icon: Icons.description_rounded,
                        color: const Color(0xFF03A9F4),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CVUploadScreen()),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildToolCard(
                        context,
                        title: 'AI Mock Interview',
                        subtitle: 'Practice with our AI coach to ace your next job interview.',
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFF26C6DA),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MockInterviewScreen()),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildToolCard(
                        context,
                        title: 'Salary ROI Analyst',
                        subtitle: 'Analyze your salary growth potential and market trends.',
                        icon: Icons.insights_rounded,
                        color: const Color(0xFF4FC3F7),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SalaryROIScreen()),
                        ),
                      ),
                      
                      const SizedBox(height: 120), // Bottom navigation buffer
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getGlassColor(context).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppTheme.getGlassBorderColor(context),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
