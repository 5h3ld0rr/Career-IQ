import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:careeriq/features/interview/data/interview_model.dart';

class CalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<String?> syncInterview(Interview interview) async {
    try {
      await _googleSignIn.authenticate();

      final authz = await _googleSignIn.authorizationClient.authorizeScopes([
        calendar.CalendarApi.calendarEventsScope,
      ]);

      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          authz.accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [calendar.CalendarApi.calendarEventsScope],
      );

      final httpClient = auth.authenticatedClient(http.Client(), credentials);
      final calendarApi = calendar.CalendarApi(httpClient);

      final event = calendar.Event(
        summary: 'Interview Prep: ${interview.jobTitle}',
        status: 'confirmed',
        description:
            'Career-IQ Interview Preparation\n\n'
            'Company: ${interview.companyName}\n'
            'Summary: ${interview.companySummary}\n'
            'Key Questions to Prepare:\n- ${interview.commonQuestions.join("\n- ")}',
        start: calendar.EventDateTime(
          dateTime: interview.scheduledAt,
          timeZone: DateTime.now().timeZoneName,
        ),
        end: calendar.EventDateTime(
          dateTime: interview.scheduledAt.add(const Duration(hours: 1)),
          timeZone: DateTime.now().timeZoneName,
        ),
        reminders: calendar.EventReminders(
          useDefault: false,
          overrides: [calendar.EventReminder(method: 'popup', minutes: 30)],
        ),
      );

      final createdEvent = await calendarApi.events.insert(event, "primary");
      return createdEvent.id;
    } catch (e) {
      print('Error syncing with Calendar: $e');
      return null;
    }
  }
}
