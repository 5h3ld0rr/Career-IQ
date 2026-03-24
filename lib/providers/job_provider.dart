import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/job_service.dart';

class JobProvider with ChangeNotifier {
  final JobService _jobService = JobService();

  List<Job> _jobs = [];
  List<Job> _featuredJobs = [];
  List<Job> _savedJobs = [];
  bool _isLoading = false;
  String? _error;
  String? _currentQuery;
  String? _currentCategory = 'All';
  String _selectedJobType = 'All';
  String _selectedWorkMode = 'All';

  List<Map<String, dynamic>> _userApplications = [];

  List<Job> get jobs => _jobs;
  List<Job> get featuredJobs => _featuredJobs;
  List<Job> get savedJobs => _savedJobs;
  List<Map<String, dynamic>> get userApplications => _userApplications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentQuery => _currentQuery;
  String? get currentCategory => _currentCategory;
  String get selectedJobType => _selectedJobType;
  String get selectedWorkMode => _selectedWorkMode;

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

      // Auto-seed if database is empty and no query/filter is applied
      if (_jobs.isEmpty &&
          (_currentQuery == null || _currentQuery!.isEmpty) &&
          (_currentCategory == null || _currentCategory == 'All')) {
        await _jobService.seedJobs();
        _jobs = await _jobService.fetchJobs();
      }

      // Sync with saved jobs
      for (var job in _jobs) {
        job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
      }
    } catch (e) {
      _error = e.toString();
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

  Future<void> applyForJob(String userId, String jobId, {String? resumeUrl, String? coverLetter}) async {
    try {
      await _jobService.applyForJob(userId, jobId, resumeUrl: resumeUrl, coverLetter: coverLetter);
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
    String? coverLetter,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resumeUrl = await _jobService.uploadResume(resumeFile, userId);
      await applyForJob(userId, jobId, resumeUrl: resumeUrl, coverLetter: coverLetter);
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
      await _jobService.seedJobs(userId: userId);
      await loadJobs();
      if (userId != null) {
        await loadUserApplications(userId);
        await loadSavedJobs(userId);
      }
    } catch (e) {
      _error = 'Failed to seed database: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedJobs(String userId) async {
    try {
      _savedJobs = await _jobService.fetchSavedJobs(userId);
      // Sync isSaved status across all lists
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
      // Sync other lists that might contain this job
      for (var j in _jobs) { if (j.id == job.id) j.isSaved = job.isSaved; }
      for (var j in _featuredJobs) { if (j.id == job.id) j.isSaved = job.isSaved; }
      notifyListeners();
    } catch (e) {
      // Revert on error
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
}
