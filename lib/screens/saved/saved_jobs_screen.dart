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
                title: const Text('Saved Jobs'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: jobProvider.savedJobs.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState(context))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildSavedJobCard(
                              jobProvider.savedJobs[index],
                              context,
                            ),
                          ),
                          childCount: jobProvider.savedJobs.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
          gradient: RadialGradient(
            colors: [
              const Color(0xFF81D4FA).withValues(alpha: 0.3),
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
    double borderRadius = 24,
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
            blurRadius: 15,
            offset: const Offset(0, 5),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGlassBox(
            context,
            borderRadius: 50,
            padding: const EdgeInsets.all(24),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 60,
              color: Colors.black26,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No saved jobs yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedJobCard(Job job, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
      ),
      child: _buildGlassBox(
        context,
        disableBlur: true,
        child: Row(
          children: [
            _buildGlassBox(
              context,
              borderRadius: 16,
              padding: const EdgeInsets.all(8),
              disableBlur: true,
              child: CachedNetworkImage(
                imageUrl: job.logoUrl,
                width: 40,
                height: 40,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(strokeWidth: 2),
                errorWidget: (context, url, error) => Icon(
                  Icons.business_rounded,
                  size: 24,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${job.companyName} • ${job.location}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.salary,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.bookmark_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
