import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _mockJobsJson = '''
  [
    {
      "id": "1",
      "title": "Senior Product Designer",
      "company_name": "Google",
      "logo_url": "https://logo.clearbit.com/google.com",
      "location": "Mountain View, CA",
      "salary": "\$150k - \$200k",
      "description": "We are looking for a Senior Product Designer to join our Cloud team...",
      "responsibilities": ["Lead design for core cloud features", "Collaborate with PMs and Engineers", "Mentor junior designers"],
      "requirements": ["5+ years of experience", "Strong portfolio", "Expert in Figma"],
      "job_type": "Full-time",
      "posted_at": "2024-03-10T10:00:00Z",
      "apply_url": "https://careers.google.com"
    },
    {
      "id": "2",
      "title": "Software Engineer (Flutter)",
      "company_name": "Airbnb",
      "logo_url": "https://logo.clearbit.com/airbnb.com",
      "location": "Remote",
      "salary": "\$130k - \$180k",
      "description": "Join our mobile team to build beautiful experiences with Flutter...",
      "responsibilities": ["Develop new features using Flutter", "Ensure high performance and responsiveness", "Write clean, testable code"],
      "requirements": ["3+ years of Flutter experience", "Deep understanding of Dart", "Experience with Firebase"],
      "job_type": "Remote",
      "posted_at": "2024-03-12T09:00:00Z",
      "apply_url": "https://careers.airbnb.com"
    },
    {
      "id": "3",
      "title": "Marketing Manager",
      "company_name": "Spotify",
      "logo_url": "https://logo.clearbit.com/spotify.com",
      "location": "New York, NY",
      "salary": "\$100k - \$140k",
      "description": "Drive growth and engagement for our podcast platform...",
      "responsibilities": ["Develop marketing campaigns", "Analyze user data", "Manage brand partnerships"],
      "requirements": ["Bachelor's in Marketing", "4+ years of experience", "Passion for music and podcasts"],
      "job_type": "Full-time",
      "posted_at": "2024-03-13T14:30:00Z",
      "apply_url": "https://careers.spotify.com"
    },
    {
      "id": "4",
      "title": "UI/UX Intern",
      "company_name": "Adobe",
      "logo_url": "https://logo.clearbit.com/adobe.com",
      "location": "San Jose, CA",
      "salary": "\$40/hr - \$55/hr",
      "description": "Learn from the best in the industry and work on creative tools...",
      "responsibilities": ["Assist in user research", "Create wireframes and prototypes", "Participate in design reviews"],
      "requirements": ["Currently pursuing design degree", "Knowledge of Adobe Creative Cloud", "Eagerness to learn"],
      "job_type": "Part-time",
      "posted_at": "2024-03-14T11:00:00Z",
      "apply_url": "https://careers.adobe.com"
    }
  ]
  ''';

  Future<List<Job>> fetchJobs({
    String? query,
    String? jobType,
    String? location,
  }) async {
    Query queryRef = _firestore.collection('jobs');

    if (jobType != null && jobType != 'All') {
      queryRef = queryRef.where('job_type', isEqualTo: jobType);
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

  Future<List<Job>> fetchFeaturedJobs() async {
    final snapshot = await _firestore.collection('jobs').limit(5).get();

    return snapshot.docs.map((doc) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        doc.data() as Map,
      );
      data['id'] = doc.id;
      return Job.fromJson(data);
    }).toList();
  }

  /// One-time method to seed some initial data into Firestore
  Future<void> seedJobs() async {
    final List<dynamic> data = json.decode(_mockJobsJson);
    final batch = _firestore.batch();

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

  Future<void> applyForJob(String userId, String jobId) async {
    await _firestore.collection('applications').add({
      'userId': userId,
      'jobId': jobId,
      'appliedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
