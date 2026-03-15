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
  bool isSaved;

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
    this.isSaved = false,
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
      postedAt: json['posted_at'] != null
          ? DateTime.parse(json['posted_at'])
          : DateTime.now(),
      applyUrl: json['apply_url'] ?? '',
    );
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
    };
  }
}
