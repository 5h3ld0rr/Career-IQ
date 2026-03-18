import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ApplicationTrackerScreen extends StatelessWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
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
                title: const Text('Application Tracker'),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGlassBox(
                      child: _buildQuickActions(context),
                    ),
                    const SizedBox(height: 32),
                    _buildStatsRow(context),
                    const SizedBox(height: 32),
                    const Text(
                      'Active Applications',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    _buildApplicationList(context),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
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

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: 100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [const Color(0xFF81D4FA).withOpacity(0.35), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child, EdgeInsets? padding, double borderRadius = 28}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.event_available_rounded, color: Colors.blueAccent, size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next Interview', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Google UX Design', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Tomorrow', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            Text('10:30 AM', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Total', '24'),
        _buildStatItem('Applied', '12'),
        _buildStatItem('Interviews', '5'),
        _buildStatItem('Offers', '2'),
      ],
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black54, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildApplicationList(BuildContext context) {
    final List<Map<String, dynamic>> apps = [
      {'company': 'Canva', 'role': 'UX Designer', 'status': 'Interviewing', 'date': 'Oct 14', 'progress': 0.6},
      {'company': 'Atlassian', 'role': 'Product Designer', 'status': 'Applied', 'date': 'Oct 12', 'progress': 0.2},
      {'company': 'Slack', 'role': 'Lead Designer', 'status': 'Offered', 'date': 'Oct 8', 'progress': 1.0},
    ];

    return Column(
      children: apps.map((app) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildGlassBox(
          child: Column(
            children: [
              Row(
                children: [
                  _buildGlassBox(borderRadius: 12, padding: const EdgeInsets.all(8), child: Text(app['company'].substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app['role'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(app['company'], style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  _buildStatusPill(app['status']),
                ],
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: app['progress'],
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(app['status'] == 'Offered' ? Colors.blueAccent : Colors.lightBlueAccent),
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildStatusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black54)),
    );
  }
}
