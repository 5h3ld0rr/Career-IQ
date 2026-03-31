import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import 'package:careeriq/core/theme.dart';
import 'package:flutter/services.dart';
import '../../widgets/app_snackbar.dart';

class AICoverLetterScreen extends StatefulWidget {
  final String jobTitle;
  final String jobDescription;

  const AICoverLetterScreen({
    super.key,
    required this.jobTitle,
    required this.jobDescription,
  });

  @override
  State<AICoverLetterScreen> createState() => _AICoverLetterScreenState();
}

class _AICoverLetterScreenState extends State<AICoverLetterScreen> {
  final TextEditingController _skillsController = TextEditingController(
    text: "Experienced professional with a strong track record of success.",
  );

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _skillsController.dispose();
    super.dispose();
  }

  void _generate() {
    if (_skillsController.text.trim().isEmpty) return;

    Future.microtask(() {
      Provider.of<AIProvider>(context, listen: false).generateCoverLetter(
        resumeContent: _skillsController.text.trim(),
        jobDescription: widget.jobDescription,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);

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
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                title: const Text('AI Cover Letter'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: aiProvider.isLoading
                    ? SliverFillRemaining(child: _buildLoadingState())
                    : SliverList(
                        delegate: SliverChildListDelegate([
                          _buildGlassBox(child: _buildHeader()),
                          const SizedBox(height: 16),
                          _buildGlassBox(child: _buildSkillsInput()),
                          const SizedBox(height: 32),
                          if (aiProvider.coverLetter != null) ...[
                            _buildGlassBox(
                              padding: const EdgeInsets.all(32),
                              child: SelectableText(
                                aiProvider.coverLetter!,
                                style: const TextStyle(
                                  height: 1.7,
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildActionRow(context, aiProvider),
                            const SizedBox(height: 48),
                          ],
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
      top: 150,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 24),
          const Text(
            'AI is crafting your letter...',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF03A9F4),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Professional Cover Letter',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(
                'Optimized for ${widget.jobTitle}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Key Skills & Experience',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _skillsController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'E.g., 5 years of experience in Flutter and Node.js...',
            hintStyle: const TextStyle(color: Colors.black38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF03A9F4)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, AIProvider aiProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassBox(
            padding: EdgeInsets.zero,
            borderRadius: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                AppSnackBar.show('Copied to clipboard! 📋');
              },
              icon: const Icon(
                Icons.copy_all_rounded,
                size: 20,
                color: Color(0xFF03A9F4),
              ),
              label: const Text(
                'COPY TEXT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildGlassBox(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          child: IconButton(
            onPressed: _generate,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF03A9F4)),
            padding: const EdgeInsets.all(18),
          ),
        ),
      ],
    );
  }
}
