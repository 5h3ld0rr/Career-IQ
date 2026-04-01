import 'package:cloud_firestore/cloud_firestore.dart';

class Interview {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final DateTime scheduledAt;
  final String? zoomLink;
  final List<String> commonQuestions;
  final String companySummary;
  final bool syncedWithCalendar;
  final String? calendarEventId;

  Interview({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.scheduledAt,
    this.zoomLink,
    required this.commonQuestions,
    required this.companySummary,
    this.syncedWithCalendar = false,
    this.calendarEventId,
  });

  Interview copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyName,
    DateTime? scheduledAt,
    String? zoomLink,
    List<String>? commonQuestions,
    String? companySummary,
    bool? syncedWithCalendar,
    String? calendarEventId,
  }) {
    return Interview(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      zoomLink: zoomLink ?? this.zoomLink,
      commonQuestions: commonQuestions ?? this.commonQuestions,
      companySummary: companySummary ?? this.companySummary,
      syncedWithCalendar: syncedWithCalendar ?? this.syncedWithCalendar,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }

  factory Interview.fromMap(String id, Map<String, dynamic> data) {
    return Interview(
      id: id,
      jobId: data['job_id'] ?? '',
      jobTitle: data['job_title'] ?? '',
      companyName: data['company_name'] ?? '',
      scheduledAt: (data['scheduled_at'] as Timestamp).toDate(),
      zoomLink: data['zoom_link'],
      commonQuestions: List<String>.from(data['common_questions'] ?? []),
      companySummary: data['company_summary'] ?? '',
      syncedWithCalendar: data['synced_with_calendar'] ?? false,
      calendarEventId: data['calendar_event_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'job_title': jobTitle,
      'company_name': companyName,
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'zoom_link': zoomLink,
      'common_questions': commonQuestions,
      'company_summary': companySummary,
      'synced_with_calendar': syncedWithCalendar,
      'calendar_event_id': calendarEventId,
    };
  }
}
