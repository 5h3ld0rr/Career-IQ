import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart';
import '../models/job.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  static const String _mockJobsJson = '''
  [
    {
      "id": "1",
      "title": "Software Engineer",
      "company_name": "Google",
      "category": "IT",
      "logo_url": "https://logo.clearbit.com/google.com",
      "location": "Mountain View, CA",
      "salary": "\$150k - \$200k",
      "description": "We are looking for a Software Engineer...",
      "responsibilities": ["Coding", "Design"],
      "requirements": ["3+ years experience"],
      "job_type": "Full-time",
      "posted_at": "2024-03-10T10:00:00Z",
      "apply_url": "https://careers.google.com"
    },
    {
      "id": "2",
      "title": "Business Analyst",
      "company_name": "Airbnb",
      "category": "Business",
      "logo_url": "https://logo.clearbit.com/airbnb.com",
      "location": "Remote",
      "salary": "\$130k - \$180k",
      "description": "Join our business team...",
      "responsibilities": ["Analysis", "Strategy"],
      "requirements": ["Expert in Excel"],
      "job_type": "Remote",
      "posted_at": "2024-03-12T09:00:00Z",
      "apply_url": "https://careers.airbnb.com"
    },
    {
      "id": "3",
      "title": "Mechanical Engineer",
      "company_name": "Tesla",
      "category": "Engineering",
      "logo_url": "https://logo.clearbit.com/tesla.com",
      "location": "Palo Alto, CA",
      "salary": "\$120k - \$160k",
      "description": "Build cars...",
      "responsibilities": ["AutoCAD", "Design"],
      "requirements": ["BS in Engineering"],
      "job_type": "Full-time",
      "posted_at": "2024-03-13T14:30:00Z",
      "apply_url": "https://careers.tesla.com"
    },
    {
      "id": "4",
      "title": "Hotel Manager",
      "company_name": "Hilton",
      "category": "Hotel",
      "logo_url": "https://logo.clearbit.com/hilton.com",
      "location": "San Jose, CA",
      "salary": "\$80k - \$110k",
      "description": "Manage our premium hotels...",
      "responsibilities": ["Guest service", "Operations"],
      "requirements": ["Hospitality degree"],
      "job_type": "Full-time",
      "posted_at": "2024-03-14T11:00:00Z",
      "apply_url": "https://careers.hilton.com"
    }
  ]
  ''';

  Future<List<Job>> fetchJobs({
    String? query,
    String? category,
    String? jobType,
    String? workMode,
    String? location,
  }) async {
    Query queryRef = _firestore.collection('jobs');

    if (category != null && category != 'All') {
      // Assuming jobs have a 'category' field in Firestore
      queryRef = queryRef.where('category', isEqualTo: category);
    }

    if (jobType != null && jobType != 'All') {
      queryRef = queryRef.where('job_type', isEqualTo: jobType);
    }

    if (workMode != null && workMode != 'All') {
      // 'Remote' vs 'On-site' for example
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

    // Client side filtering for text search because Firestore doesn't support partial text queries natively without integration
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

    // Sort by posted_at descending
    jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));

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

  /// Method to reset system data (clears jobs and user data, then seeds)
  Future<void> seedJobs({String? userId}) async {
    final batch = _firestore.batch();

    // 1. Delete all current jobs
    final allJobs = await _firestore.collection('jobs').get();
    for (var doc in allJobs.docs) {
      batch.delete(doc.reference);
    }

    // 2. If userId is provided, delete their applications and saved jobs
    if (userId != null) {
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
    }

    // 3. Seed fresh jobs
    final List<dynamic> data = json.decode(_mockJobsJson);
    for (var jobData in data) {
      final jsonMap = jobData as Map<String, dynamic>;
      final docRef = _firestore.collection('jobs').doc(jsonMap['id']);
      // Remove id from map before saving as it will be the doc id
      final Map<String, dynamic> cleanData = Map.from(jsonMap);
      cleanData.remove('id');
      batch.set(docRef, cleanData);
    }

    await batch.commit();
  }

  Future<String> uploadResume(dynamic file, String userId, {String? fileName}) async {
    try {
      final url = await _cloudinary.uploadFile(
        file: file,
        folder: 'CareerIQ/CV',
        fileName: fileName ?? 'resume_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
        .orderBy('appliedAt', descending: true)
        .get();

    List<Map<String, dynamic>> applications = [];

    for (var doc in snapshot.docs) {
      final appData = doc.data();
      final jobId = appData['jobId'];

      // Fetch job details for each application
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        final jobData = jobDoc.data()!;
        applications.add({
          'id': doc.id,
          'status': appData['status'],
          'appliedAt': appData['appliedAt'],
          'job': {'id': jobDoc.id, ...jobData},
        });
      }
    }
    return applications;
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
}
