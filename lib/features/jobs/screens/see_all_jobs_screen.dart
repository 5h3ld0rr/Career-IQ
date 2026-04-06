import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/jobs/screens/details/job_details_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Proactively load more jobs when the user is 600 pixels (approx 4-5 items) 
    // from the bottom, to ensure a seamless "infinite" scroll experience.
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 600 &&
        _searchQuery.isEmpty) {
      context.read<JobProvider>().loadMoreJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, _) {
        List<Job> displayJobs = [];
        if (widget.title == 'Latest Job Listings') {
          displayJobs = jobProvider.jobs;
        } else if (widget.title == 'Featured Jobs') {
          displayJobs = jobProvider.featuredJobs;
        } else if (widget.title == 'Jobs Near You') {
          displayJobs = jobProvider.suggestedJobs;
        } else {
          displayJobs = widget.initialJobs;
        }

        // Apply local search filter
        if (_searchQuery.isNotEmpty) {
          displayJobs = displayJobs
              .where(
                (job) =>
                    job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    job.companyName.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
        }

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
                      child: displayJobs.isEmpty && !jobProvider.isLoading
                          ? _buildNoResults()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: displayJobs.length + (jobProvider.isMoreLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index < displayJobs.length) {
                                  final job = displayJobs[index];
                                  return _buildJobListItem(job, context);
                                } else {
                                  return const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchArea() {
    return Consumer<JobProvider>(
      builder: (context, jobs, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(
          children: [
            Expanded(
              child: _buildGlassBox(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search jobs in this list...',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showFilterModal(context, jobs),
              child: _buildGlassBox(
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                child: Icon(
                  Icons.tune_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context, JobProvider jobs) {
    String tempJobType = jobs.selectedJobType;
    String tempWorkMode = jobs.selectedWorkMode;
    String tempLocation = jobs.currentQuery?.split(' in ').last ?? "";
    final locationController = TextEditingController(text: tempLocation);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Search Filters',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        hintText: 'City, Country or Remote',
                        prefixIcon: const Icon(Icons.location_on_rounded),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Job Type',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'Full-time', 'Part-time', 'Contract'].map(
                        (type) {
                          final isSelected = tempJobType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => tempJobType = type);
                            },
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Work Mode',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'Remote', 'On-site', 'Hybrid'].map((
                        mode,
                      ) {
                        final isSelected = tempWorkMode == mode;
                        return ChoiceChip(
                          label: Text(mode),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => tempWorkMode = mode);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          final loc = locationController.text.trim();
                          jobs.loadJobs(
                            query: loc.isNotEmpty ? "jobs in $loc" : null,
                            jobType: tempJobType,
                            workMode: tempWorkMode,
                            userLocation: loc.isNotEmpty ? loc : null,
                          );
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'APPLY FILTERS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJobListItem(Job job, BuildContext context) {
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        Flexible(
                          child: Text(
                            job.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.work_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            job.jobType,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          Provider.of<JobProvider>(
                            context,
                            listen: false,
                          ).toggleSaveJob(auth.userId!, job);
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
            style: TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.w600,
            ),
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
