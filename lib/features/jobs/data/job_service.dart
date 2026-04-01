import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:careeriq/core/services/cloudinary_service.dart';
import 'package:careeriq/features/jobs/data/jsearch_service.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  final JSearchService _jsearchService = JSearchService();

  Future<List<Job>> fetchJobs({
    String? query,
    String? category,
    String? jobType,
    String? workMode,
    String? location,
  }) async {
    Query queryRef = _firestore.collection('jobs');

    if (category != null && category != 'All') {
      queryRef = queryRef.where('category', isEqualTo: category);
    }

    if (jobType != null && jobType != 'All') {
      queryRef = queryRef.where('job_type', isEqualTo: jobType);
    }

    if (workMode != null && workMode != 'All') {
      queryRef = queryRef.where(
        'location',
        isEqualTo: workMode == 'Remote' ? 'Remote' : workMode,
      );
    }

    final snapshot = await queryRef.get();
    List<Job> jobs = snapshot.docs.map((doc) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        doc.data() as Map,
      );
      data['id'] = doc.id;
      return Job.fromJson(data);
    }).toList();

    if (query != null && query.isNotEmpty) {
      jobs = jobs
          .where(
            (j) =>
                j.title.toLowerCase().contains(query.toLowerCase()) ||
                j.companyName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    if (location != null && location.isNotEmpty) {
      jobs = jobs
          .where(
            (j) => j.location.toLowerCase().contains(location.toLowerCase()),
          )
          .toList();
    }

    jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));

    return jobs;
  }

  /// Fetches real-time job listings from JSearch API for Sri Lanka.
  ///
  /// Results are cached to Firestore for offline access.
  /// Falls back to Firestore-cached jobs if the API call fails.
  Future<List<Job>> fetchLiveJobs({
    String? query,
    String? location,
    int page = 1,
  }) async {
    try {
      final response = await _jsearchService.searchJobs(
        query: query,
        page: page,
      );

      if (response.jobs.isNotEmpty) {
        final appJobs = _jsearchService.toAppJobs(response.jobs);

        await _cacheLiveJobs(appJobs);

        return appJobs;
      }
    } catch (e) {
      debugPrint('JobService: JSearch fetch failed, falling back to cache: $e');
    }

    return _getCachedLiveJobs(query: query);
  }

  /// Caches live jobs to Firestore for offline access.
  Future<void> _cacheLiveJobs(List<Job> jobs) async {
    final batch = _firestore.batch();
    for (final job in jobs) {
      final docRef = _firestore.collection('live_jobs_cache').doc(job.id);
      batch.set(docRef, {
        ...job.toJson(),
        'cached_at': FieldValue.serverTimestamp(),
      });
    }
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('JobService: Cache write failed: $e');
    }
  }

  /// Retrieves cached live jobs from Firestore.
  Future<List<Job>> _getCachedLiveJobs({String? query}) async {
    final snapshot = await _firestore
        .collection('live_jobs_cache')
        .orderBy('cached_at', descending: true)
        .limit(50)
        .get();

    List<Job> jobs = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return Job.fromJson(data);
    }).toList();

    if (query != null && query.isNotEmpty) {
      jobs = jobs
          .where(
            (j) =>
                j.title.toLowerCase().contains(query.toLowerCase()) ||
                j.companyName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    return jobs;
  }

  Future<List<Job>> fetchFeaturedJobs({String? category}) async {
    Query query = _firestore.collection('jobs');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.limit(5).get();

    return snapshot.docs.map((doc) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        doc.data() as Map,
      );
      data['id'] = doc.id;
      return Job.fromJson(data);
    }).toList();
  }

  /// Resets user-specific data (applications and saved jobs).
  Future<void> resetUserData(String userId) async {
    final batch = _firestore.batch();

    final apps = await _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in apps.docs) {
      batch.delete(doc.reference);
    }

    final savedJobs = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_jobs')
        .get();
    for (var doc in savedJobs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<String?> getProfileResumeUrl(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['resumeUrl'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile resume: $e');
      return null;
    }
  }

  Future<String> uploadResume(
    dynamic file,
    String userId, {
    String? fileName,
  }) async {
    try {
      final url = await _cloudinary.uploadFile(
        file: file,
        folder: 'CareerIQ/CV',
        fileName:
            fileName ?? 'resume_${DateTime.now().millisecondsSinceEpoch}.pdf',
        isImage: false,
      );
      if (url == null) throw Exception('Upload returned empty URL');
      return url;
    } catch (e) {
      throw Exception('Failed to upload resume to Cloudinary: $e');
    }
  }

  Future<void> applyForJob(
    String userId,
    String jobId, {
    String? resumeUrl,
    String? coverLetter,
  }) async {
    await _firestore.collection('applications').add({
      'userId': userId,
      'jobId': jobId,
      'appliedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'resumeUrl': resumeUrl,
      'coverLetter': coverLetter,
    });
  }

  Future<List<Map<String, dynamic>>> fetchUserApplications(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> applications = [];

    for (var doc in snapshot.docs) {
      final appData = doc.data();
      final jobId = appData['jobId'];

      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();

      final jobMap = jobDoc.exists
          ? {'id': jobDoc.id, ...jobDoc.data()!}
          : {
              'id': jobId,
              'title': 'Unknown Position',
              'company_name': 'Unknown Company',
            };

      applications.add({
        'id': doc.id,
        'status': appData['status'] ?? 'pending',
        'appliedAt': appData['appliedAt'],
        'job': jobMap,
      });
    }

    applications.sort((a, b) {
      final aTime = a['appliedAt'] as Timestamp?;
      final bTime = b['appliedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime); // Latest first
    });

    return applications;
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    String newStatus, {
    Map<String, dynamic>? data,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
    };
    if (data != null) {
      updateData.addAll(data);
    }
    await _firestore
        .collection('applications')
        .doc(applicationId)
        .update(updateData);
  }

  Future<List<Map<String, dynamic>>> fetchApplicantsForJob(String jobId) async {
    final snapshot = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .get();

    List<Map<String, dynamic>> applicants = [];

    for (var doc in snapshot.docs) {
      final appData = doc.data();
      final userId = appData['userId'];

      final userDoc = await _firestore.collection('users').doc(userId).get();

      final userMap = userDoc.exists
          ? {'id': userDoc.id, ...userDoc.data()!}
          : {
              'id': userId,
              'fullName': 'Unknown Applicant',
              'currentRole': 'Unknown',
            };

      // Use resume from application; fall back to user's profile resume.
      final resumeUrl =
          (appData['resumeUrl'] as String?)?.isNotEmpty == true
              ? appData['resumeUrl'] as String
              : userMap['resumeUrl'] as String?;

      applicants.add({
        'applicationId': doc.id,
        'userId': userId,
        'status': appData['status'] ?? 'New Applied',
        'appliedAt': appData['appliedAt'],
        'resumeUrl': resumeUrl,
        'user': userMap,
      });
    }

    return applicants;
  }

  Future<void> saveJob(String userId, String jobId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_jobs')
        .doc(jobId)
        .set({'savedAt': FieldValue.serverTimestamp()});
  }

  Future<void> unsaveJob(String userId, String jobId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_jobs')
        .doc(jobId)
        .delete();
  }

  Future<List<Job>> fetchSavedJobs(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_jobs')
        .get();

    List<Job> savedJobs = [];
    for (var doc in snapshot.docs) {
      final jobDoc = await _firestore.collection('jobs').doc(doc.id).get();
      if (jobDoc.exists) {
        final job = Job.fromFirestore(jobDoc);
        job.isSaved = true;
        savedJobs.add(job);
      }
    }
    return savedJobs;
  }

  Future<void> addJob(Job job) async {
    await _firestore.collection('jobs').doc(job.id).set(job.toJson());
  }

  Future<List<Job>> fetchJobsByUser(String userId) async {
    final snapshot = await _firestore
        .collection('jobs')
        .where('posted_by', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
  }
}
