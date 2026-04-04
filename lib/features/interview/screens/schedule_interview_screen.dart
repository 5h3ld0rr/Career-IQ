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

      if (mounted) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        final pushService = notificationProvider.pushService;
        if (pushService != null) {
          await pushService.scheduleInterviewPrep(finalInterview);
        }
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
                          Icons.calendar_month_rounded,
                          'Date',
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          onTap: _selectDate,
                        ),
                        Divider(
                          height: 32,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          thickness: 1,
                        ),
                        _buildInfoTile(
                          Icons.access_time_filled_rounded,
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
                    height: 62,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSyncing || _isGeneratingDetails
                            ? null
                            : _scheduleInterview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                const Color(0xFF0288D1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isSyncing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'SYNC TO CALENDAR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gemini is researching company insights...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gathering interview highlights for you',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepDetails() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        _buildGlassBox(
          context,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Company Summary',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _prepDetails!['companySummary'] ?? 'No summary available.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildGlassBox(
          context,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Key Questions',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(List<String>.from(_prepDetails!['commonQuestions'] ?? []))
                  .take(4)
                  .map(
                    (q) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: onSurface.withValues(alpha: 0.8),
                              ),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.2),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orangeAccent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
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
