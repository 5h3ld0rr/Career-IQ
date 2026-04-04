import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/features/interview/screens/schedule_interview_screen.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';

class ApplicationTrackerScreen extends StatefulWidget {
  final String? initialApplicationId;
  const ApplicationTrackerScreen({super.key, this.initialApplicationId});

  @override
  State<ApplicationTrackerScreen> createState() =>
      _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen> {
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userId != null) {
        Provider.of<JobProvider>(
          context,
          listen: false,
        ).startUserAppsStream(auth.userId!);
      }
    });
  }

  @override
  void dispose() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId != null) {
       Provider.of<JobProvider>(context, listen: false).stopUserAppsStream();
    }
    super.dispose();
  }

  Future<void> _seedMockData() async {
    setState(() => _isSeeding = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final jobProvider = Provider.of<JobProvider>(context, listen: false);

      if (auth.userId != null) {
        await jobProvider.seedDatabase(auth.userId!);

        if (jobProvider.jobs.isNotEmpty) {
          final topJobs = jobProvider.jobs.take(3).toList();
          for (var job in topJobs) {
            await jobProvider.applyForJob(auth.userId!, job.id);
          }
        }

        if (mounted) {
          AppSnackBar.show('Mock data seeded successfully! 🚀');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show('Failed to seed data: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          Consumer<JobProvider>(
            builder: (context, jobProvider, child) {
              final apps = jobProvider.userApplications;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text(
                      'Application Tracker',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    centerTitle: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildGlassBox(
                          context,
                          child: _buildQuickActions(context, apps),
                        ),
                        const SizedBox(height: 32),
                        _buildStatsRow(context, apps),
                        const SizedBox(height: 32),
                        const Text(
                          'Active Applications',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (jobProvider.isLoading || _isSeeding)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (apps.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildApplicationList(context, apps),
                        const SizedBox(height: 120),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _buildGlassBox(
      context,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No applications yet',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Your job applications will appear here once you apply.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _seedMockData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SEED MOCK DATA',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              AppSnackBar.show('Navigate to the Search tab to find jobs!');
            },
            child: const Text(
              'DISCOVER JOBS',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
        Positioned(
          bottom: 200,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF81D4FA).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: 50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE1F5FE).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassBox(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 28,
    bool disableBlur = false,
  }) {
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
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.light
                  ? 0.04
                  : 0.2,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: disableBlur
            ? Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              )
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(20),
                  child: child,
                ),
              ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    List<Map<String, dynamic>> apps,
  ) {
    String nextCompany = 'None';
    String status = 'N/A';
    if (apps.isNotEmpty) {
      nextCompany = _capitalize(apps.first['job']['company_name']);
      status = apps.first['status'] ?? 'Submitted';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withValues(alpha: 0.1),
                Colors.blueAccent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.blueAccent,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Application',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _capitalize(nextCompany),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),
        if (apps.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, List<Map<String, dynamic>> apps) {
    int total = apps.length;
    int pending = apps.where((a) => a['status'] == 'pending').length;
    int accepted = apps.where((a) => a['status'] == 'accepted').length;
    int rejected = apps.where((a) => a['status'] == 'rejected').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Total', total.toString(), Colors.blueAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Pending',
            pending.toString(),
            Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Hired',
            accepted.toString(),
            Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Rejected',
            rejected.toString(),
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return _buildGlassBox(
      context,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderRadius: 22,
      disableBlur: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForLabel(label),
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'total':
        return Icons.all_inbox_rounded;
      case 'pending':
        return Icons.access_time_filled_rounded;
      case 'hired':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.bar_chart_rounded;
    }
  }

  Widget _buildApplicationList(
    BuildContext context,
    List<Map<String, dynamic>> apps,
  ) {
    return Column(
      children: apps.map((app) {
        final job = app['job'];
        final status = app['status'] as String;
        double progress = status == 'pending'
            ? 0.4
            : (status == 'accepted' ? 1.0 : 0.6);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildGlassBox(
            context,
            disableBlur: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        job['company_name'] != null &&
                                job['company_name'].toString().isNotEmpty
                            ? job['company_name'].toString().substring(0, 1)
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalize(job['title']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job['company_name'],
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              status == 'accepted'
                                  ? Colors.greenAccent
                                  : (status == 'rejected'
                                        ? Colors.redAccent
                                        : Colors.blueAccent),
                              status == 'accepted'
                                  ? Colors.green
                                  : (status == 'rejected'
                                        ? Colors.red
                                        : Colors.lightBlueAccent),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ScheduleInterviewScreen(application: app),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text(
                      'SCHEDULE INTERVIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(dynamic value) {
    if (value == null) return '';
    final String text = value.toString();
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildStatusPill(String status) {
    Color color = Colors.blueAccent;
    if (status == 'accepted') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
