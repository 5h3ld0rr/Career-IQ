import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';

class ApplicationTrackerScreen extends StatefulWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  State<ApplicationTrackerScreen> createState() => _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userId != null) {
        Provider.of<JobProvider>(context, listen: false).loadUserApplications(auth.userId!);
      }
    });
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
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildGlassBox(
                        context,
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
                    title: const Text('Application Tracker'),
                    centerTitle: true,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildGlassBox(context, child: _buildQuickActions(context, apps)),
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
                        if (jobProvider.isLoading)
                          const Center(child: CircularProgressIndicator())
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white, width: 1.5),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _buildGlassBox(
      context,
      padding: const EdgeInsets.all(40),
      child: const Column(
        children: [
          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text(
            'No applications yet',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Your job applications will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: 100,
      left: -50,
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

  Widget _buildQuickActions(BuildContext context, List<Map<String, dynamic>> apps) {
    // Show most recent application or some default info
    String nextCompany = 'None';
    if (apps.isNotEmpty) {
       nextCompany = apps.first['job']['company_name'];
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.event_available_rounded,
            color: Colors.blueAccent,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Application',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                nextCompany,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
        ),
        if (apps.isNotEmpty)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              Text(
                'Submitted',
                style: TextStyle(color: Colors.black54, fontSize: 12),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Total', total.toString()),
        _buildStatItem('Pending', pending.toString()),
        _buildStatItem('Hired', accepted.toString()),
        _buildStatItem('Rejected', rejected.toString()),
      ],
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationList(BuildContext context, List<Map<String, dynamic>> apps) {
    return Column(
      children: apps
          .map(
            (app) {
              final job = app['job'];
              final status = app['status'] as String;
              double progress = status == 'pending' ? 0.3 : (status == 'accepted' ? 1.0 : 0.5);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildGlassBox(
                  context,
                  disableBlur: true,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildGlassBox(
                            context,
                            borderRadius: 12,
                            padding: const EdgeInsets.all(8),
                            disableBlur: true,
                            child: Text(
                              job['company_name'].toString().substring(0, 1),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  job['company_name'],
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusPill(status),
                        ],
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          status == 'accepted'
                              ? Colors.greenAccent
                              : (status == 'rejected' ? Colors.redAccent : Colors.blueAccent),
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
          .toList(),
    );
  }

  Widget _buildStatusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.black54,
        ),
      ),
    );
  }
}
