import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';

class ApplyJobScreen extends StatefulWidget {
  final Job job;
  const ApplyJobScreen({super.key, required this.job});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  File? _selectedResume;
  String? _resumeName;
  final TextEditingController _coverLetterController = TextEditingController();

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedResume = File(result.files.single.path!);
          _resumeName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _submitApplication() async {
    if (_selectedResume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your resume to continue')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to apply')));
      return;
    }

    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.submitApplication(
        userId: auth.userId!,
        jobId: widget.job.id,
        resumeFile:
            _selectedResume!, // File upload is handled in Provider/Service
        coverLetter: _coverLetterController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully! 🎉')),
      );
      Navigator.pop(context); // Go back to job details
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildGlassBox(
            borderRadius: 50,
            padding: EdgeInsets.zero,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Submit Application',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobSummaryCard(),
                const SizedBox(height: 32),
                const Text(
                  'Upload Resume *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _buildUploadArea(),
                const SizedBox(height: 32),
                const Text(
                  'Cover Letter (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _buildCoverLetterField(),
                const SizedBox(height: 48),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSubmitAction(),
          ),
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
              const Color(0xFF81D4FA).withValues(alpha: 0.3),
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
    double? borderOpacity,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: borderOpacity ?? 0.8),
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

  Widget _buildJobSummaryCard() {
    return _buildGlassBox(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.network(
              widget.job.logoUrl,
              errorBuilder: (_, __, ___) => const Icon(Icons.business),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.job.companyName,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickResume,
      child: _buildGlassBox(
        borderRadius: 20,
        borderOpacity: _selectedResume != null ? 1.0 : 0.4,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Icon(
                _selectedResume != null
                    ? Icons.description_rounded
                    : Icons.upload_file_rounded,
                size: 48,
                color: _selectedResume != null
                    ? const Color(0xFF03A9F4)
                    : Colors.black38,
              ),
              const SizedBox(height: 16),
              Text(
                _selectedResume != null
                    ? _resumeName!
                    : 'Tap to upload or pick a file',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _selectedResume != null
                      ? Colors.black87
                      : Colors.black54,
                ),
              ),
              if (_selectedResume == null) ...[
                const SizedBox(height: 8),
                const Text(
                  'PDF, DOC, or DOCX (Max 5MB)',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _pickResume,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Change File'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF03A9F4),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverLetterField() {
    return _buildGlassBox(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _coverLetterController,
        maxLines: 6,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          hintText: 'Write why you are a good fit for this role...',
          hintStyle: TextStyle(
            color: Colors.black38,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBottomSubmitAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Consumer<JobProvider>(
              builder: (context, jobs, _) {
                final isSubmitting = jobs.isLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'SUBMIT APPLICATION',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
