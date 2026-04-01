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

    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      final qs = await _aiService.generateMockInterviewQuestions(
        role: _roleController.text,
        experienceLevel: _selectedLevel,
      );
      setState(() {
        _questions = qs;
        _isSettingUp = false;
        _isLoadingQuestions = false;
      });
    } catch (e) {
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
      setState(() => _isAnalyzing = false);
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
                Text(
                  _roleController.text.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
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
              'Evaluating your performance and insights.',
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
                    _questions.isNotEmpty
                        ? _questions[_currentQuestionIndex]
                        : "Loading questions...",
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
            if (_isRecording) ...[
              TextField(
                controller: _answerController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Type your answer here or practice speaking...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildConsoleAction(Icons.skip_next_rounded, 'Skip', () {
                  if (_currentQuestionIndex < _questions.length - 1) {
                    setState(() => _currentQuestionIndex++);
                  }
                }),
                _buildRecordButton(),
                _buildConsoleAction(
                  _currentQuestionIndex == _questions.length - 1
                      ? Icons.check_circle_outline_rounded
                      : Icons.arrow_forward_rounded,
                  _currentQuestionIndex == _questions.length - 1
                      ? 'Finish'
                      : 'Next',
                  _nextQuestion,
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
              value: _questions.isNotEmpty
                  ? (_currentQuestionIndex + 1) / _questions.length
                  : 0,
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
