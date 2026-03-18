import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class InterviewFeedbackScreen extends StatelessWidget {
  final double score;
  final List<Map<String, dynamic>> insights;

  const InterviewFeedbackScreen({
    super.key,
    required this.score,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildGlassBox(
                    borderRadius: 50,
                    padding: const EdgeInsets.all(4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                title: const Text('Interview Performance'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGlassBox(
                      child: _buildScoreHeader(),
                    ),
                    const SizedBox(height: 32),
                    _buildMetricsGrid(context),
                    const SizedBox(height: 32),
                    const Text(
                      'Detailed Feedback',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    ...insights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGlassBox(child: _buildInsightCard(context, insight)),
                    )).toList(),
                    const SizedBox(height: 32),
                    _buildActionButtons(context),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      bottom: -50,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [const Color(0xFF81D4FA).withOpacity(0.3), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child, EdgeInsets? padding, double borderRadius = 24}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
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

  Widget _buildScoreHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF03A9F4)),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '${score.toInt()}%',
              style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Confidence Score', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        const Text(
          'Your tone was professional and steady.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricItem('Clarity', 85, Colors.blueAccent),
        _buildMetricItem('Pace', 60, Colors.cyan),
        _buildMetricItem('Keywords', 92, Colors.lightBlue),
      ],
    );
  }

  Widget _buildMetricItem(String label, int value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _buildGlassBox(
          padding: const EdgeInsets.symmetric(vertical: 20),
          borderRadius: 20,
          child: Column(
            children: [
              Text('$value%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 4),
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, Map<String, dynamic> insight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(insight['icon'] ?? Icons.lightbulb_outline_rounded, color: const Color(0xFF03A9F4), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                insight['subtitle'],
                style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Practice Again', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Back to Dashboard', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
