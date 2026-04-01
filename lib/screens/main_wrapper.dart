import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'home/home_screen.dart';
import 'saved/saved_jobs_screen.dart';
import 'profile/profile_screen.dart';
import 'tracker/application_tracker_screen.dart';
import 'interview/mock_interview_screen.dart';
import 'salary_roi/salary_roi_screen.dart';
import 'chat/expert_ai_chat_screen.dart';
import 'recruiter/recruiter_dashboard_screen.dart';
import 'recruiter/ats_dashboard_screen.dart';
import 'recruiter/manage_jobs_screen.dart';
import 'recruiter/recruiter_tools_screen.dart';
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
        const ManageJobsScreen(),
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

          // Menu Overlay Background (Dim & Blur)
          IgnorePointer(
            ignoring: !_isAIHubMenuOpen,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _isAIHubMenuOpen ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: () => setState(() => _isAIHubMenuOpen = false),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),

          // Arc Hub Actions
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
                  _buildNavItem(2, Icons.work_outline_rounded, Icons.work_rounded, 'Jobs'),
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
    
    // Spread them out
    double posX = centerX;
    double posY = 45; // Start at nav bar height
    
    if (_isAIHubMenuOpen) {
      posY = 145 + (index == 1 ? 35 : 0); // Arc height peaks at center
      if (index == 0) posX = centerX - 90;
      else if (index == 1) posX = centerX;
      else posX = centerX + 90;
    }

    return AnimatedPositioned(
      duration: Duration(milliseconds: 550 + (index * 80)),
      curve: Curves.easeOutBack,
      bottom: posY,
      left: posX - 32, // centering the 64 width icon
      child: AnimatedScale(
        duration: Duration(milliseconds: 450 + (index * 100)),
        curve: Curves.easeOutCubic,
        scale: _isAIHubMenuOpen ? 1.0 : 0.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
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
                        color: color.withValues(alpha: 0.3),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
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
