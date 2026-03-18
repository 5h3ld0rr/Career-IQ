import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'interview_feedback_screen.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  bool _isRecording = false;
  int _currentQuestionIndex = 0;
  bool _isAnalyzing = false;

  final List<String> _questions = [
    "Tell me about a challenging project you've worked on recently.",
    "How do you handle disagreements within a technical team?",
    "What is your approach to learning new technologies?",
    "Where do you see yourself in the next 3 to 5 years?",
  ];

  void _finishInterview() async {
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(seconds: 3));
    setState(() => _isAnalyzing = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewFeedbackScreen(
            score: 82.0,
            insights: [
              {
                'icon': Icons.check_circle_outline_rounded,
                'title': 'Great Confidence',
                'subtitle': 'You maintained steady eye contact.',
                'color': Colors.blue,
              },
              {
                'icon': Icons.lightbulb_outline_rounded,
                'title': 'Technical Depth',
                'subtitle': 'Try to include more specific metrics.',
                'color': Colors.cyan,
              },
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          _isAnalyzing ? _buildAnalyzingState() : _buildInterviewBody(),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: -100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF81D4FA).withValues(alpha: 0.35),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBox({
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 24,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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

  Widget _buildInterviewBody() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassBox(
                  borderRadius: 50,
                  padding: const EdgeInsets.all(4),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  'Mock Interview AI',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                _buildRecordingIndicator(),
              ],
            ),
          ),
          Expanded(child: _buildVideoPreview()),
          _buildInterviewConsole(),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: _buildGlassBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(height: 24),
            const Text(
              'AI Analysis in Progress...',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Evaluating confidence and clarity.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.person_rounded, size: 100, color: Colors.white12),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _buildGlassBox(
              child: Column(
                children: [
                  const Text(
                    'QUESTION',
                    style: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _questions[_currentQuestionIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.4,
                      color: Colors.black,
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

  Widget _buildRecordingIndicator() {
    return _buildGlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: _isRecording ? Colors.red : Colors.black26,
            size: 8,
          ),
          const SizedBox(width: 8),
          Text(
            _isRecording ? 'LIVE' : 'READY',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewConsole() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: _buildGlassBox(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildConsoleAction(Icons.skip_next_rounded, 'Skip', () {
                  setState(
                    () => _currentQuestionIndex =
                        (_currentQuestionIndex + 1) % _questions.length,
                  );
                }),
                _buildRecordButton(),
                _buildConsoleAction(
                  Icons.check_circle_outline_rounded,
                  'Finish',
                  _finishInterview,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INTERVIEW PROGRESS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Colors.black45,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF03A9F4),
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _buildGlassBox(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Icon(icon, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: () => setState(() => _isRecording = !_isRecording),
      child: _buildGlassBox(
        padding: const EdgeInsets.all(20),
        borderRadius: 50,
        child: Icon(
          _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: _isRecording ? Colors.red : Colors.blueAccent,
          size: 36,
        ),
      ),
    );
  }
}
