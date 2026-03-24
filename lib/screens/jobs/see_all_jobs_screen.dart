import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:careeriq/models/job.dart';
import 'package:careeriq/providers/job_provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/core/theme.dart';
import '../details/job_details_screen.dart';

class SeeAllJobsScreen extends StatefulWidget {
  final String title;
  final List<Job> initialJobs;

  const SeeAllJobsScreen({
    super.key,
    required this.title,
    required this.initialJobs,
  });

  @override
  State<SeeAllJobsScreen> createState() => _SeeAllJobsScreenState();
}

class _SeeAllJobsScreenState extends State<SeeAllJobsScreen> {
  late List<Job> _filteredJobs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredJobs = widget.initialJobs;
  }

  void _filterJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = widget.initialJobs;
      } else {
        _filteredJobs = widget.initialJobs
            .where((job) =>
                job.title.toLowerCase().contains(query.toLowerCase()) ||
                job.companyName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SafeArea(
            child: Column(
              children: [
                _buildSearchArea(),
                Expanded(
                  child: _filteredJobs.isEmpty
                      ? _buildNoResults()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredJobs[index];
                            return _buildJobCard(job);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: _buildGlassBox(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchController,
          onChanged: _filterJobs,
          decoration: const InputDecoration(
            hintText: 'Search jobs in this list...',
            prefixIcon: Icon(Icons.search_rounded),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        ),
        child: _buildGlassBox(
          child: Row(
            children: [
              _buildGlassBox(
                borderRadius: 12,
                padding: const EdgeInsets.all(8),
                disableBlur: true,
                child: CachedNetworkImage(
                  imageUrl: job.logoUrl,
                  width: 44,
                  height: 44,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(strokeWidth: 2),
                  errorWidget: (context, url, error) => Icon(
                    Icons.business_rounded,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.companyName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.work_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.jobType,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => IconButton(
                      onPressed: () {
                        if (auth.userId != null) {
                          Provider.of<JobProvider>(context, listen: false)
                              .toggleSaveJob(auth.userId!, job);
                        }
                      },
                      icon: Icon(
                        job.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: job.isSaved
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black26,
                      ),
                    ),
                  ),
                  Text(
                    job.salary.split('-').first,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No jobs found',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const Text(
            'Try adjusting your search query',
            style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBox({
    required Widget child,
    double? width,
    EdgeInsets? padding,
    double borderRadius = 24,
    bool disableBlur = false,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(context),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: disableBlur
            ? Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              )
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      bottom: -100,
      left: -100,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFB3E5FC).withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
