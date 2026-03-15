import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import 'package:elitehire/core/theme.dart';
import 'package:flutter/services.dart';

class AICoverLetterScreen extends StatefulWidget {
  final String jobTitle;
  final String jobDescription;
  
  const AICoverLetterScreen({
    super.key, 
    required this.jobTitle, 
    required this.jobDescription
  });

  @override
  State<AICoverLetterScreen> createState() => _AICoverLetterScreenState();
}

class _AICoverLetterScreenState extends State<AICoverLetterScreen> {
  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    Future.microtask(() {
      Provider.of<AIProvider>(context, listen: false).generateCoverLetter(
        resumeContent: "I am a Senior Product Designer expert in Figma and UX Research.", // Placeholder resume
        jobDescription: widget.jobDescription,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Cover Letter'),
        centerTitle: true,
      ),
      body: aiProvider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('Crafting your perfect cover letter...', 
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
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
                        const Icon(Icons.description_rounded, color: AppTheme.primaryBlue, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Elite AI Write',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryBlue)),
                              const SizedBox(height: 4),
                              Text('Generated for ${widget.jobTitle}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (aiProvider.coverLetter != null) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.lightGray),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        aiProvider.coverLetter!,
                        style: const TextStyle(height: 1.6, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: aiProvider.coverLetter!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy Text'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generate,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Regenerate'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Center(child: Text('Something went wrong. Please try again.')),
                  ],
                ],
              ),
            ),
    );
  }
}
