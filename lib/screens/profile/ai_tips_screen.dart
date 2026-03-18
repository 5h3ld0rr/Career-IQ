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
        title: const Text('AI Resume Analysis'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, aiProvider),
            const SizedBox(height: 32),
            if (aiProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (aiProvider.analysisResult != null) ...[
                Text(
                  'Analysis Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    aiProvider.analysisResult!,
                    style: const TextStyle(height: 1.6, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              Text(
                'Smart Tips for You',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...aiProvider.currentTips.map((tip) => _buildTipCard(tip)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton.icon(
          onPressed: aiProvider.isLoading
              ? null
              : () => aiProvider.analyzeResume(
                  "I am a Senior Product Designer expert in Figma and UX Research.",
                ),
          icon: const Icon(Icons.psychology_rounded),
          label: const Text('Analyze My Resume Now'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AIProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppTheme.primaryBlue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elite Resume Optimizer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Get AI-powered feedback to land your dream job.'),
              ],
            ),
          ),
        ],
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
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
