import 'dart:typed_data';
import 'dart:developer' as dev;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:careeriq/features/ai_assistant/providers/ai_provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/cv_analysis/screens/skills_gap_analysis_screen.dart';

class CVUploadScreen extends StatefulWidget {
  const CVUploadScreen({super.key});

  @override
  State<CVUploadScreen> createState() => _CVUploadScreenState();
}

class _CVUploadScreenState extends State<CVUploadScreen> {
  bool _isUploading = false;
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isAnalyzed = false;
  String _analysisStep = '';
  double _analysisProgress = 0.0;
  bool _useProfileResume = false;

  Future<void> _startAnalysis() async {
    setState(() {
      _isUploading = true;
      _isAnalyzed = false;
      _analysisProgress = 0.0;
    });

    final aiProvider = Provider.of<AIProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final steps = [
      'Extracting text...',
      'Identifying experience...',
      'Cross-referencing...',
      'Generating AI insights...',
    ];

    try {
      for (int i = 0; i < steps.length; i++) {
        setState(() {
          _analysisStep = steps[i];
          _analysisProgress = (i + 0.5) / steps.length;
        });
        await Future.delayed(const Duration(milliseconds: 600));
      }

      String resumeText = '';

      if (_useProfileResume && auth.resumeUrl != null && _fileBytes == null) {
        setState(() {
          _analysisStep = 'Downloading profile resume...';
          _analysisProgress = 0.1;
        });
        final response = await http.get(Uri.parse(auth.resumeUrl!));
        if (response.statusCode == 200) {
          _fileBytes = response.bodyBytes;
          _fileName = auth.resumeFileName;
        }
      }

      if (_fileBytes != null) {
        resumeText = await _extractTextFromPdf(_fileBytes!);
      }

      if (resumeText.trim().isEmpty) {
        resumeText =
            "User uploaded a file named $_fileName. Analyze this contexto if possible.";
      }

      await aiProvider.extractSkills(resumeText);

      await aiProvider.analyzeGeneralMarketGap(resumeText);

      setState(() {
        _analysisStep = 'Analysis complete!';
        _analysisProgress = 1.0;
        _isUploading = false;
        _isAnalyzed = true;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _analysisStep = 'Analysis failed.';
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _useProfileResume = false;
        _fileName = result.files.single.name;
        _fileBytes = result.files.single.bytes;
      });
      _startAnalysis();
    }
  }

  Future<String> _extractTextFromPdf(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF81D4FA).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  title: const Text('Career IQ'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Center(
                        child: Text(
                          'Upload Your CV',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) =>
                            _buildProfileResumeToggle(auth),
                      ),
                      _buildGlassContainer(child: _buildUploadZone()),
                      if (_fileName != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _fileName!,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (_isUploading) _buildLoadingSection(),
                      if (_isAnalyzed) ...[
                        _buildGlassContainer(child: _buildSkillsMatchSection()),
                        const SizedBox(height: 32),
                        _buildGlassButton(
                          _isUploading ? 'Saving...' : 'Continue with Profile',
                          () async {
                            if (_isUploading) return;

                            setState(() => _isUploading = true);

                            try {
                              final auth = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final ai = Provider.of<AIProvider>(
                                context,
                                listen: false,
                              );

                              if (_fileBytes != null && _fileName != null) {
                                await auth.uploadResume(
                                  _fileBytes!,
                                  _fileName!,
                                );
                              }

                              if (ai.extractedSkills.isNotEmpty) {
                                final List<String> skillNames = ai
                                    .extractedSkills
                                    .map((s) => s['skill'].toString())
                                    .toList();
                                await auth.updateSkills(skillNames);
                              }

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SkillsGapAnalysisScreen(),
                                  ),
                                );
                              }
                            } catch (e) {
                              dev.log("Error saving profile: $e");
                            } finally {
                              if (mounted) setState(() => _isUploading = false);
                            }
                          },
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileResumeToggle(AuthProvider auth) {
    if (auth.resumeUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_pin_rounded,
              color: Color(0xFF00BFA5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use Profile Resume',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  auth.resumeFileName ?? 'Resume.pdf',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _useProfileResume,
              activeThumbColor: AppTheme.primaryBlue,
              onChanged: (val) {
                if (_isUploading) return;
                setState(() {
                  _useProfileResume = val;
                  if (val) {
                    _fileName = auth.resumeFileName;
                    _isAnalyzed = false;
                  } else {
                    _fileName = null;
                    _fileBytes = null;
                    _isAnalyzed = false;
                    _analysisProgress = 0.0;
                    _analysisStep = '';
                  }
                });
                if (val) {
                  _startAnalysis();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _useProfileResume ? null : _pickFile,
      child: Opacity(
        opacity: _useProfileResume ? 0.5 : 1.0,
        child: Column(
          children: [
            const Text(
              'Upload CV',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.black12,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.black54,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload CV (PDF, DOCX)',
                    style: TextStyle(
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
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Analysis Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _analysisProgress,
            minHeight: 12,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _analysisStep,
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSkillsMatchSection() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        final skills = aiProvider.extractedSkills;

        if (skills.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Analysis complete, but no clear skills were identified.',
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Extracted Skills Match:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ...skills.map(
              (skill) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSkillRow(skill),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillRow(Map<String, dynamic> skill) {
    IconData icon = Icons.auto_awesome_rounded;
    final skillName = (skill['skill'] as String).toLowerCase();

    if (skillName.contains('flutter') || skillName.contains('dart')) {
      icon = Icons.code_rounded;
    } else if (skillName.contains('design') ||
        skillName.contains('ui') ||
        skillName.contains('ux')) {
      icon = Icons.palette_rounded;
    } else if (skillName.contains('management') ||
        skillName.contains('business')) {
      icon = Icons.business_center_rounded;
    } else if (skillName.contains('marketing')) {
      icon = Icons.ads_click_rounded;
    } else if (skillName.contains('react') ||
        skillName.contains('js') ||
        skillName.contains('frontend')) {
      icon = Icons.web_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill['skill'],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
