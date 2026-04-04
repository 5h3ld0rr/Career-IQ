import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:careeriq/core/services/cloudinary_service.dart';
import 'package:careeriq/features/jobs/data/jsearch_service.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  final JSearchService _jsearchService = JSearchService();

  Future<Job?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        return Job.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('JobService: Error fetching job: $e');
      return null;
    }
  }

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

    if (location != null && location.isNotEmpty) {
      queryRef = queryRef.where('location', isEqualTo: location);
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
      final q = query.toLowerCase();
      jobs = jobs.where((job) {
        return job.title.toLowerCase().contains(q) ||
            job.companyName.toLowerCase().contains(q) ||
            job.location.toLowerCase().contains(q) ||
            job.description.toLowerCase().contains(q);
      }).toList();
    }

    return jobs;
  }

  Stream<List<Job>> getJobsStream({
    String? category,
    String? jobType,
    String? workMode,
    String? location,
  }) {
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

    if (location != null && location.isNotEmpty) {
      queryRef = queryRef.where('location', isEqualTo: location);
    }

    return queryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();
    });
  }

  Stream<List<Job>> getFeaturedJobsStream({String? category}) {
    Query query = _firestore.collection('jobs');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.limit(5).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();
    });
  }

  Future<List<Job>> fetchLiveJobs({String? query, String? location}) async {
    final response = await _jsearchService.searchJobs(
      query: (query != null && query.isNotEmpty)
          ? '$query in ${location ?? "Sri Lanka"}'
          : 'jobs in ${location ?? "Sri Lanka"}',
    );
    return _jsearchService.toAppJobs(response.jobs);
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

  Future<void> resetUserData(String userId, {bool isRecruiter = false}) async {
    final batch = _firestore.batch();

    // 1. Delete user applications (as an applicant)
    final apps = await _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in apps.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete user saved jobs
    final savedJobs = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_jobs')
        .get();
    for (var doc in savedJobs.docs) {
      batch.delete(doc.reference);
    }

    // 3. Reset profile fields in user document
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'bio': null,
      'skills': [],
      'experience': null,
      'location': null,
      'resumeUrl': null,
      'resumeFileName': null,
      'resumeUploadedAt': null,
      // If recruiter, we might want to keep company basic info but clear description
      'companyDescription': null,
    });

    // 4. If recruiter, handle posted jobs and received applications
    if (isRecruiter) {
      final postedJobs = await _firestore
          .collection('jobs')
          .where('posted_by', isEqualTo: userId)
          .get();
      
      for (var jobDoc in postedJobs.docs) {
        // Find and delete all applications for THIS job
        final jobApps = await _firestore
            .collection('applications')
            .where('jobId', isEqualTo: jobDoc.id)
            .get();
        for (var appDoc in jobApps.docs) {
          batch.delete(appDoc.reference);
        }
        
        // Delete the job itself
        batch.delete(jobDoc.reference);
      }
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
    String? recruiterId,
  }) async {
    await _firestore.collection('applications').add({
      'userId': userId,
      'jobId': jobId,
      'recruiter_id': recruiterId,
      'appliedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'resumeUrl': resumeUrl,
      'coverLetter': coverLetter,
    });
  }

  Stream<QuerySnapshot> getUserApplicationsStream(String userId) {
    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<Map<String, dynamic>> enrichApplicationData(DocumentSnapshot doc) async {
    final appData = doc.data() as Map<String, dynamic>;
    final jobId = appData['jobId'];

    final jobDoc = await _firestore.collection('jobs').doc(jobId).get();

    final jobMap = jobDoc.exists
        ? {'id': jobDoc.id, ...jobDoc.data()!}
        : {
            'id': jobId,
            'title': 'Unknown Position',
            'company_name': 'Unknown Company',
          };

    return {
      'id': doc.id,
      'status': appData['status'] ?? 'pending',
      'appliedAt': appData['appliedAt'],
      'job': jobMap,
      ...appData,
    };
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
      applications.add(await enrichApplicationData(doc));
    }

    applications.sort((a, b) {
      final aTime = a['appliedAt'] as Timestamp?;
      final bTime = b['appliedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
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

  Future<void> addJob(Job job) async {
    await _firestore.collection('jobs').add(job.toJson());
  }

  Future<List<Job>> fetchJobsByUser(String userId) async {
    final snapshot = await _firestore
        .collection('jobs')
        .where('posted_by', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return Job.fromJson(data);
    }).toList();
  }

  Stream<QuerySnapshot> getRecruiterApplicationsStream(String recruiterId) {
    return _firestore
        .collection('applications')
        .where('recruiter_id', isEqualTo: recruiterId)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> fetchApplicantsForJob(String jobId) async {
    final snapshot = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .get();

    List<Map<String, dynamic>> applicants = [];
    for (var doc in snapshot.docs) {
      applicants.add(await enrichApplicant(doc));
    }
    return applicants;
  }

  Stream<QuerySnapshot> getApplicantsStream(String jobId) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots();
  }

  Future<Map<String, dynamic>> enrichApplicant(DocumentSnapshot doc) async {
    final appData = doc.data() as Map<String, dynamic>;
    final userId = appData['userId'];

    final userDoc = await _firestore.collection('users').doc(userId).get();

    final userMap = userDoc.exists
        ? {'id': userDoc.id, ...userDoc.data()!}
        : {
            'id': userId,
            'fullName': 'Unknown Applicant',
            'currentRole': 'Unknown',
          };

    final resumeUrl = (appData['resumeUrl'] as String?)?.isNotEmpty == true
        ? appData['resumeUrl'] as String
        : userMap['resumeUrl'] as String?;

    return {
      'applicationId': doc.id,
      'userId': userId,
      'status': appData['status'] ?? 'New Applied',
      'appliedAt': appData['appliedAt'],
      'resumeUrl': resumeUrl,
      'user': userMap,
      ...appData,
    };
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

  Future<void> deleteJob(String jobId) async {
    final batch = _firestore.batch();

    // 1. Delete all applications for this job
    final apps = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .get();
    for (var doc in apps.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete the job itself
    final jobRef = _firestore.collection('jobs').doc(jobId);
    batch.delete(jobRef);

    await batch.commit();
  }
}
