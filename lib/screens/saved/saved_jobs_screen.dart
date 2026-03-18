import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/providers/job_provider.dart';
import 'package:careeriq/core/theme.dart';
import 'package:careeriq/models/job.dart';
import '../details/job_details_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);

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
                title: const Text('Saved Jobs'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: jobProvider.savedJobs.isEmpty 
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSavedJobCard(jobProvider.savedJobs[index], context),
                        ),
                        childCount: jobProvider.savedJobs.length,
                      ),
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
      top: 100,
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

  Widget _buildGlassBox({required Widget child, EdgeInsets? padding, double borderRadius = 24, bool disableBlur = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(disableBlur ? 0.8 : 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: disableBlur 
          ? Padding(padding: padding ?? const EdgeInsets.all(20), child: child)
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGlassBox(
            borderRadius: 50,
            padding: const EdgeInsets.all(24),
            child: const Icon(Icons.bookmark_border_rounded, size: 60, color: Colors.black26),
          ),
          const SizedBox(height: 24),
          const Text('No saved jobs yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSavedJobCard(Job job, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job))),
      child: _buildGlassBox(
        disableBlur: true,
        child: Row(
          children: [
            _buildGlassBox(
              borderRadius: 16,
              padding: const EdgeInsets.all(8),
              disableBlur: true,
              child: CachedNetworkImage(imageUrl: job.logoUrl, width: 40, height: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Text('${job.companyName} • ${job.location}', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(job.salary, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF03A9F4))),
                ],
              ),
            ),
            const Icon(Icons.bookmark_rounded, color: Color(0xFF03A9F4)),
          ],
        ),
      ),
    );
  }
}
