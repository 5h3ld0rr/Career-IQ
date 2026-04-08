import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:careeriq/features/jobs/screens/home_screen.dart';
import 'package:careeriq/features/jobs/screens/saved_jobs_screen.dart';
import 'package:careeriq/features/profile/screens/profile_screen.dart';
import 'package:careeriq/features/tracker/screens/application_tracker_screen.dart';
import 'package:careeriq/features/interview/screens/mock_interview_screen.dart';
import 'package:careeriq/features/salary_roi/screens/salary_roi_screen.dart';
import 'package:careeriq/features/chat/screens/expert_ai_chat_screen.dart';
import 'package:careeriq/features/recruiter/screens/recruiter_dashboard_screen.dart';
import 'package:careeriq/features/recruiter/screens/ats_dashboard_screen.dart';
import 'package:careeriq/features/recruiter/screens/manage_jobs_screen.dart';
import 'package:careeriq/features/recruiter/screens/recruiter_tools_screen.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => MainWrapperState();
}

class MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  void setSelectedIndex(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }
  bool _bottomNavVisible = true;
  bool _isAIHubMenuOpen = false;

  late List<Widget> _userScreens;
  late List<Widget> _recruiterScreens;

  @override
  void initState() {
    super.initState();
    _userScreens = [
      const HomeScreen(key: ValueKey('home')),
      const ApplicationTrackerScreen(key: ValueKey('tracker')),
      const SavedJobsScreen(key: ValueKey('saved')),
      const ProfileScreen(key: ValueKey('profile_v')),
    ];
    _recruiterScreens = [
      const RecruiterDashboardScreen(key: ValueKey('rec_dash')),
      const ATSDashboardScreen(key: ValueKey('ats_dash')),
      const ManageJobsScreen(key: ValueKey('manage_jobs')),
      const ProfileScreen(key: ValueKey('rec_profile')),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGlobalStreams();
    });
  }

  void _initGlobalStreams() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final jobProv = Provider.of<JobProvider>(context, listen: false);

    if (auth.userId != null) {
      if (!auth.isRecruiter) {
        jobProv.startUserAppsStream(auth.userId!);
      } else {
        jobProv.startRecruiterAppsStream(auth.userId!);
      }
    }
  }

  List<Widget> _getScreens(bool isRecruiter) =>
      isRecruiter ? _recruiterScreens : _userScreens;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screens = _getScreens(authProvider.isRecruiter);

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (_isAIHubMenuOpen) return true;
              final metrics = notification.metrics;
              if (metrics.axis != Axis.vertical) return true;

              if (notification.direction == ScrollDirection.reverse &&
                  metrics.pixels > 50) {
                if (_bottomNavVisible) {
                  setState(() => _bottomNavVisible = false);
                }
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_bottomNavVisible) {
                  setState(() => _bottomNavVisible = true);
                }
              }
              return true;
            },
            child: _FadeIndexedStack(index: _selectedIndex, children: screens),
          ),

          IgnorePointer(
            ignoring: !_isAIHubMenuOpen,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _isAIHubMenuOpen ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) {
                if (value == 0) return const SizedBox.shrink();
                return Opacity(
                  opacity: value,
                  child: GestureDetector(
                    onTap: () => setState(() => _isAIHubMenuOpen = false),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 5 * value,
                        sigmaY: 5 * value,
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35 * value),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (!authProvider.isRecruiter) ...[
            _buildArcAction(
              context,
              index: 0,
              icon: Icons.psychology_rounded,
              label: 'Interview',
              color: const Color(0xFFFF9100),
              onTap: () => _navigateTo(const MockInterviewScreen()),
            ),
            _buildArcAction(
              context,
              index: 1,
              icon: Icons.insights_rounded,
              label: 'ROI',
              color: const Color(0xFF00E676),
              onTap: () => _navigateTo(const SalaryROIScreen()),
            ),
            _buildArcAction(
              context,
              index: 2,
              icon: Icons.forum_rounded,
              label: 'Expert',
              color: const Color(0xFFD500F9),
              onTap: () => _navigateTo(const ExpertAIChatScreen()),
            ),
          ] else ...[
            _buildArcAction(
              context,
              index: 0,
              icon: Icons.auto_awesome_rounded,
              label: 'JD Gen',
              color: const Color(0xFFD500F9),
              onTap: () => _navigateTo(const RecruiterToolsScreen()),
            ),
            _buildArcAction(
              context,
              index: 1,
              icon: Icons.rule_rounded,
              label: 'Scorer',
              color: const Color(0xFF00E676),
              onTap: () => _navigateTo(const RecruiterToolsScreen()),
            ),
            _buildArcAction(
              context,
              index: 2,
              icon: Icons.analytics_rounded,
              label: 'Market',
              color: const Color(0xFFFF9100),
              onTap: () => _navigateTo(const RecruiterToolsScreen()),
            ),
          ],
        ],
      ),
      bottomNavigationBar: RepaintBoundary(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          offset: _bottomNavVisible ? Offset.zero : const Offset(0, 1.2),
          child: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    final isRecruiter = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).isRecruiter;

    return Container(
      height: 85,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(context),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.light ? 0.05 : 0.4,
            ),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Home',
                ),
                if (!isRecruiter)
                  _buildNavItem(
                    1,
                    Icons.assignment_outlined,
                    Icons.assignment_rounded,
                    'Tracker',
                  )
                else
                  _buildNavItem(
                    1,
                    Icons.people_outline_rounded,
                    Icons.people_alt_rounded,
                    'ATS',
                  ),
                _buildNavItem(
                  -1,
                  Icons.widgets_outlined,
                  Icons.widgets_rounded,
                  '',
                ),
                if (!isRecruiter)
                  _buildNavItem(
                    2,
                    Icons.bookmark_outline_rounded,
                    Icons.bookmark_rounded,
                    'Saved',
                  )
                else
                  _buildNavItem(
                    2,
                    Icons.work_outline_rounded,
                    Icons.work_rounded,
                    'Jobs',
                  ),
                _buildNavItem(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    setState(() => _isAIHubMenuOpen = false);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      }
    });
  }

  void _showAIHubMenu() {
    HapticFeedback.heavyImpact();
    setState(() => _isAIHubMenuOpen = !_isAIHubMenuOpen);
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final bool isAIHub = index == -1;
    final bool isSelected = isAIHub
        ? _isAIHubMenuOpen
        : _selectedIndex == index;
    final theme = Theme.of(context);
    final activeColor = isAIHub
        ? theme.colorScheme.primary
        : theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (isAIHub) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.isRecruiter) {
              _navigateTo(const RecruiterToolsScreen());
            } else {
              _showAIHubMenu();
            }
          } else if (!isSelected) {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedIndex = index;
              _isAIHubMenuOpen = false;
            });
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isAIHub)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isSelected ? 52 : 44,
                    height: isSelected ? 52 : 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(
                            alpha: isSelected ? 0.35 : 0.12,
                          ),
                          theme.colorScheme.secondary.withValues(
                            alpha: isSelected ? 0.2 : 0.05,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 15,
                              ),
                            ]
                          : null,
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    isSelected ? filledIcon : outlineIcon,
                    key: ValueKey(isSelected),
                    color: isSelected ? activeColor : inactiveColor,
                    size: isAIHub ? 30 : 26,
                  ),
                ),
              ],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArcAction(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double centerX = screenWidth / 2;

    double posX = centerX;
    double posY = 45;

    if (_isAIHubMenuOpen) {
      posY = 145 + (index == 1 ? 35 : 0);
      if (index == 0) {
        posX = centerX - 90;
      } else if (index == 1) {
        posX = centerX;
      } else {
        posX = centerX + 90;
      }
    }

    return AnimatedPositioned(
      duration: Duration(milliseconds: 550 + (index * 80)),
      curve: Curves.easeOutBack,
      bottom: posY,
      left: posX - 32,
      child: AnimatedScale(
        duration: Duration(milliseconds: 450 + (index * 100)),
        curve: Curves.easeOutCubic,
        scale: _isAIHubMenuOpen ? 1.0 : 0.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
          opacity: _isAIHubMenuOpen ? 1.0 : 0.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({required this.index, required this.children});

  @override
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _prevIndex) {
      _controller.reset();
      _controller.forward();
      _prevIndex = widget.index;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}
