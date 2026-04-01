import 'dart:ui';
import 'package:careeriq/features/recruiter/screens/applicant_profile_screen.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';

class ATSDashboardScreen extends StatefulWidget {
  final String? initialJobId;
  const ATSDashboardScreen({super.key, this.initialJobId});

  @override
  State<ATSDashboardScreen> createState() => _ATSDashboardScreenState();
}

class _ATSDashboardScreenState extends State<ATSDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _stages = [
    'All',
    'New Applied',
    'Shortlisted',
    'Interviewing',
    'Hired',
    'Rejected',
  ];

  String? _selectedJobId;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    if (auth.userId != null) {
      await jobProvider.loadPostedJobs(auth.userId!);

      if (jobProvider.postedJobs.isNotEmpty) {
        String? targetId = widget.initialJobId;

        if (targetId != null &&
            !jobProvider.postedJobs.any((j) => j.id == targetId)) {
          targetId = null;
        }

        setState(() {
          _selectedJobId = targetId ?? jobProvider.postedJobs.first.id;
        });

        if (_selectedJobId != null) {
          jobProvider.startApplicantsStream(_selectedJobId!);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _onJobSelected(String? jobId) {
    if (jobId != null && jobId != _selectedJobId) {
      setState(() {
        _selectedJobId = jobId;
        _isInitializing = true;
      });
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobProvider.startApplicantsStream(jobId);
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.stopApplicantsStream();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredCandidates(
    List<Map<String, dynamic>> allApplicants,
  ) {
    final stage = _stages[_tabController.index];
    if (stage == 'All') return allApplicants;
    return allApplicants.where((c) => c['status'] == stage).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobProvider = Provider.of<JobProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicant Tracking',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Manage your talent pipeline',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(jobProvider),
    );
  }

  Widget _buildBody(JobProvider jobProvider) {
    if (_isInitializing && jobProvider.postedJobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobProvider.postedJobs.isEmpty) {
      return Center(
        child: Text(
          'You haven\'t posted any jobs yet.',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
      );
    }

    final applicants = jobProvider.jobApplicants;

    return Column(
      children: [
        _buildJobSelector(jobProvider.postedJobs),
        const SizedBox(height: 16),
        _buildStageTabs(applicants),
        Expanded(
          child: _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    final filtered = _getFilteredCandidates(applicants);

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No candidates found for this stage.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 16,
                        bottom: 100,
                        left: 16,
                        right: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildCandidateCard(filtered[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJobSelector(List<Job> jobs) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getGlassBorderColor(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedJobId,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_circle_rounded,
            color: theme.colorScheme.primary,
          ),
          items: jobs.map((job) {
            return DropdownMenuItem<String>(
              value: job.id,
              child: Text(
                job.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _onJobSelected,
        ),
      ),
    );
  }

  Widget _buildStageTabs(List<Map<String, dynamic>> applicants) {
    final theme = Theme.of(context);

    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        padding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.5,
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        onTap: (_) =>
            setState(() {}), // trigger rebuild to update filtered items
        tabs: _stages.map((stage) {
          final count = stage == 'All'
              ? applicants.length
              : applicants.where((c) => c['status'] == stage).length;

          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stage),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: count > 0
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidateData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Map<String, dynamic> user = candidateData['user'] ?? {};
    final String name = user['name'] ?? user['fullName'] ?? 'Unknown Applicant';
    final String role = user['role'] ?? user['currentRole'] ?? 'No Headline provided';
    final String stage = candidateData['status'] ?? 'New Applied';
    final String applicationId = candidateData['applicationId'];

    int score = 85;
    Color scoreColor = Colors.green;

    String initials = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : '?';
    if (name.contains(' ')) {
      final parts = name.split(' ');
      if (parts.length > 1) {
        initials = parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicantProfileScreen(candidateData: candidateData),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(context),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timeline_rounded,
                                size: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                initialValue: stage,
                                child: Text(
                                  stage,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                    decorationColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                onSelected: (newStage) {
                                  final provider = Provider.of<JobProvider>(
                                    context,
                                    listen: false,
                                  );
                                  provider.updateApplicationStatus(
                                    applicationId,
                                    newStage,
                                  );
                                  AppSnackBar.show('Moved $name to $newStage');
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    'New Applied',
                                    'Shortlisted',
                                    'Interviewing',
                                    'Hired',
                                    'Rejected',
                                  ].map((String choice) {
                                    return PopupMenuItem<String>(
                                      value: choice,
                                      child: Text(
                                        choice,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: scoreColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$score%',
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 12),
                if (stage == 'Shortlisted' || stage == 'Interviewing')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        context,
                        Icons.fact_check_rounded,
                        'Application Outcome',
                        const Color(0xFFFF9100),
                        () => _showScheduleModal(
                          context,
                          candidateData,
                          name,
                          applicationId,
                        ),
                      ),
                    ],
                  ),
                if (stage == 'New Applied')
                  Center(
                    child: Text(
                      'Shortlist candidate to evaluate outcome',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ), // GestureDetector
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleModal(
    BuildContext context,
    Map<String, dynamic> candidateData,
    String name,
    String applicationId,
  ) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    bool? passed; // null = not yet selected
    final remarksCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(ctx).padding.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Application Outcome',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Step 1: Outcome toggle ──────────────────────────
                    const Text(
                      'CV & APPLICATION OUTCOME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOutcomeToggle(
                            context,
                            label: 'Passed',
                            icon: Icons.check_circle_rounded,
                            color: Colors.green,
                            selected: passed == true,
                            onTap: () =>
                                setModalState(() => passed = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOutcomeToggle(
                            context,
                            label: 'Failed',
                            icon: Icons.cancel_rounded,
                            color: Colors.red,
                            selected: passed == false,
                            onTap: () =>
                                setModalState(() => passed = false),
                          ),
                        ),
                      ],
                    ),

                    // ── Step 2: Date + Time (Pass only) ────────────────
                    if (passed == true) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'SCHEDULE NEXT INTERVIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildScheduleRow(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: 'Interview Date',
                        value:
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        color: const Color(0xFFFF9100),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildScheduleRow(
                        context,
                        icon: Icons.access_time_rounded,
                        label: 'Interview Time',
                        value: selectedTime.format(context),
                        color: const Color(0xFF03A9F4),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                      ),
                    ],

                    // ── Step 3: Remarks (once outcome chosen) ───────────
                    if (passed != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'REMARKS (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksCtrl,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Strong technical skills, needs improvement in communication…',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Confirm button ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                passed! ? Colors.green : Colors.red,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            passed!
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 20,
                          ),
                          label: Text(
                            passed!
                                ? 'Confirm & Schedule'
                                : 'Confirm Rejection',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: () {
                            final provider = Provider.of<JobProvider>(
                              context,
                              listen: false,
                            );
                            final data = {
                              if (passed!) ...{
                                'interviewDate': selectedDate,
                                'interviewTime':
                                    '${selectedTime.hour}:${selectedTime.minute}',
                              },
                              'remarks': remarksCtrl.text,
                              'lastResultAt': DateTime.now(),
                            };
                            provider.updateApplicationStatus(
                              applicationId,
                              passed! ? 'Interviewing' : 'Rejected',
                              data: data,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            AppSnackBar.show(
                              passed!
                                  ? 'Interview scheduled for $name'
                                  : 'Application marked as Rejected',
                              isError: !passed!,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_rounded, size: 16, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeToggle(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
