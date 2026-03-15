import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:elitehire/models/job.dart';
import 'package:elitehire/providers/job_provider.dart';
import 'package:elitehire/providers/auth_provider.dart';
import 'package:elitehire/core/theme.dart';
import '../details/job_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Design', 'Tech', 'Marketing', 'Sales', 'Finance'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
      Provider.of<JobProvider>(context, listen: false).loadFeaturedJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => jobProvider.loadJobs(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, \${authProvider.userName ?? "User"}!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Find your dream job',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.secondaryBlue,
                        child: Text(
                          authProvider.userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) => jobProvider.loadJobs(query: val),
                    onChanged: (val) {
                      if (val.isEmpty) {
                        jobProvider.loadJobs(query: '');
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for jobs, companies...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              jobProvider.loadJobs(query: '');
                            },
                          )
                        : Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: _categories
                        .map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: jobProvider.currentCategory == cat,
                                onSelected: (selected) {
                                  if (selected) {
                                    jobProvider.loadJobs(category: cat);
                                  }
                                },
                                selectedColor: AppTheme.primaryBlue,
                                labelStyle: TextStyle(
                                  color: jobProvider.currentCategory == cat ? Colors.white : AppTheme.darkGray,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: AppTheme.lightGray,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                side: BorderSide.none,
                                showCheckmark: false,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(title: 'Featured Jobs'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: jobProvider.isLoading && jobProvider.featuredJobs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: jobProvider.featuredJobs.length,
                          itemBuilder: (context, index) {
                            final job = jobProvider.featuredJobs[index];
                            return FeaturedJobCard(job: job);
                          },
                        ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SectionHeader(title: 'Latest Job Listings'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: jobProvider.isLoading && jobProvider.jobs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: jobProvider.jobs.length,
                          itemBuilder: (context, index) {
                            final job = jobProvider.jobs[index];
                            return JobListItem(job: job);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: () {}, child: const Text('See All')),
      ],
    );
  }
}

class FeaturedJobCard extends StatelessWidget {
  final Job job;
  const FeaturedJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job))),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: CachedNetworkImage(imageUrl: job.logoUrl, width: 32, height: 32),
                ),
                IconButton(
                  icon: Icon(job.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, color: Colors.white),
                  onPressed: () => Provider.of<JobProvider>(context, listen: false).toggleSaveJob(job),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(job.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(job.companyName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job.salary, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text(job.jobType, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class JobListItem extends StatelessWidget {
  final Job job;
  const JobListItem({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightGray),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(12)),
              child: CachedNetworkImage(imageUrl: job.logoUrl, width: 40, height: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('\${job.companyName} • \${job.location}',
                      style: const TextStyle(color: AppTheme.mediumGray, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(job.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: job.isSaved ? AppTheme.primaryBlue : AppTheme.mediumGray),
              onPressed: () => Provider.of<JobProvider>(context, listen: false).toggleSaveJob(job),
            ),
          ],
        ),
      ),
    );
  }
}
