import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/interview/data/interview_model.dart';
import 'package:careeriq/features/ai_assistant/providers/ai_provider.dart';
import 'package:careeriq/features/notifications/providers/notification_provider.dart';
import 'package:careeriq/core/services/calendar_service.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';

class ScheduleInterviewScreen extends StatefulWidget {
  final Map<String, dynamic> application;

  const ScheduleInterviewScreen({super.key, required this.application});

  @override
  State<ScheduleInterviewScreen> createState() =>
      _ScheduleInterviewScreenState();
}

class _ScheduleInterviewScreenState extends State<ScheduleInterviewScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isGeneratingDetails = false;
  bool _isSyncing = false;

  Map<String, dynamic>? _prepDetails;

  @override
  void initState() {
    super.initState();
    _generatePrepDetails();
  }

  Future<void> _generatePrepDetails() async {
    setState(() => _isGeneratingDetails = true);
    try {
      final aiProvider = Provider.of<AIProvider>(context, listen: false);
      final job = widget.application['job'];
      final details = await aiProvider.getInterviewPrep(
        companyName: job['company_name'],
        jobDescription: job['description'] ?? 'Software Engineer role',
      );
      setState(() {
        _prepDetails = details;
        _isGeneratingDetails = false;
      });
    } catch (e) {
      setState(() => _isGeneratingDetails = false);
      if (mounted) {
        AppSnackBar.show('Failed to generate prep details: $e', isError: true);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleInterview() async {
    if (_prepDetails == null) return;

    setState(() => _isSyncing = true);

    try {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final interview = Interview(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId:
            widget.application['job_id'] ??
            (widget.application['job'] is Map
                ? (widget.application['job']['id'] ?? '')
                : ''),
        jobTitle: widget.application['job']['title'],
        companyName: widget.application['job']['company_name'],
        scheduledAt: scheduledAt,
        companySummary: _prepDetails!['companySummary'] ?? '',
        commonQuestions: List<String>.from(
          _prepDetails!['commonQuestions'] ?? [],
        ),
      );

      final calendarEventId = await CalendarService.syncInterview(interview);
      final finalInterview = interview.copyWith(
        calendarEventId: calendarEventId,
      );

      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final pushService = notificationProvider.pushService;

      if (pushService != null) {
        await pushService.scheduleInterviewPrep(finalInterview);
      }

      if (mounted) {
        AppSnackBar.show('Interview scheduled and synced with Calendar! 🗓️');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show('Scheduling failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Smart Scheduler',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlassBox(
                    context,
                    child: Column(
                      children: [
                        _buildInfoTile(
                          Icons.calendar_today_rounded,
                          'Date',
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          onTap: _selectDate,
                        ),
                        const Divider(height: 32, color: Colors.white24),
                        _buildInfoTile(
                          Icons.access_time_rounded,
                          'Time',
                          _selectedTime.format(context),
                          onTap: _selectTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'AI Interview Prep Highlights',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (_isGeneratingDetails)
                    _buildLoadingPrep()
                  else if (_prepDetails != null)
                    _buildPrepDetails()
                  else
                    const Text('Could not generate prep details.'),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSyncing || _isGeneratingDetails
                          ? null
                          : _scheduleInterview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: _isSyncing
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'SYNC TO CALENDAR',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPrep() {
    return _buildGlassBox(
      context,
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Gemini is researching the company...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepDetails() {
    return Column(
      children: [
        _buildGlassBox(
          context,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Company Summary',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _prepDetails!['companySummary'] ?? '',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildGlassBox(
          context,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 20,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Key Questions',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...(List<String>.from(_prepDetails!['commonQuestions'] ?? []))
                  .take(3)
                  .map(
                    (q) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              q,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white24,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.blueAccent.withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBox(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 28,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(context),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
