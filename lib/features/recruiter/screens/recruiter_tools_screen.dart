import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/ai_assistant/providers/ai_provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/jobs/data/job_service.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';
import 'package:fl_chart/fl_chart.dart';

class RecruiterToolsScreen extends StatefulWidget {
  const RecruiterToolsScreen({super.key});

  @override
  State<RecruiterToolsScreen> createState() => _RecruiterToolsScreenState();
}

class _RecruiterToolsScreenState extends State<RecruiterToolsScreen> {
  String _selectedRole = "Senior Software Engineer";
  final List<String> _popularRoles = [
    "Senior Software Engineer",
    "Flutter Developer",
    "AI/ML Engineer",
    "Product Manager",
    "UI/UX Designer",
    "Data Scientist",
    "Backend Developer",
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialInsights();
  }

  Future<void> _loadInitialInsights() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final ai = Provider.of<AIProvider>(context, listen: false);


      try {
        if (auth.userId != null) {
          final jobs = await JobService().fetchJobsByUser(auth.userId!);
          if (jobs.isNotEmpty) {
            _selectedRole = jobs.first.title;
          }
        }
      } catch (e) {
        debugPrint("Error fetching recruiter jobs for insights: $e");
      }

      if (ai.recruiterMarketInsights.isEmpty) {
        ai.getMarketInsights(
          jobTitle: _selectedRole,
          location: auth.location ?? "Global / Remote",
        );
      }
    });
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
    final ai = Provider.of<AIProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    ai.getMarketInsights(
      jobTitle: role,
      location: auth.location ?? "Global",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: Stack(
        children: [
          _buildBackgroundGradients(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildToolsGrid(),
                      const SizedBox(height: 40),
                      _buildMarketInsightsSection(),
                      const SizedBox(height: 100),
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
                  const Color(0xFFD500F9).withValues(alpha: 0.15),
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
                  const Color(0xFF00E676).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Recruiter AI',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hiring Intelligence',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF00B0FF),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Scale your talent acquisition with AI',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildToolsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.82,
      children: [
        _buildToolCard(
          title: 'JD Generator',
          subtitle: 'Create optimized job descriptions',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFFD500F9),
          onTap: () => _showJDGeneratorModal(),
        ),
        _buildToolCard(
          title: 'AI Scorer',
          subtitle: 'Rank candidates instantly',
          icon: Icons.checklist_rtl_rounded,
          color: const Color(0xFF00E676),
          onTap: () => _showResumeScorerModal(),
        ),
      ],
    );
  }

  Widget _buildToolCard({
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
          color: AppTheme.getGlassColor(context),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppTheme.getGlassBorderColor(context),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketInsightsSection() {
    return Consumer<AIProvider>(
      builder: (context, ai, child) {
        final insights = ai.recruiterMarketInsights;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MARKET INSIGHTS 2026',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 2.0,
                  ),
                ),
                if (ai.isGenerating)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  InkWell(
                    onTap: () async {
                      final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                      String title = "Senior Software Engineer";
                      try {
                        final jobs = await JobService().fetchJobsByUser(
                          auth.userId!,
                        );
                        if (jobs.isNotEmpty) title = jobs.first.title;
                      } catch (_) {}

                      ai.getMarketInsights(
                        jobTitle: title,
                        location: auth.location ?? "Global",
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Color(0xFF03A9F4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _popularRoles.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final role = _popularRoles[index];
                  final isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _onRoleSelected(role);
                    },
                    selectedColor: const Color(0xFF03A9F4).withValues(alpha: 0.1),
                    checkmarkColor: const Color(0xFF03A9F4),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF03A9F4)
                          : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF03A9F4).withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildMarketTrendChart(context),
            const SizedBox(height: 24),
            _buildMarketInsightCard(
              title: 'Avg. Salary',
              value: insights['avgSalary'] ?? '\$120k - \$185k',
              trend: insights['salaryReasoning'] ??
                  'Based on latest 2026 tech market data.',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF03A9F4),
            ),
            const SizedBox(height: 16),
            _buildMarketInsightCard(
              title: 'Demand Level',
              value: insights['demandLevel'] ?? 'High Demand',
              trend: insights['demandReasoning'] ??
                  insights['remoteTrends'] ??
                  'Remote-first hiring is peaking.',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFFF9100),
            ),
            const SizedBox(height: 16),
            _buildMarketInsightCard(
              title: 'Hiring Difficulty',
              value: insights['hiringDifficulty'] != null
                  ? '${insights['hiringDifficulty']}/10'
                  : '7/10',
              trend: 'Moderately difficult to find niche talent.',
              icon: Icons.psychology_rounded,
              color: const Color(0xFF00E676),
            ),
            const SizedBox(height: 16),
            _buildMarketInsightCard(
              title: 'Top AI Skill',
              value: (insights['topSkills'] is List &&
                      (insights['topSkills'] as List).isNotEmpty)
                  ? (insights['topSkills'] as List).first
                  : (insights['topSkills']?.toString() ?? 'Agentic AI'),
              trend: 'Highest growth in current recruiter demand.',
              icon: Icons.verified_rounded,
              color: const Color(0xFFD500F9),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarketTrendChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Demand Trend',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Last 6 months velocity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 14,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '12.4%',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 7,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 3),
                      FlSpot(4, 5),
                      FlSpot(5, 4),
                      FlSpot(6, 5),
                    ],
                    isCurved: true,
                    color: const Color(0xFF03A9F4),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF03A9F4).withValues(alpha: 0.1),
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

  Widget _buildMarketInsightCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJDGeneratorModal() {
    final titleController = TextEditingController();
    final requirementsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Consumer<AIProvider>(
          builder: (context, ai, child) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI JD Generator',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Describe the role, and let AI do the heavy lifting.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildModalField(
                          'Job Title',
                          'e.g. Senior Flutter Developer',
                          titleController,
                        ),
                        const SizedBox(height: 24),
                        _buildModalField(
                          'Key Skills/Requirements',
                          'e.g. 3 years exp, Firebase, Clean Architecture...',
                          requirementsController,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 40),
                        if (ai.isGenerating)
                          const Center(child: CircularProgressIndicator())
                        else
                          _buildPrimaryButton('Generate Description', () async {
                            if (titleController.text.isEmpty) {
                              AppSnackBar.show(
                                'Please enter a job title',
                                isError: true,
                              );
                              return;
                            }

                            try {
                              final result = await ai.generateJobDescription(
                                title: titleController.text,
                                company: "Your Company",
                                requirements: requirementsController.text,
                              );

                              if (mounted) {
                                _showJDResultModal(result);
                              }
                            } catch (e) {
                              AppSnackBar.show(
                                'Generation failed. Try again.',
                                isError: true,
                              );
                            }
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJDResultModal(Map<String, dynamic> data) {
    if (Navigator.canPop(context)) Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Generated JD',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            final responsibilities =
                                data['responsibilities'] is List
                                ? (data['responsibilities'] as List).join('\n')
                                : data['responsibilities'];
                            final requirements = data['requirements'] is List
                                ? (data['requirements'] as List).join('\n')
                                : data['requirements'];

                            final text =
                                "${data['description']}\n\nResponsibilities:\n$responsibilities\n\nRequirements:\n$requirements";
                            Clipboard.setData(ClipboardData(text: text));
                            AppSnackBar.show('Copied to clipboard!');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildResultSection(
                      'Overview',
                      data['description'] ?? 'N/A',
                    ),
                    const SizedBox(height: 24),
                    _buildListSection(
                      'Responsibilities',
                      data['responsibilities'] ?? [],
                    ),
                    const SizedBox(height: 24),
                    _buildListSection(
                      'Requirements',
                      data['requirements'] ?? [],
                    ),
                    const SizedBox(height: 24),
                    _buildResultSection(
                      'Market Salary Range',
                      data['salaryRange'] ?? 'N/A',
                    ),
                    const SizedBox(height: 40),
                    _buildPrimaryButton('Create Job Posting', () {
                      Navigator.pop(context);
                      AppSnackBar.show('Drafting job posting...');
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResumeScorerModal() {
    final jdController = TextEditingController();
    final resumeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<AIProvider>(
        builder: (context, ai, child) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Resume Scorer',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Paste JD and Resume to get instant matching score.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildModalField(
                        'Job Description',
                        'Paste the job requirements here...',
                        jdController,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      _buildModalField(
                        'Resume Content',
                        'Paste applicant resume content here...',
                        resumeController,
                        maxLines: 8,
                      ),
                      const SizedBox(height: 40),
                      if (ai.isGenerating)
                        const Center(child: CircularProgressIndicator())
                      else
                        _buildPrimaryButton('Score Talent', () async {
                          if (jdController.text.isEmpty ||
                              resumeController.text.isEmpty) {
                            AppSnackBar.show(
                              'Please provide both JD and Resume',
                              isError: true,
                            );
                            return;
                          }

                          try {
                            final result = await ai.scoreResume(
                              resumeContent: resumeController.text,
                              jobDescription: jdController.text,
                            );

                            if (mounted) {
                              _showScoringResultModal(result);
                            }
                          } catch (e) {
                            AppSnackBar.show('Scoring failed.', isError: true);
                          }
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScoringResultModal(Map<String, dynamic> data) {
    if (Navigator.canPop(context)) Navigator.pop(context);

    final scoreStr = data['overallScore']?.toString() ?? '0';
    final int score = int.tryParse(scoreStr) ?? 0;
    final color = score > 80
        ? Colors.green
        : (score > 50 ? Colors.orange : Colors.red);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      score > 70 ? 'Strong Candidate' : 'Average Match',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildResultSection('AI Verdict', data['verdict'] ?? 'N/A'),
                    const SizedBox(height: 24),
                    _buildListSection('Key Matches', data['keyMatches'] ?? []),
                    const SizedBox(height: 24),
                    _buildListSection(
                      'Missing Critical',
                      data['missingCritical'] ?? [],
                    ),
                    const SizedBox(height: 40),
                    _buildPrimaryButton('Done', () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF03A9F4), Color(0xFF00B0FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03A9F4).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, dynamic list) {
    final List<String> items = list is List ? List<String>.from(list) : [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text(
            'No significant items noted.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
