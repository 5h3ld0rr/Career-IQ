import 'dart:ui';
import 'package:flutter/material.dart';
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
          // Background Gradient Circles for Aesthetic
          _buildBackgroundGradients(),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Hub',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Premium Career Toolbox',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Tool Icons Grid (Circular layout like BOC Flex)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCircularTool(
                          context,
                          title: 'CV Analysis',
                          icon: Icons.description_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CVUploadScreen()),
                          ),
                        ),
                        _buildCircularTool(
                          context,
                          title: 'Mock Interview',
                          icon: Icons.psychology_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MockInterviewScreen()),
                          ),
                        ),
                        _buildCircularTool(
                          context,
                          title: 'Salary ROI',
                          icon: Icons.insights_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SalaryROIScreen()),
                          ),
                        ),
                        _buildCircularTool(
                          context,
                          title: 'Expert AI',
                          icon: Icons.forum_outlined,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI Expert coming soon!')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Featured Sections (Additional BOC Flex-like UI)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 10),
                      _buildSectionHeader('FAVORITE TOOLS', 'MANAGE LIST'),
                      const SizedBox(height: 16),
                      _buildToolCard(
                        context,
                        title: 'Resume Tailor',
                        subtitle: 'Optimize your resume for specific job roles.',
                        icon: Icons.edit_document,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('CAREER GROWTH', 'VIEW ALL'),
                      const SizedBox(height: 16),
                      _buildToolCard(
                        context,
                        title: 'Market Trends',
                        subtitle: 'See what skills are in demand right now.',
                        icon: Icons.trending_up_rounded,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 120),
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

  Widget _buildCircularTool(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: Colors.blueGrey.shade800, size: 28),
                // Tiny decorative dot like in BOC Flex
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107), // Gold/Amber accent
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title.split(' ').join('\n'), // Multi-line title
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00B0FF),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundGradients() {
    return Stack(
      children: [
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
                  const Color(0xFF81D4FA).withValues(alpha: 0.25),
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
                  const Color(0xFF03A9F4).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }
}
