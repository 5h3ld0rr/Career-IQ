class Job {
  final String id;
  final String title;
  final String companyName;
  final String logoUrl;
  final String location;
  final String salary;
  final String description;
  final List<String> responsibilities;
  final List<String> requirements;
  final String jobType; // Full-time, Part-time, Remote
  final DateTime postedAt;
  final String applyUrl;
  final String? postedBy;
  final String? companyPhone;
  bool isSaved;
  int? matchScore;
  bool isAnalyzing;

  Job({
    required this.id,
    required this.title,
    required this.companyName,
    required this.logoUrl,
    required this.location,
    required this.salary,
    required this.description,
    required this.responsibilities,
    required this.requirements,
    required this.jobType,
    required this.postedAt,
    required this.applyUrl,
    this.postedBy,
    this.companyPhone,
    this.isSaved = false,
    this.matchScore,
    this.isAnalyzing = false,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      companyName: json['company_name'] ?? '',
      logoUrl: json['logo_url'] ?? 'https://via.placeholder.com/150',
      location: json['location'] ?? '',
      salary: json['salary'] ?? 'Competitive',
      description: json['description'] ?? '',
      responsibilities: List<String>.from(json['responsibilities'] ?? []),
      requirements: List<String>.from(json['requirements'] ?? []),
      jobType: json['job_type'] ?? 'Full-time',
      postedAt: json['posted_at'] is String
          ? DateTime.parse(json['posted_at'])
          : (json['posted_at'] as dynamic)?.toDate() ?? DateTime.now(),
      applyUrl: json['apply_url'] ?? '',
      postedBy: json['posted_by'],
      companyPhone: json['company_phone'],
      matchScore: json['match_score'],
    );
  }

  factory Job.fromMap(String id, Map<String, dynamic> data) {
    return Job(
      id: id,
      title: data['title'] ?? '',
      companyName: data['company_name'] ?? '',
      logoUrl: data['logo_url'] ?? 'https://via.placeholder.com/150',
      location: data['location'] ?? '',
      salary: data['salary'] ?? 'Competitive',
      description: data['description'] ?? '',
      responsibilities: List<String>.from(data['responsibilities'] ?? []),
      requirements: List<String>.from(data['requirements'] ?? []),
      jobType: data['job_type'] ?? 'Full-time',
      postedAt: data['posted_at'] is String
          ? DateTime.parse(data['posted_at'])
          : (data['posted_at'] as dynamic)?.toDate() ?? DateTime.now(),
      applyUrl: data['apply_url'] ?? '',
      postedBy: data['posted_by'],
      companyPhone: data['company_phone'],
      matchScore: data['match_score'],
    );
  }

  factory Job.fromFirestore(dynamic doc) {
    return Job.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company_name': companyName,
      'logo_url': logoUrl,
      'location': location,
      'salary': salary,
      'description': description,
      'responsibilities': responsibilities,
      'requirements': requirements,
      'job_type': jobType,
      'posted_at': postedAt.toIso8601String(),
      'apply_url': applyUrl,
      'posted_by': postedBy,
      'company_phone': companyPhone,
    };
  }
}
