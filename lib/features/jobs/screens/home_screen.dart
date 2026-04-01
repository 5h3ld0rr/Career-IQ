import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/jobs/screens/details/job_details_screen.dart';
import 'package:careeriq/features/notifications/screens/notifications_screen.dart';
import 'package:careeriq/features/jobs/screens/see_all_jobs_screen.dart';
import 'package:careeriq/features/notifications/providers/notification_provider.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final List<String> _categories = [
    'All',
    'IT',
    'Business',
    'Engineering',
    'Hotel',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobProvider.loadJobs(location: auth.location).then((_) {
        if (!mounted) return;
        final profileStr =
            "Skills: ${auth.skills.join(', ')}\nBio: ${auth.bio}\nExperience: ${auth.experience}";
        if (auth.skills.isNotEmpty || auth.bio != null) {
          jobProvider.calculateMatchScores(profileStr);
        }
      });
      jobProvider.loadFeaturedJobs().then((_) {
        if (!mounted) return;
        final profileStr =
            "Skills: ${auth.skills.join(', ')}\nBio: ${auth.bio}\nExperience: ${auth.experience}";
        if (auth.skills.isNotEmpty || auth.bio != null) {
          jobProvider.calculateMatchScores(profileStr);
        }
      });
      if (auth.userId != null) {
        jobProvider.loadSavedJobs(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final jobs = Provider.of<JobProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => jobs.loadJobs(),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(auth, context),
                          const SizedBox(height: 24),
                          _buildSearchArea(context, jobs),
                          const SizedBox(height: 24),
                          _buildCategoryFilters(jobs),
                          const SizedBox(height: 32),
                          if (jobs.isLoading ||
                              jobs.featuredJobs.isNotEmpty) ...[
                            _buildSectionTitle(
                              'Featured Jobs',
                              showSeeAll: true,
                              onSeeAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SeeAllJobsScreen(
                                    title: 'Featured Jobs',
                                    initialJobs: jobs.featuredJobs,
                                  ),
                                ),
                              ),
                            ),
                            _buildFeaturedJobs(jobs),
                            const SizedBox(height: 32),
                          ],
                          if (jobs.suggestedJobs.isNotEmpty) ...[
                            _buildSectionTitle(
                              'Suggested Near ${auth.location ?? ""}',
                              showSeeAll: true,
                              onSeeAll: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SeeAllJobsScreen(
                                    title: 'Jobs Near You',
                                    initialJobs: jobs.suggestedJobs,
                                  ),
                                ),
                              ),
                            ),
                            _buildSuggestedJobs(jobs),
                            const SizedBox(height: 32),
                          ],
                          _buildSectionTitle(
                            'Latest Job Listings',
                            showSeeAll: true,
                            onSeeAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeeAllJobsScreen(
                                  title: 'Latest Job Listings',
                                  initialJobs: jobs.jobs,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: jobs.isLoading
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildVerticalShimmerItem(),
                              );
                            }, childCount: 5),
                          )
                        : jobs.jobs.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text('No jobs found'),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final job = jobs.jobs[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildJobListItem(job, context),
                              );
                            }, childCount: jobs.jobs.length),
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

  Widget _buildJobListItem(Job job, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
      ),
      child: _buildGlassBox(
        disableBlur: true, // Optimizing performance in list
        child: Row(
          children: [
            _buildGlassBox(
              borderRadius: 12,
              padding: const EdgeInsets.all(8),
              disableBlur: true,
              child: CachedNetworkImage(
                imageUrl: job.logoUrl,
                width: 32,
                height: 32,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(strokeWidth: 2),
                errorWidget: (context, url, error) => Icon(
                  Icons.business_rounded,
                  size: 20,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${job.companyName} • ${job.location}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (job.isAnalyzing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (job.matchScore != null)
              _buildMatchScoreCircle(job.matchScore!),
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
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E676).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildHeader(AuthProvider auth, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello ${auth.userName ?? "User"}!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Find your dream job',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) => _buildGlassBox(
              borderRadius: 50,
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
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

  Widget _buildSearchArea(BuildContext context, JobProvider jobs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildGlassBox(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    jobs.loadJobs(query: val.trim());
                  }
                },
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search for jobs...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Stack(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (jobs.selectedJobType != 'All' ||
                      jobs.selectedWorkMode != 'All')
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
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

  void _showFilterModal(BuildContext context, JobProvider jobs) {
    String tempJobType = jobs.selectedJobType;
    String tempWorkMode = jobs.selectedWorkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(
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
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Advanced Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
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
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
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
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        jobs.loadJobs(
                          jobType: tempJobType,
                          workMode: tempWorkMode,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(
    String title, {
    bool showSeeAll = false,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(JobProvider jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Explore Categories'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = jobs.currentCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    jobs.loadJobs(category: cat);
                    jobs.loadFeaturedJobs(category: cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppTheme.getGlassColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.getGlassBorderColor(context),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(cat),
                          size: 18,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'IT':
        return Icons.code_rounded;
      case 'Business':
        return Icons.business_center_rounded;
      case 'Engineering':
        return Icons.engineering_rounded;
      case 'Hotel':
        return Icons.hotel_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Widget _buildMatchScoreCircle(int score) {
    Color color = score > 80
        ? Colors.green
        : score > 50
        ? Colors.orange
        : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedJobs(JobProvider jobs) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: jobs.suggestedJobs.length,
        itemBuilder: (context, i) =>
            _buildSuggestedCard(jobs.suggestedJobs[i], context),
      ),
    );
  }

  Widget _buildSuggestedCard(Job job, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        ),
        child: _buildGlassBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildGlassBox(
                    padding: const EdgeInsets.all(6),
                    borderRadius: 10,
                    disableBlur: true,
                    child: CachedNetworkImage(
                      imageUrl: job.logoUrl,
                      width: 24,
                      height: 24,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.business_rounded, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      job.companyName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    job.location,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    job.salary,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (job.matchScore != null)
                    _buildMatchScoreCircle(job.matchScore!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedJobs(JobProvider jobs) {
    if (jobs.isLoading) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: 3,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildHorizontalShimmerItem(),
          ),
        ),
      );
    }

    if (jobs.featuredJobs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: jobs.featuredJobs.length,
        itemBuilder: (context, i) =>
            _buildFeaturedCard(jobs.featuredJobs[i], context),
      ),
    );
  }

  Widget _buildFeaturedCard(Job job, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        ),
        child: _buildGlassBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassBox(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 12,
                    disableBlur: true,
                    child: CachedNetworkImage(
                      imageUrl: job.logoUrl,
                      width: 32,
                      height: 32,
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
                  Row(
                    children: [
                      if (job.isAnalyzing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (job.matchScore != null)
                        _buildMatchScoreCircle(job.matchScore!),
                      const SizedBox(width: 8),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => GestureDetector(
                          onTap: () {
                            if (auth.userId != null) {
                              Provider.of<JobProvider>(
                                context,
                                listen: false,
                              ).toggleSaveJob(auth.userId!, job);
                            }
                          },
                          child: Icon(
                            job.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: job.isSaved
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
                maxLines: 1,
              ),
              Text(
                job.companyName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    job.salary,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildGlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    borderRadius: 8,
                    disableBlur: true,
                    child: Text(
                      job.jobType,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildVerticalShimmerItem() {
    return _buildGlassBox(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.getSkeletonBase(context),
            highlightColor: AppTheme.getSkeletonHighlight(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppTheme.getSkeletonBase(context),
                  highlightColor: AppTheme.getSkeletonHighlight(context),
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: AppTheme.getSkeletonBase(context),
                  highlightColor: AppTheme.getSkeletonHighlight(context),
                  child: Container(height: 12, width: 150, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: AppTheme.getSkeletonBase(context),
                      highlightColor: AppTheme.getSkeletonHighlight(context),
                      child: Container(
                        height: 20,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: AppTheme.getSkeletonBase(context),
                      highlightColor: AppTheme.getSkeletonHighlight(context),
                      child: Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalShimmerItem() {
    return _buildGlassBox(
      width: 280,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: AppTheme.getSkeletonBase(context),
                highlightColor: AppTheme.getSkeletonHighlight(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: AppTheme.getSkeletonBase(context),
                highlightColor: AppTheme.getSkeletonHighlight(context),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: AppTheme.getSkeletonBase(context),
            highlightColor: AppTheme.getSkeletonHighlight(context),
            child: Container(height: 16, width: 200, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: AppTheme.getSkeletonBase(context),
            highlightColor: AppTheme.getSkeletonHighlight(context),
            child: Container(height: 12, width: 120, color: Colors.white),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: AppTheme.getSkeletonBase(context),
                highlightColor: AppTheme.getSkeletonHighlight(context),
                child: Container(height: 16, width: 80, color: Colors.white),
              ),
              Shimmer.fromColors(
                baseColor: AppTheme.getSkeletonBase(context),
                highlightColor: AppTheme.getSkeletonHighlight(context),
                child: Container(
                  height: 24,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
