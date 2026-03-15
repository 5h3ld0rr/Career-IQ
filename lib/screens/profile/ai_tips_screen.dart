import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import 'package:elitehire/core/theme.dart';

class AIResumeTipsScreen extends StatefulWidget {
  const AIResumeTipsScreen({super.key});

  @override
  State<AIResumeTipsScreen> createState() => _AIResumeTipsScreenState();
}

class _AIResumeTipsScreenState extends State<AIResumeTipsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AIProvider>(context, listen: false).fetchTips('Design');
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Tips'),
        centerTitle: true,
      ),
      body: aiProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Analysis',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryBlue)),
                              const SizedBox(height: 4),
                              const Text('Personalized tips to make your resume stand out.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Top Tips for You', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ...aiProvider.currentTips.map((tip) => _buildTipCard(tip)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      aiProvider.analyzeResume("I am a Senior Product Designer expert in Figma and UX Research.");
                    },
                    child: const Text('Re-Analyze My Resume'),
                  ),
                  if (aiProvider.analysisResult != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                      ),
                      child: Text(
                        aiProvider.analysisResult!,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }
}
