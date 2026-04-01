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

  List<Map<String, dynamic>> _userApplications = [];
  List<Map<String, dynamic>> _jobApplicants = [];
  List<Job> _postedJobs = [];
  int _totalApplicantsCount = 0;
  StreamSubscription<QuerySnapshot>? _applicantsSubscription;

  List<Job> get jobs => _jobs;
  List<Job> get featuredJobs => _featuredJobs;
  List<Job> get suggestedJobs => _suggestedJobs;
  List<Job> get savedJobs => _savedJobs;
  List<Job> get liveJobs => _liveJobs;
  List<Job> get postedJobs => _postedJobs;
  List<Map<String, dynamic>> get userApplications => _userApplications;
  List<Map<String, dynamic>> get jobApplicants => _jobApplicants;
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
  }) async {
    _currentQuery = query ?? _currentQuery;
    _currentCategory = category ?? _currentCategory;
    _selectedJobType = jobType ?? _selectedJobType;
    _selectedWorkMode = workMode ?? _selectedWorkMode;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _jobService.fetchJobs(
        query: _currentQuery,
        category: _currentCategory,
        jobType: _selectedJobType == 'All' ? null : _selectedJobType,
        workMode: _selectedWorkMode == 'All' ? null : _selectedWorkMode,
        location: location,
      );

      try {
        final live = await _jobService.fetchLiveJobs(
          query: _currentQuery,
          location: location,
        );
        final existingIds = _jobs.map((j) => j.id).toSet();
        final newLive = live.where((j) => !existingIds.contains(j.id)).toList();
        _liveJobs = newLive;
        _jobs = [..._jobs, ...newLive];
      } catch (e) {
        debugPrint('Live jobs fetch failed (non-blocking): $e');
      }

      if (location != null && location.isNotEmpty) {
        _suggestedJobs = _jobs
            .where(
              (j) =>
                  j.location.toLowerCase().contains(location.toLowerCase()) ||
                  location.toLowerCase().contains(j.location.toLowerCase()),
            )
            .toList();
      } else {
        _suggestedJobs = [];
      }

      for (var job in _jobs) {
        job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
      }
      for (var job in _suggestedJobs) {
        job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    try {
      _featuredJobs = await _jobService.fetchFeaturedJobs(category: category);
      for (var job in _featuredJobs) {
        job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured jobs: $e');
    }
  }

  Future<void> loadUserApplications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userApplications = await _jobService.fetchUserApplications(userId);
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
      await _jobService.updateApplicationStatus(applicationId, status,
          data: data);
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
  }) async {
    try {
      await _jobService.applyForJob(
        userId,
        jobId,
        resumeUrl: resumeUrl,
        coverLetter: coverLetter,
      );
      await loadUserApplications(userId); // Reload after application
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

  Future<void> seedDatabase([String? userId]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (userId != null) {
        await _jobService.resetUserData(userId);
        await loadUserApplications(userId);
        await loadSavedJobs(userId);
      }
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

  Future<void> calculateMatchScores(String userProfile) async {
    if (userProfile.isEmpty || (_jobs.isEmpty && _featuredJobs.isEmpty)) return;

    final processedIds = <String>{};

    final targetJobs = [
      ..._jobs.take(5),
      ..._featuredJobs.take(3),
      ..._suggestedJobs.take(3),
    ];

    for (var job in targetJobs) {
      if (processedIds.contains(job.id) || job.matchScore != null) continue;

      job.isAnalyzing = true;
      notifyListeners();

      try {
        final score = await _aiService.calculateJobMatchScore(
          resumeContent: userProfile,
          jobDescription:
              "${job.title} at ${job.companyName}\n${job.description}\nRequirements: ${job.requirements.join(', ')}",
        );

        job.matchScore = score;
        processedIds.add(job.id);

        for (var lJob in _jobs) {
          if (lJob.id == job.id) lJob.matchScore = score;
        }
        for (var fJob in _featuredJobs) {
          if (fJob.id == job.id) fJob.matchScore = score;
        }
        for (var sJob in _suggestedJobs) {
          if (sJob.id == job.id) sJob.matchScore = score;
        }
      } catch (e) {
        debugPrint('Error calculating score for ${job.id}: $e');
        job.matchScore = 0;
      } finally {
        job.isAnalyzing = false;
        notifyListeners();
      }
    }
  }

  void startApplicantsStream(String jobId) {
    stopApplicantsStream();
    _applicantsSubscription = _jobService.getApplicantsStream(jobId).listen((snapshot) async {
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

  @override
  void dispose() {
    stopApplicantsStream();
    super.dispose();
  }
}
