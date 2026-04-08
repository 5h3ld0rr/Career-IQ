import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/ai_assistant/data/ai_service.dart';
import 'package:careeriq/features/interview/screens/interview_feedback_screen.dart';

class MockInterviewScreen extends StatefulWidget {
  final String? initialRole;
  final String? initialLevel;
  const MockInterviewScreen({super.key, this.initialRole, this.initialLevel});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  final _aiService = AIService();
  final _roleController = TextEditingController();
  final _answerController = TextEditingController();

  bool _isRecording = false;
  int _currentQuestionIndex = 0;
  bool _isAnalyzing = false;
  bool _isSettingUp = true;
  bool _isLoadingQuestions = false;
  String _selectedLevel = 'Junior';

  List<String> _questions = [];
  final List<Map<String, String>> _responses = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      _roleController.text = widget.initialRole!;
    }
    if (widget.initialLevel != null) {
      _selectedLevel = widget.initialLevel!;
    }
  }

  void _generateQuestions() async {
    if (_roleController.text.isEmpty) return;

    setState(() => _isLoadingQuestions = true);

    try {
      final qs = await _aiService.generateMockInterviewQuestions(
        role: _roleController.text,
        experienceLevel: _selectedLevel,
      );

      if (!mounted) return;

      if (qs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate questions. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingQuestions = false);
        return;
      }

      setState(() {
        _questions = qs;
        _isSettingUp = false;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoadingQuestions = false);
    }
  }

  void _nextQuestion() {
    _responses.add({
      'question': _questions[_currentQuestionIndex],
      'answer': _answerController.text.isNotEmpty
          ? _answerController.text
          : "The candidate practiced speaking this answer.",
    });

    _answerController.clear();

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishInterview();
    }
  }

  void _finishInterview() async {
    setState(() => _isAnalyzing = true);

    try {
      final analysis = await _aiService.analyzeInterviewSession(
        conversation: _responses,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InterviewFeedbackScreen(
              score: (analysis['score'] as num?)?.toDouble() ?? 0.0,
              insights: List<Map<String, dynamic>>.from(
                analysis['insights'] ?? [],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          if (_isSettingUp)
            _buildSetupView()
          else if (_isAnalyzing)
            _buildAnalyzingState()
          else
            _buildInterviewBody(),
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlassBox(
              borderRadius: 50,
              padding: const EdgeInsets.all(4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Interview Setup',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Tell AI what role you are preparing for.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            _buildGlassBox(
              child: Column(
                children: [
                  TextField(
                    controller: _roleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Flutter Developer, Product Manager',
                      labelText: 'Target Role',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Experience Level',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Junior', 'Mid-Level', 'Senior'].map((level) {
                      final isSelected = _selectedLevel == level;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedLevel = level),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : Colors.black12,
                            ),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoadingQuestions ? null : _generateQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoadingQuestions
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'START AI INTERVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
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
    return Column(
      children: [
        _buildInterviewHeader(),
        Expanded(child: _buildStage()),
        _buildQuestionCard(),
        _buildControls(),
        _buildProgressSection(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildInterviewHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(Icons.close_rounded, size: 18),
              ),
            ),
            const Spacer(),
            Column(
              children: [
                Text(
                  _roleController.text.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'AI INTERVIEW',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isRecording
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isRecording ? 'LIVE' : 'READY',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: _isRecording ? Colors.red : Colors.green,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STAGE (avatar area) ──────────────────────────────────────────────────────
  Widget _buildStage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2A3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03A9F4).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background grid pattern
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Glow orb
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF03A9F4).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Outer ring
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isRecording
                    ? Colors.red.withValues(alpha: 0.5)
                    : const Color(0xFF03A9F4).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          // Inner ring
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF03A9F4).withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFF03A9F4).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 48,
              color: Color(0xFF03A9F4),
            ),
          ),
          // Question number badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'Q${_currentQuestionIndex + 1} / ${_questions.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── QUESTION CARD ────────────────────────────────────────────────────────────
  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03A9F4).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF03A9F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'QUESTION',
                  style: TextStyle(
                    color: Color(0xFF03A9F4),
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _questions.isNotEmpty
                ? _questions[_currentQuestionIndex]
                : "Generating your interview questions...",
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF0D1B2A),
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type key points here (optional)...',
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── CONTROLS ─────────────────────────────────────────────────────────────────
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip
          _buildSideAction(
            icon: Icons.skip_next_rounded,
            label: 'Skip',
            onTap: () {
              if (_currentQuestionIndex < _questions.length - 1) {
                setState(() => _currentQuestionIndex++);
              }
            },
          ),
          // Mic button (center, large)
          GestureDetector(
            onTap: () => setState(() => _isRecording = !_isRecording),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [
                          const Color(0xFF03A9F4),
                          const Color(0xFF0288D1),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : const Color(0xFF03A9F4))
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // Next / Finish
          _buildSideAction(
            icon: _currentQuestionIndex == _questions.length - 1
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            label: _currentQuestionIndex == _questions.length - 1
                ? 'Finish'
                : 'Next',
            onTap: _nextQuestion,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSideAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isPrimary
                  ? const Color(0xFF03A9F4).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPrimary
                    ? const Color(0xFF03A9F4).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isPrimary ? const Color(0xFF03A9F4) : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: isPrimary ? const Color(0xFF03A9F4) : Colors.black45,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── PROGRESS ─────────────────────────────────────────────────────────────────
  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROGRESS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  color: Colors.black38,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${_currentQuestionIndex + 1} of ${_questions.length} questions',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_questions.length, (i) {
              final done = i < _currentQuestionIndex;
              final current = i == _currentQuestionIndex;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: done
                        ? const Color(0xFF03A9F4)
                        : current
                            ? const Color(0xFF03A9F4).withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF03A9F4), Color(0xFF0288D1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF03A9F4).withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Analyzing Your\nInterview...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI is evaluating your answers\nand generating personalized feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── BACKGROUND GRID PAINTER ────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



