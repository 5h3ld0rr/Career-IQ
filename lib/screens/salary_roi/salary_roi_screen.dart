import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../core/theme.dart';

class SalaryROIScreen extends StatefulWidget {
  const SalaryROIScreen({super.key});

  @override
  State<SalaryROIScreen> createState() => _SalaryROIScreenState();
}

class _SalaryROIScreenState extends State<SalaryROIScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshInsights();
    });
  }

  void _refreshInsights() {
    final authProvider = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();

    // Get unique job titles from tracked jobs if available
    final targetTitles = jobProvider.jobs.map((j) => j.title).toSet().toList();
    if (targetTitles.isEmpty) {
      targetTitles.add("Software Engineer"); // Default fallback
    }

    context.read<SalaryProvider>().fetchSalaryInsights(
      userSkills: authProvider.skills,
      targetJobTitles: targetTitles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryProvider = context.watch<SalaryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppTheme.darkText;

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _buildGlassIconButton(
            context,
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'ROI Analyst',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -1,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
            child: _buildGlassIconButton(
              context,
              icon: Icons.refresh_rounded,
              onTap: _refreshInsights,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(salaryProvider, isDark),
                const SizedBox(height: 40),
                
                if (salaryProvider.insights.isNotEmpty || salaryProvider.isLoading) ...[
                  _buildMarketTrendSection(salaryProvider, isDark),
                  const SizedBox(height: 40),
                  
                  Text(
                    'High-ROI Skills',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSkillsGrid(salaryProvider, isDark),
                  const SizedBox(height: 40),
                  _buildRecommendationSection(salaryProvider, isDark),
                ] else ...[
                  _buildEmptyState(context, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white60,
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, size: 18, color: isDark ? Colors.white : AppTheme.darkText),
            onPressed: onTap,
          ),
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
                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF472B6).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Analyzing Market Potential',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Explore more jobs and complete your profile skills to unlock personalized salary ROI insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _refreshInsights,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(SalaryProvider provider, bool isDark) {
    if (provider.isLoading) {
      return _buildShimmerHeader();
    }

    final totalGrowth = provider.insights.fold(
      0.0,
      (sum, item) => sum + item.potentialIncreasePercentage,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppTheme.primaryBlue, AppTheme.darkBlue]
                      : [const Color(0xFF0288D1), const Color(0xFF03A9F4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Market Growth',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const Icon(Icons.trending_up_rounded, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: totalGrowth),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) => Text(
                      '+${value.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Potential value increase based on 2026 market demand benchmarks.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketTrendSection(SalaryProvider provider, bool isDark) {
    if (provider.isLoading) {
      return _buildShimmerChart();
    }

    if (provider.insights.isEmpty) return const SizedBox.shrink();

    final textColor = isDark ? Colors.white : AppTheme.darkText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Value Trajectory',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 30, 20, 10),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: provider.insights.map((insight) {
                      return LineChartBarData(
                        spots: insight.trendData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value);
                        }).toList(),
                        isCurved: true,
                        color: _getGlowColor(provider.insights.indexOf(insight)),
                        barWidth: 6,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _getGlowColor(
                            provider.insights.indexOf(insight),
                          ).withValues(alpha: 0.15),
                        ),
                      );
                    }).toList(),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black87.withValues(alpha: 0.8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toInt()}% value',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsGrid(SalaryProvider provider, bool isDark) {
    if (provider.isLoading) {
      return _buildShimmerGrid();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: provider.insights.length,
      itemBuilder: (context, index) {
        final insight = provider.insights[index];
        final color = _getGlowColor(index);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? color.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bolt_rounded, color: color, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  insight.skillName,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : AppTheme.darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  '+${insight.potentialIncreasePercentage}%',
                  style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationSection(SalaryProvider provider, bool isDark) {
    if (provider.isLoading || provider.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.lightBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : AppTheme.primaryBlue.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
              SizedBox(width: 10),
              Text(
                'AI Analysis',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            provider.insights.first.aiRecommendation,
            style: TextStyle(
              color: isDark
                  ? Colors.white70
                  : AppTheme.darkText.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGlowColor(int index) {
    final colors = [
      const Color(0xFF60A5FA), // Sky Blue
      const Color(0xFFF472B6), // Pink
      const Color(0xFF34D399), // Emerald
      const Color(0xFFFB7185), // Rose
      const Color(0xFF818CF8), // Indigo
    ];
    return colors[index % colors.length];
  }

  // Shimmer Loaders
  Widget _buildShimmerHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.white12,
      highlightColor: Colors.white24,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildShimmerChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Shimmer.fromColors(
          baseColor: Colors.white12,
          highlightColor: Colors.white24,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: List.generate(
        4,
        (index) => Shimmer.fromColors(
          baseColor: Colors.white12,
          highlightColor: Colors.white24,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
