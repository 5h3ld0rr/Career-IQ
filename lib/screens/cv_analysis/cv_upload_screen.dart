import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme.dart';

class CVUploadScreen extends StatefulWidget {
  const CVUploadScreen({super.key});

  @override
  State<CVUploadScreen> createState() => _CVUploadScreenState();
}

class _CVUploadScreenState extends State<CVUploadScreen> {
  bool _isUploading = false;
  String? _fileName;
  bool _isAnalyzed = false;
  String _analysisStep = '';
  double _analysisProgress = 0.0;

  final List<Map<String, dynamic>> _mockSkills = [
    {'skill': 'Flutter Development', 'match': 95, 'category': 'Technical'},
    {'skill': 'UI/UX Architecture', 'match': 90, 'category': 'Design'},
    {'skill': 'State Management', 'match': 85, 'category': 'Technical'},
    {'skill': 'Team Leadership', 'match': 80, 'category': 'Soft Skill'},
    {'skill': 'Firebase Auth', 'match': 75, 'category': 'Cloud'},
  ];

  Future<void> _startAnalysis() async {
    setState(() {
      _isUploading = true;
      _isAnalyzed = false;
    });

    final steps = [
      'Extracting text from PDF...',
      'Identifying professional experience...',
      'Extracting technical skill set...',
      'Cross-referencing with industry standards...',
      'Generating AI insights...',
    ];

    for (int i = 0; i < steps.length; i++) {
      setState(() {
        _analysisStep = steps[i];
        _analysisProgress = (i + 1) / steps.length;
      });
      await Future.delayed(const Duration(milliseconds: 800));
    }

    setState(() {
      _isUploading = false;
      _isAnalyzed = true;
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
      _startAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'AI CV Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isAnalyzed && !_isUploading) _buildInitialPrompt(),
            if (_isUploading) _buildLoadingState(),
            if (_isAnalyzed) _buildAnalysisView(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optimize Your Professional Profile',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.displaySmall?.color,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Upload your resume to get deep AI-driven insights into your skills and how they match current market demands.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        _buildUploadArea(),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_rounded,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _fileName ?? 'Upload Resume',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supports PDF, DOCX (Max 5MB)',
              style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _analysisProgress,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  color: Theme.of(context).primaryColor,
                  strokeCap: StrokeCap.round,
                ),
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _analysisStep,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This usually takes about 10-15 seconds',
            style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverallMatchHeader(),
        const SizedBox(height: 32),
        Text(
          'Top Extracted Skills',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildSkillGrid(),
        const SizedBox(height: 32),
        _buildAITipsCard(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildOverallMatchHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expertise Score',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Elite Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Top 5% in your field',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '92',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _mockSkills.length,
      itemBuilder: (context, index) {
        final skill = _mockSkills[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill['category'].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.mediumGray,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                skill['skill'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: skill['match'] / 100,
                        backgroundColor: AppTheme.lightGray,
                        color: AppTheme.primaryBlue,
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${skill['match']}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAITipsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: Colors.amber[700]),
              const SizedBox(width: 12),
              Text(
                'AI Optimization Tip',
                style: TextStyle(
                  color: Colors.amber[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your "State Management" score could be improved by mentioning specialized libraries like Bloc or Riverpod in your project descriptions.',
            style: TextStyle(
              color: Colors.amber[900]?.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

