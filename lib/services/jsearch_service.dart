import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';

/// Service for fetching real-time Sri Lankan job listings via JSearch API.
///
/// JSearch aggregates from Google for Jobs (LinkedIn, Indeed, local boards).
/// Free tier: 200 requests/month on RapidAPI.
///
/// Get your key at: https://rapidapi.com/letscrape-6bRBa3QguO5/api/jsearch
class JSearchService {
  static const String _baseUrl = 'https://jsearch.p.rapidapi.com';
  static const String _host = 'jsearch.p.rapidapi.com';
  static const String _defaultCountry = 'lk'; // Sri Lanka

  String get _apiKey => dotenv.env['RAPIDAPI_KEY'] ?? '';

  /// Fetches live job listings for Sri Lanka from Google for Jobs.
  ///
  /// [query] - Search keywords (e.g., "Software Engineer in Colombo")
  /// [page] - Pagination (1-based, max 50)
  /// [datePosted] - Filter: "today", "3days", "week", "month", or "all"
  /// [employmentTypes] - Comma-separated: "FULLTIME,PARTTIME,CONTRACTOR,INTERN"
  /// [remoteOnly] - If true, return only remote positions
  Future<JSearchResponse> searchJobs({
    String? query,
    int page = 1,
    String? datePosted,
    String? employmentTypes,
    bool remoteOnly = false,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('JSearchService: API key not set. Add RAPIDAPI_KEY to .env');
      return JSearchResponse(jobs: [], status: 'NO_KEY');
    }

    // Build search query — always include Sri Lanka for localized results
    final searchQuery = query != null && query.isNotEmpty
        ? '$query in Sri Lanka'
        : 'jobs in Sri Lanka';

    final queryParams = <String, String>{
      'query': searchQuery,
      'page': page.toString(),
      'num_pages': '1',
      'country': _defaultCountry,
    };

    if (datePosted != null) queryParams['date_posted'] = datePosted;
    if (employmentTypes != null) {
      queryParams['employment_types'] = employmentTypes;
    }
    if (remoteOnly) queryParams['remote_jobs_only'] = 'true';

    final url = Uri.parse('$_baseUrl/search').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _host,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return JSearchResponse.fromJson(data);
      } else {
        debugPrint(
          'JSearchService: API error ${response.statusCode}: ${response.body}',
        );
        return JSearchResponse(jobs: [], status: 'ERROR_${response.statusCode}');
      }
    } catch (e) {
      debugPrint('JSearchService: Network error: $e');
      return JSearchResponse(jobs: [], status: 'NETWORK_ERROR');
    }
  }

  /// Converts JSearch job data into the app's [Job] model.
  List<Job> toAppJobs(List<JSearchJob> jsearchJobs) {
    return jsearchJobs.map((j) {
      return Job(
        id: 'jsearch_${j.jobId}',
        title: j.jobTitle,
        companyName: j.employerName,
        logoUrl: j.employerLogo ?? '',
        location: j.jobCity.isNotEmpty
            ? '${j.jobCity}, ${j.jobCountry}'
            : j.jobCountry.isNotEmpty
                ? j.jobCountry
                : 'Sri Lanka',
        salary: _formatSalary(j.salaryMin, j.salaryMax, j.salaryCurrency),
        description: j.jobDescription,
        responsibilities: j.jobHighlights?.responsibilities ?? [],
        requirements: j.jobHighlights?.qualifications ?? [],
        jobType: _mapEmploymentType(j.jobEmploymentType),
        postedAt: _parseDate(j.jobPostedAt),
        applyUrl: j.jobApplyLink,
      );
    }).toList();
  }

  String _formatSalary(double? min, double? max, String? currency) {
    if (min == null && max == null) return 'Negotiable';
    final cur = currency ?? 'LKR';
    if (min != null && max != null) {
      return '$cur ${_formatNumber(min)} - ${_formatNumber(max)}';
    }
    if (min != null) return '$cur ${_formatNumber(min)}+';
    return 'Up to $cur ${_formatNumber(max!)}';
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toStringAsFixed(0);
  }

  String _mapEmploymentType(String? type) {
    switch (type?.toUpperCase()) {
      case 'FULLTIME':
        return 'Full-time';
      case 'PARTTIME':
        return 'Part-time';
      case 'CONTRACTOR':
        return 'Contract';
      case 'INTERN':
        return 'Internship';
      default:
        return type ?? 'Full-time';
    }
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }
}

/// Top-level API response from JSearch.
class JSearchResponse {
  final List<JSearchJob> jobs;
  final String status;

  JSearchResponse({required this.jobs, required this.status});

  factory JSearchResponse.fromJson(Map<String, dynamic> json) {
    final jobsList = (json['data'] as List<dynamic>?)
            ?.map((j) => JSearchJob.fromJson(j as Map<String, dynamic>))
            .toList() ??
        [];
    return JSearchResponse(
      jobs: jobsList,
      status: json['status'] as String? ?? 'UNKNOWN',
    );
  }
}

/// Represents a single job listing from the JSearch API.
class JSearchJob {
  final String jobId;
  final String jobTitle;
  final String employerName;
  final String? employerLogo;
  final String jobDescription;
  final String? jobEmploymentType;
  final String jobApplyLink;
  final String jobCity;
  final String jobState;
  final String jobCountry;
  final String? jobPostedAt;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final JobHighlights? jobHighlights;

  JSearchJob({
    required this.jobId,
    required this.jobTitle,
    required this.employerName,
    this.employerLogo,
    required this.jobDescription,
    this.jobEmploymentType,
    required this.jobApplyLink,
    required this.jobCity,
    required this.jobState,
    required this.jobCountry,
    this.jobPostedAt,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.jobHighlights,
  });

  factory JSearchJob.fromJson(Map<String, dynamic> json) {
    return JSearchJob(
      jobId: json['job_id'] as String? ?? '',
      jobTitle: json['job_title'] as String? ?? '',
      employerName: json['employer_name'] as String? ?? '',
      employerLogo: json['employer_logo'] as String?,
      jobDescription: json['job_description'] as String? ?? '',
      jobEmploymentType: json['job_employment_type'] as String?,
      jobApplyLink: json['job_apply_link'] as String? ?? '',
      jobCity: json['job_city'] as String? ?? '',
      jobState: json['job_state'] as String? ?? '',
      jobCountry: json['job_country'] as String? ?? '',
      jobPostedAt: json['job_posted_at_datetime_utc'] as String?,
      salaryMin: (json['job_min_salary'] as num?)?.toDouble(),
      salaryMax: (json['job_max_salary'] as num?)?.toDouble(),
      salaryCurrency: json['job_salary_currency'] as String?,
      jobHighlights: json['job_highlights'] != null
          ? JobHighlights.fromJson(
              json['job_highlights'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Job highlights containing responsibilities and qualifications.
class JobHighlights {
  final List<String> responsibilities;
  final List<String> qualifications;

  JobHighlights({
    required this.responsibilities,
    required this.qualifications,
  });

  factory JobHighlights.fromJson(Map<String, dynamic> json) {
    return JobHighlights(
      responsibilities: _extractList(json['Responsibilities']),
      qualifications: _extractList(json['Qualifications']),
    );
  }

  static List<String> _extractList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
