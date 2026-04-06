import 'dart:async';
import 'package:flutter/material.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';
import 'package:careeriq/features/jobs/data/job_service.dart';
import 'package:careeriq/features/ai_assistant/data/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobProvider with ChangeNotifier {
  final JobService _jobService = JobService();
  final AIService _aiService = AIService();

  List<Job> _jobs = [];
  List<Job> _featuredJobs = [];
  List<Job> _suggestedJobs = [];
  List<Job> _savedJobs = [];
  List<Job> _liveJobs = [];
  bool _isLoading = false;
  String? _error;
  String? _currentQuery;
  String? _currentCategory = 'All';
  String _selectedJobType = 'All';
  String _selectedWorkMode = 'All';
  String? _userLocation;
  int _currentPage = 1;
  bool _isMoreLoading = false;
  bool get isMoreLoading => _isMoreLoading;

  List<Map<String, dynamic>> _userApplications = [];
  List<Map<String, dynamic>> _jobApplicants = [];
  List<Job> _postedJobs = [];
  Set<String> _appliedJobIds = {};
  int _totalApplicantsCount = 0;
  StreamSubscription<QuerySnapshot>? _applicantsSubscription;
  StreamSubscription<QuerySnapshot>? _userAppsSubscription;
  StreamSubscription<QuerySnapshot>? _recruiterAppsSubscription;
  StreamSubscription<List<Job>>? _jobsSubscription;
  StreamSubscription<List<Job>>? _featuredJobsSubscription;

  List<Job> get jobs {
    // Combine local database jobs and external API jobs
    final combined = [..._jobs, ..._liveJobs];
    // Sort by postedAt descending to show latest first
    combined.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return combined;
  }

  List<Job> get featuredJobs => _featuredJobs;
  List<Job> get suggestedJobs => _suggestedJobs;
  List<Job> get savedJobs => _savedJobs;
  List<Job> get liveJobs => _liveJobs;
  List<Job> get postedJobs => _postedJobs;
  List<Map<String, dynamic>> get userApplications => _userApplications;
  List<Map<String, dynamic>> get jobApplicants => _jobApplicants;
  Set<String> get appliedJobIds => _appliedJobIds;
  bool isJobApplied(String jobId) => _appliedJobIds.contains(jobId);
  int get totalApplicantsCount => _totalApplicantsCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentQuery => _currentQuery;
  String? get currentCategory => _currentCategory;
  String get selectedJobType => _selectedJobType;
  String get selectedWorkMode => _selectedWorkMode;

  Future<Job?> getJobById(String jobId) async {
    return await _jobService.getJobById(jobId);
  }

  Future<void> loadJobs({
    String? query,
    String? category,
    String? jobType,
    String? workMode,
    String? location,
    String? userLocation,
    bool resetPage = true,
  }) async {
    if (resetPage) _currentPage = 1;
    _currentQuery = query ?? _currentQuery;
    _currentCategory = category ?? _currentCategory;
    _selectedJobType = jobType ?? _selectedJobType;
    _selectedWorkMode = workMode ?? _selectedWorkMode;
    _userLocation = userLocation ?? _userLocation;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final effectiveLocation = location ?? _userLocation;

    startJobsStream(
      query: _currentQuery,
      category: _currentCategory,
      jobType: _selectedJobType,
      workMode: _selectedWorkMode,
      location: effectiveLocation,
      userLocation: _userLocation,
    );

    // Live jobs are external (JSearch), so they remain as a Future fetch
    try {
      final live = await _jobService.fetchLiveJobs(
        query: _currentQuery,
        location: effectiveLocation,
      );
      _liveJobs = live;
      notifyListeners();
    } catch (e) {
      debugPrint('Live jobs fetch failed (non-blocking): $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void startJobsStream({
    String? query,
    String? category,
    String? jobType,
    String? workMode,
    String? location,
    String? userLocation,
  }) {
    stopJobsStream();
    _jobsSubscription = _jobService
        .getJobsStream(
          category: category,
          jobType: jobType,
          workMode: workMode,
          location: location,
        )
        .listen((allJobs) {
          List<Job> filtered = allJobs;

          if (query != null && query.isNotEmpty) {
            final q = query.toLowerCase();
            filtered = filtered.where((job) {
              return job.title.toLowerCase().contains(q) ||
                  job.companyName.toLowerCase().contains(q) ||
                  job.location.toLowerCase().contains(q) ||
                  job.description.toLowerCase().contains(q);
            }).toList();
          }

          // Sync saved status
          for (var job in filtered) {
            job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
          }

          _jobs = filtered;

          // Update suggested jobs if userLocation is set
          // We use the full available list (filtered only by category/type/mode) to pick suggestions
          final targetLocation = userLocation ?? location;
          if (targetLocation != null && targetLocation.isNotEmpty) {
            final loc = targetLocation.toLowerCase();
            _suggestedJobs = _jobs
                .where(
                  (j) =>
                      j.location.toLowerCase().contains(loc) ||
                      loc.contains(j.location.toLowerCase()),
                )
                .toList();
          } else {
            _suggestedJobs = [];
          }

          notifyListeners();
        });
  }

  void stopJobsStream() {
    _jobsSubscription?.cancel();
    _jobsSubscription = null;
  }

  Future<void> loadPostedJobs(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _postedJobs = await _jobService.fetchJobsByUser(userId);
      int count = 0;
      for (var job in _postedJobs) {
        final applicants = await _jobService.fetchApplicantsForJob(job.id);
        count += applicants.length;
      }
      _totalApplicantsCount = count;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addJob(Job job) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _jobService.addJob(job);
      _postedJobs.insert(0, job);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearFilters() async {
    _currentQuery = null;
    _currentCategory = 'All';
    await loadJobs();
  }

  Future<void> loadFeaturedJobs({String? category}) async {
    startFeaturedJobsStream(category: category);
  }

  void startFeaturedJobsStream({String? category}) {
    stopFeaturedJobsStream();
    _featuredJobsSubscription = _jobService
        .getFeaturedJobsStream(category: category)
        .listen((jobs) {
          for (var job in jobs) {
            job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
          }
          _featuredJobs = jobs;
          notifyListeners();
        });
  }

  void stopFeaturedJobsStream() {
    _featuredJobsSubscription?.cancel();
    _featuredJobsSubscription = null;
  }

  Future<void> loadUserApplications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userApplications = await _jobService.fetchUserApplications(userId);
      _appliedJobIds = _userApplications
          .map((app) => (app['jobId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      _error = 'Failed to load applications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadApplicantsForJob(String jobId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobApplicants = await _jobService.fetchApplicantsForJob(jobId);
    } catch (e) {
      _error = 'Failed to load applicants: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    String status, {
    Map<String, dynamic>? data,
  }) async {
    try {
      await _jobService.updateApplicationStatus(
        applicationId,
        status,
        data: data,
      );
      final index = _jobApplicants.indexWhere(
        (a) => a['applicationId'] == applicationId,
      );
      if (index != -1) {
        _jobApplicants[index]['status'] = status;
        if (data != null) {
          _jobApplicants[index].addAll(data);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> applyForJob(
    String userId,
    String jobId, {
    String? resumeUrl,
    String? coverLetter,
    String? recruiterId,
  }) async {
    try {
      await _jobService.applyForJob(
        userId,
        jobId,
        resumeUrl: resumeUrl,
        coverLetter: coverLetter,
        recruiterId: recruiterId,
      );
      await loadUserApplications(userId);
    } catch (e) {
      debugPrint('Error applying for job: $e');
      rethrow;
    }
  }

  Future<void> submitApplication({
    required String userId,
    required String jobId,
    required dynamic resumeFile,
    bool useProfileResume = false,
    String? coverLetter,
    String? recruiterId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      String? resumeUrl;

      if (useProfileResume) {
        resumeUrl = await _jobService.getProfileResumeUrl(userId);
      } else {
        resumeUrl = await _jobService.uploadResume(resumeFile, userId);
      }

      await applyForJob(
        userId,
        jobId,
        resumeUrl: resumeUrl,
        coverLetter: coverLetter,
        recruiterId: recruiterId,
      );
    } catch (e) {
      _error = 'Failed to submit application';
      debugPrint('Error submitting application: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seedDatabase(String userId, {bool isRecruiter = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _jobService.resetUserData(userId, isRecruiter: isRecruiter);
      await loadUserApplications(userId);
      await loadSavedJobs(userId);
      await loadJobs();
    } catch (e) {
      _error = 'Failed to reset data: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedJobs(String userId) async {
    try {
      _savedJobs = await _jobService.fetchSavedJobs(userId);
      for (var job in _jobs) {
        job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
      }
      for (var job in _featuredJobs) {
        job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved jobs: $e');
    }
  }

  Future<void> toggleSaveJob(String userId, Job job) async {
    final originalStatus = job.isSaved;
    try {
      if (job.isSaved) {
        job.isSaved = false;
        _savedJobs.removeWhere((j) => j.id == job.id);
        notifyListeners();
        await _jobService.unsaveJob(userId, job.id);
      } else {
        job.isSaved = true;
        _savedJobs.add(job);
        notifyListeners();
        await _jobService.saveJob(userId, job.id);
      }
      for (var j in _jobs) {
        if (j.id == job.id) j.isSaved = job.isSaved;
      }
      for (var j in _featuredJobs) {
        if (j.id == job.id) j.isSaved = job.isSaved;
      }
      notifyListeners();
    } catch (e) {
      job.isSaved = originalStatus;
      if (originalStatus) {
        if (!_savedJobs.any((j) => j.id == job.id)) _savedJobs.add(job);
      } else {
        _savedJobs.removeWhere((j) => j.id == job.id);
      }
      debugPrint('Error toggling save job: $e');
      notifyListeners();
    }
  }

  bool _isCalculatingMatchScores = false;

  Future<void> calculateMatchScores(String userProfile) async {
    if (userProfile.isEmpty ||
        _isCalculatingMatchScores ||
        (_jobs.isEmpty && _featuredJobs.isEmpty)) {
      return;
    }

    _isCalculatingMatchScores = true;
    final processedIds = <String>{};

    final targetJobs = [
      ..._jobs.take(10), // Limit to top 10 for performance
      ..._featuredJobs.take(5),
      ..._suggestedJobs.take(5),
    ];

    int updateCount = 0;
    for (var job in targetJobs) {
      if (processedIds.contains(job.id) || job.matchScore != null) continue;

      job.isAnalyzing = true;
      // Only notify every few items or if it's important to keep UI responsive without jank
      if (updateCount % 3 == 0) notifyListeners();

      try {
        final score = await _aiService.calculateJobMatchScore(
          resumeContent: userProfile,
          jobDescription:
              "${job.title} at ${job.companyName}\n${job.description}\nRequirements: ${job.requirements.join(', ')}",
        );

        job.matchScore = score;
        processedIds.add(job.id);

        // Sync score across lists
        for (var lJob in _jobs) {
          if (lJob.id == job.id) lJob.matchScore = score;
        }
        for (var fJob in _featuredJobs) {
          if (fJob.id == job.id) fJob.matchScore = score;
        }
        for (var sJob in _suggestedJobs) {
          if (sJob.id == job.id) sJob.matchScore = score;
        }
        updateCount++;
      } catch (e) {
        debugPrint('Error calculating score for ${job.id}: $e');
        job.matchScore = 0;
      } finally {
        job.isAnalyzing = false;
        // Batch notification after each set
        if (updateCount % 2 == 0) notifyListeners();
      }
    }
    _isCalculatingMatchScores = false;
    notifyListeners();
  }

  void startApplicantsStream(String jobId) {
    stopApplicantsStream();
    _applicantsSubscription = _jobService.getApplicantsStream(jobId).listen((
      snapshot,
    ) async {
      List<Map<String, dynamic>> enrichedApplicants = [];
      for (var doc in snapshot.docs) {
        enrichedApplicants.add(await _jobService.enrichApplicant(doc));
      }
      _jobApplicants = enrichedApplicants;
      notifyListeners();
    });
  }

  void stopApplicantsStream() {
    _applicantsSubscription?.cancel();
    _applicantsSubscription = null;
  }

  void startUserAppsStream(String userId) {
    stopUserAppsStream();
    _userAppsSubscription = _jobService
        .getUserApplicationsStream(userId)
        .listen((snapshot) async {
          // Immediately update job IDs for UI reactivity
          _appliedJobIds = snapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['jobId']?.toString(),
              )
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();
          notifyListeners();

          List<Map<String, dynamic>> enrichedApps = [];
          for (var doc in snapshot.docs) {
            enrichedApps.add(await _jobService.enrichApplicationData(doc));
          }

          enrichedApps.sort((a, b) {
            final aTime = a['appliedAt'] as Timestamp?;
            final bTime = b['appliedAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          _userApplications = enrichedApps;
          // Re-sync after enrichment to be sure
          _appliedJobIds = _userApplications
              .map((app) => (app['jobId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet();
          notifyListeners();
        });
  }

  void stopUserAppsStream() {
    _userAppsSubscription?.cancel();
    _userAppsSubscription = null;
  }

  void startRecruiterAppsStream(String recruiterId) {
    stopRecruiterAppsStream();
    _recruiterAppsSubscription = _jobService
        .getRecruiterApplicationsStream(recruiterId)
        .listen((snapshot) {
          _totalApplicantsCount = snapshot.docs.length;
          notifyListeners();
        });
  }

  void stopRecruiterAppsStream() {
    _recruiterAppsSubscription?.cancel();
    _recruiterAppsSubscription = null;
  }

  Future<void> deleteJob(String jobId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _jobService.deleteJob(jobId);
      _postedJobs.removeWhere((job) => job.id == jobId);
      _jobs.removeWhere((job) => job.id == jobId);
      _liveJobs.removeWhere((job) => job.id == jobId);
      _featuredJobs.removeWhere((job) => job.id == jobId);
      _suggestedJobs.removeWhere((job) => job.id == jobId);
      _savedJobs.removeWhere((job) => job.id == jobId);

      // Refresh recruiter state (counts etc)
      await loadPostedJobs(userId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreJobs() async {
    if (_isMoreLoading || _isLoading) return;

    _isMoreLoading = true;
    notifyListeners();

    try {
      _currentPage++;
      final effectiveLocation = _userLocation;
      final moreLive = await _jobService.fetchLiveJobs(
        query: _currentQuery,
        location: effectiveLocation,
        page: _currentPage,
      );

      if (moreLive.isNotEmpty) {
        _liveJobs.addAll(moreLive);
      }
    } catch (e) {
      debugPrint('Load more failed: $e');
      _currentPage--;
    } finally {
      _isMoreLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopApplicantsStream();
    stopUserAppsStream();
    stopRecruiterAppsStream();
    stopJobsStream();
    stopFeaturedJobsStream();
    super.dispose();
  }
}
