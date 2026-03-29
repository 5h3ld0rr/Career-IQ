import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import 'skills_gap_analysis_screen.dart';

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

  Future<void> _startAnalysis() async {
    setState(() {
      _isUploading = true;
      _isAnalyzed = false;
      _analysisProgress = 0.0;
    });

    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    // Simulate different steps of analysis
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

      // 1. REAL PDF TEXT EXTRACTION
      String resumeText = '';
      if (_fileBytes != null) {
        resumeText = await _extractTextFromPdf(_fileBytes!);
      }

      // 2. FALLBACK/ENHANCEMENT
      if (resumeText.trim().isEmpty) {
        resumeText = "User uploaded a file named $_fileName. Analyze this contexto if possible.";
      }
      
      // 3. AI ANALYSIS
      await aiProvider.extractSkills(resumeText);
      
      // 4. PREPARE GAP ANALYSIS FOR NEXT SCREEN (INDUSTRY STANDARDS)
      // This will ensure the Skills Gap screen isn't empty
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null) {
      setState(() {
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
      backgroundColor: const Color(0xFFF2F8FF),
      body: Stack(
        children: [
          // Background Gradient Circles for Glass Look
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
                  title: const Text('Elite Hire'),
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
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final ai = Provider.of<AIProvider>(context, listen: false);
                              
                              // 1. Save Resume to Storage & Firestore
                              if (_fileBytes != null && _fileName != null) {
                                await auth.uploadResume(_fileBytes!, _fileName!);
                              }
                              
                              // 2. Save Extracted Skills to Firestore
                              if (ai.extractedSkills.isNotEmpty) {
                                final List<String> skillNames = ai.extractedSkills
                                    .map((s) => s['skill'].toString())
                                    .toList();
                                await auth.updateSkills(skillNames);
                              }

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SkillsGapAnalysisScreen(),
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

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _pickFile,
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
              ), // In Flutter solid is easier than dashed for simple impl
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
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Skill Analysis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${(_analysisProgress * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
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
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Analysis complete, but no clear skills were identified.'),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Extracted Skills Match:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ...skills.map((skill) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSkillRow(skill),
            )),
          ],
        );
      },
    );
  }

  Widget _buildSkillRow(Map<String, dynamic> skill) {
    // Map AI skill names to some icons
    IconData icon = Icons.auto_awesome_rounded;
    final skillName = (skill['skill'] as String).toLowerCase();
    
    if (skillName.contains('flutter') || skillName.contains('dart')) {
      icon = Icons.code_rounded;
    } else if (skillName.contains('design') || skillName.contains('ui') || skillName.contains('ux')) {
      icon = Icons.palette_rounded;
    } else if (skillName.contains('management') || skillName.contains('business')) {
      icon = Icons.business_center_rounded;
    } else if (skillName.contains('marketing')) {
      icon = Icons.ads_click_rounded;
    } else if (skillName.contains('react') || skillName.contains('js') || skillName.contains('frontend')) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      skill['skill'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${skill['match'] ?? 0}% Match',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (skill['match'] ?? 0) / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (skill['match'] ?? 0) > 90
                          ? const Color(0xFF039BE5)
                          : const Color(0xFF81D4FA),
                    ),
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
