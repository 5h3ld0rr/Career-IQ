import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Navy
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: const Text(
          'Salary ROI Analyst',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _refreshInsights,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(salaryProvider),
            const SizedBox(height: 30),
            _buildMarketTrendSection(salaryProvider),
            const SizedBox(height: 30),
            const Text(
              'High-Impact Skills',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            _buildSkillsGrid(salaryProvider),
            const SizedBox(height: 30),
            _buildRecommendationSection(salaryProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(SalaryProvider provider) {
    if (provider.isLoading) {
      return _buildShimmerHeader();
    }

    final totalGrowth = provider.insights.fold(0.0, (sum, item) => sum + item.potentialIncreasePercentage);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], // Blue to Purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Potential Earnings Growth',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            '+${totalGrowth.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Based on your current skill set vs market demand.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTrendSection(SalaryProvider provider) {
    if (provider.isLoading) {
      return _buildShimmerChart();
    }

    if (provider.insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Value Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 250,
          padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
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
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _getGlowColor(provider.insights.indexOf(insight)).withValues(alpha: 0.1),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsGrid(SalaryProvider provider) {
    if (provider.isLoading) {
      return _buildShimmerGrid();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
      ),
      itemCount: provider.insights.length,
      itemBuilder: (context, index) {
        final insight = provider.insights[index];
        final color = _getGlowColor(index);
        
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  insight.skillName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  '+${insight.potentialIncreasePercentage}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationSection(SalaryProvider provider) {
    if (provider.isLoading || provider.insights.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            provider.insights.first.aiRecommendation,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
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
      children: List.generate(4, (index) => Shimmer.fromColors(
        baseColor: Colors.white12,
        highlightColor: Colors.white24,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      )),
    );
  }
}
