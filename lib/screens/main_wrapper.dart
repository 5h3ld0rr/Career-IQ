import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'home/home_screen.dart';
import 'saved/saved_jobs_screen.dart';
import 'profile/profile_screen.dart';
import 'tracker/application_tracker_screen.dart';
import 'cv_analysis/cv_upload_screen.dart';
import 'interview/mock_interview_screen.dart';
import 'salary_roi/salary_roi_screen.dart';
import 'chat/expert_ai_chat_screen.dart';
import 'recruiter/recruiter_dashboard_screen.dart';
import 'recruiter/ats_dashboard_screen.dart';
import '../core/theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  bool _bottomNavVisible = true;
  bool _isAIHubMenuOpen = false;

  List<Widget> _getScreens(bool isRecruiter) {
    if (isRecruiter) {
      return [
        const RecruiterDashboardScreen(),
        const ATSDashboardScreen(),
        const Scaffold(body: Center(child: Text('Smart Inbox Coming Soon', style: TextStyle(fontWeight: FontWeight.bold)))),
        const ProfileScreen(),
      ];
    }
    return [
      const HomeScreen(),
      const ApplicationTrackerScreen(),
      const SavedJobsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      extendBody: true,
      body: Stack(
        children: [
          // Main Content
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (_isAIHubMenuOpen) return true; // Don't hide while menu is open
              if (notification.direction == ScrollDirection.reverse) {
                if (_bottomNavVisible) setState(() => _bottomNavVisible = false);
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_bottomNavVisible) setState(() => _bottomNavVisible = true);
              }
              return true;
            },
            child: IndexedStack(index: _selectedIndex, children: _getScreens(authProvider.isRecruiter)),
          ),

          // Menu Overlay Background (Dim)
          if (_isAIHubMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isAIHubMenuOpen = false),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isAIHubMenuOpen ? 1.0 : 0.0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

          // Floating AI Hub Menu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            bottom: _isAIHubMenuOpen ? 120 : -300,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _isAIHubMenuOpen ? 1.0 : 0.0,
              child: _AIHubMenuOverlay(
                onToolSelected: (screen) => _navigateTo(screen),
                onSwitchRole: () {
                  setState(() => _isAIHubMenuOpen = false);
                  authProvider.toggleUserRole();
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
        opacity: _bottomNavVisible ? 1.0 : 0.0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuart,
          offset: _bottomNavVisible ? Offset.zero : const Offset(0, 1.5),
          child: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
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
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                if (!Provider.of<AuthProvider>(context).isRecruiter)
                  _buildNavItem(1, Icons.assignment_outlined, Icons.assignment_rounded, 'Tracker')
                else
                  _buildNavItem(1, Icons.people_outline_rounded, Icons.people_alt_rounded, 'ATS'),
                _buildNavItem(-1, Icons.widgets_outlined, Icons.widgets_rounded, ''), // AI Hub Button (no screen index)
                if (!Provider.of<AuthProvider>(context).isRecruiter)
                  _buildNavItem(2, Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Saved')
                else
                  _buildNavItem(2, Icons.forum_outlined, Icons.forum_rounded, 'Inbox'),
                _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    setState(() => _isAIHubMenuOpen = false);
    
    // Smooth transition
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      }
    });
  }

  void _showAIHubMenu() {
    HapticFeedback.heavyImpact();
    setState(() => _isAIHubMenuOpen = !_isAIHubMenuOpen);
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final bool isAIHub = index == -1;
    final bool isSelected = isAIHub ? _isAIHubMenuOpen : _selectedIndex == index;
    final theme = Theme.of(context);
    final activeColor = isAIHub ? const Color(0xFF00B0FF) : theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isAIHub) {
            _showAIHubMenu();
          } else if (!isSelected) {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedIndex = index;
              _isAIHubMenuOpen = false; // Ensure menu closes
            });
          }
        },
        behavior: HitTestBehavior.opaque,
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
                          const Color(0xFF00B0FF).withValues(alpha: isSelected ? 0.35 : 0.12),
                          const Color(0xFF00E5FF).withValues(alpha: isSelected ? 0.2 : 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                          blurRadius: 15,
                        )
                      ] : null,
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
}

class _AIHubMenuOverlay extends StatelessWidget {
  final Function(Widget) onToolSelected;
  final VoidCallback onSwitchRole;

  const _AIHubMenuOverlay({required this.onToolSelected, required this.onSwitchRole});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 50,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 16,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  if (!auth.isRecruiter) ...[
                    _buildMenuAction(
                      context,
                      'CV Analyst',
                      Icons.description_rounded,
                      const Color(0xFF00B0FF),
                      () => onToolSelected(const CVUploadScreen()),
                    ),
                    _buildMenuAction(
                      context,
                      'Interview',
                      Icons.psychology_rounded,
                      const Color(0xFFFF9100),
                      () => onToolSelected(const MockInterviewScreen()),
                    ),
                    _buildMenuAction(
                      context,
                      'Salary ROI',
                      Icons.insights_rounded,
                      const Color(0xFF00E676),
                      () => onToolSelected(const SalaryROIScreen()),
                    ),
                    _buildMenuAction(
                      context,
                      'Expert AI',
                      Icons.forum_rounded,
                      const Color(0xFFD500F9),
                      () => onToolSelected(const ExpertAIChatScreen()),
                    ),
                  ] else ...[
                    _buildMenuAction(
                      context,
                      'Manage Jobs',
                      Icons.work_rounded,
                      const Color(0xFF4CAF50),
                      () {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage Jobs Coming Soon')));
                      },
                    ),
                    _buildMenuAction(
                      context,
                      'JD Generator',
                      Icons.auto_awesome_rounded,
                      const Color(0xFFD500F9),
                      () {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI JD Generator Coming Soon')));
                      },
                    ),
                    _buildMenuAction(
                      context,
                      'Smart Inbox',
                      Icons.forum_rounded,
                      const Color(0xFFFF9800),
                      () {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Smart Inbox Coming Soon')));
                      },
                    ),
                  ],
                  _buildMenuAction(
                    context,
                    'Switch Role',
                    auth.isRecruiter ? Icons.person_search_rounded : Icons.business_center_rounded,
                    const Color(0xFF607D8B),
                    () => onSwitchRole(),
                  ),
                ],
              ),
              const SizedBox(height: 35),
              Text(
                'AI HUB QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
