import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/job_service.dart';

class JobProvider with ChangeNotifier {
  final JobService _jobService = JobService();

  List<Job> _jobs = [];
  List<Job> _featuredJobs = [];
  final List<Job> _savedJobs = [];
  bool _isLoading = false;
  String? _error;

  List<Job> get jobs => _jobs;
  List<Job> get featuredJobs => _featuredJobs;
  List<Job> get savedJobs => _savedJobs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadJobs({
    String? query,
    String? jobType,
    String? location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _jobService.fetchJobs(
        query: query,
        jobType: jobType,
        location: location,
      );
      
      // Auto-seed if database is empty and no query/filter is applied
      if (_jobs.isEmpty && (query == null || query.isEmpty) && (jobType == null || jobType == 'All')) {
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


  Future<void> loadFeaturedJobs() async {
    try {
      _featuredJobs = await _jobService.fetchFeaturedJobs();
      for (var job in _featuredJobs) {
        job.isSaved = _savedJobs.any((saved) => saved.id == job.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured jobs: \$e');
    }
  }

  Future<void> applyForJob(String userId, String jobId) async {
    try {
      await _jobService.applyForJob(userId, jobId);
    } catch (e) {
      debugPrint('Error applying for job: $e');
      rethrow;
    }
  }

  Future<void> seedDatabase() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _jobService.seedJobs();
      await loadJobs();
    } catch (e) {
      _error = 'Failed to seed database: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSaveJob(Job job) {
    if (job.isSaved) {
      job.isSaved = false;
      _savedJobs.removeWhere((j) => j.id == job.id);
    } else {
      job.isSaved = true;
      _savedJobs.add(job);
    }
    // TODO: Persist to Firestore
    notifyListeners();
  }
}
