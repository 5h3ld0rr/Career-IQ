import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home/home_screen.dart';
import 'saved/saved_jobs_screen.dart';
import 'profile/profile_screen.dart';
import 'tracker/application_tracker_screen.dart';
import 'career_tools/career_tools_screen.dart';
import 'cv_analysis/cv_upload_screen.dart';
import 'interview/mock_interview_screen.dart';
import 'salary_roi/salary_roi_screen.dart';
import '../core/theme.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ApplicationTrackerScreen(),
    const CareerToolsScreen(),
    const SavedJobsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
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
                _buildNavItem(1, Icons.assignment_outlined, Icons.assignment_rounded, 'Tracker'),
                _buildNavItem(2, Icons.widgets_outlined, Icons.widgets_rounded, ''),
                _buildNavItem(3, Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Saved'),
                _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAIHubMenu() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => _AIHubMenuOverlay(
        onToolSelected: (index) {
          Navigator.pop(context);
          setState(() => _selectedIndex = 2); // Switch to AI Hub tab
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    bool isSelected = _selectedIndex == index;
    bool isAIHub = index == 2;
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
            setState(() => _selectedIndex = index);
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
  final Function(int) onToolSelected;

  const _AIHubMenuOverlay({required this.onToolSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuAction(
                    context,
                    'CV Analyst',
                    Icons.description_rounded,
                    const Color(0xFF00B0FF),
                    () => _navigateTo(context, const CVUploadScreen()),
                  ),
                  _buildMenuAction(
                    context,
                    'Interview',
                    Icons.psychology_rounded,
                    const Color(0xFFFF9100),
                    () => _navigateTo(context, const MockInterviewScreen()),
                  ),
                  _buildMenuAction(
                    context,
                    'Salary ROI',
                    Icons.insights_rounded,
                    const Color(0xFF00E676),
                    () => _navigateTo(context, const SalaryROIScreen()),
                  ),
                  _buildMenuAction(
                    context,
                    'Expert AI',
                    Icons.forum_rounded,
                    const Color(0xFFD500F9),
                    () {},
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

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    onToolSelected(2);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
