import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:careeriq/models/job.dart';
import 'package:careeriq/providers/job_provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/core/theme.dart';
import '../details/job_details_screen.dart';
import '../cv_analysis/cv_upload_screen.dart';
import '../tracker/application_tracker_screen.dart';
import '../interview/mock_interview_screen.dart';
import '../../widgets/job_filter_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Design', 'Tech', 'Marketing', 'Sales'];

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
    final auth = Provider.of<AuthProvider>(context);
    final jobs = Provider.of<JobProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => jobs.loadJobs(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(auth, context),
                    const SizedBox(height: 24),
                    _buildSearchArea(context, jobs),
                    const SizedBox(height: 24),
                    _buildSectionTitle('AI Career Tools'),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildCategoryFilters(jobs),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Featured Jobs', showSeeAll: true),
                    _buildFeaturedJobs(jobs),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Latest Job Listings', showSeeAll: true),
                    _buildLatestJobs(jobs),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: -50,
      right: -50,
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

  Widget _buildGlassBox({required Widget child, double? width, EdgeInsets? padding, double borderRadius = 24}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
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
              Text('Hello ${auth.userName ?? "User"}!', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
              const Text('Find your dream job', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
            ],
          ),
          _buildGlassBox(
            borderRadius: 50,
            padding: const EdgeInsets.all(4),
            child: const CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea(BuildContext context, JobProvider jobs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildGlassBox(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TextField(
          controller: _searchController,
          onSubmitted: (val) => jobs.loadJobs(query: val),
          decoration: InputDecoration(
            hintText: 'Search for jobs...',
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (showSeeAll) TextButton(onPressed: () {}, child: const Text('See All', style: TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionItem(context, 'CV Analysis', Icons.document_scanner_rounded, const CVUploadScreen()),
          _buildActionItem(context, 'Tracker', Icons.dashboard_customize_rounded, const ApplicationTrackerScreen()),
          _buildActionItem(context, 'Mock Interview', Icons.mic_rounded, const MockInterviewScreen()),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _buildGlassBox(
          width: 140,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.black87, size: 24),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(JobProvider jobs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _categories.map((cat) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ChoiceChip(
            label: Text(cat),
            selected: jobs.currentCategory == cat,
            onSelected: (sel) => sel ? jobs.loadJobs(category: cat) : null,
            selectedColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.4),
            labelStyle: TextStyle(color: jobs.currentCategory == cat ? Colors.black : Colors.black54, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFeaturedJobs(JobProvider jobs) {
    return SizedBox(
      height: 180,
      child: jobs.isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: jobs.featuredJobs.length,
        itemBuilder: (context, i) => _buildFeaturedCard(jobs.featuredJobs[i], context),
      ),
    );
  }

  Widget _buildFeaturedCard(Job job, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job))),
        child: _buildGlassBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassBox(padding: const EdgeInsets.all(8), borderRadius: 12, child: CachedNetworkImage(imageUrl: job.logoUrl, width: 24, height: 24)),
                  const Icon(Icons.bookmark_outline_rounded, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 12),
              Text(job.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17), maxLines: 1),
              Text(job.companyName, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.salary, style: const TextStyle(fontWeight: FontWeight.bold)),
                  _buildGlassBox(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), borderRadius: 8, child: Text(job.jobType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestJobs(JobProvider jobs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: jobs.jobs.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: jobs.jobs[i]))),
            child: _buildGlassBox(
              child: Row(
                children: [
                  _buildGlassBox(borderRadius: 12, padding: const EdgeInsets.all(8), child: CachedNetworkImage(imageUrl: jobs.jobs[i].logoUrl, width: 32, height: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jobs.jobs[i].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${jobs.jobs[i].companyName} • ${jobs.jobs[i].location}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLatestJobsList(JobProvider jobs) { return Container(); } // Placeholder not needed
}
