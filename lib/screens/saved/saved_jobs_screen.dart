import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:elitehire/providers/job_provider.dart';
import 'package:elitehire/core/theme.dart';
import '../home/home_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Jobs'), centerTitle: true),
      body: jobProvider.savedJobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 80, color: AppTheme.mediumGray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No saved jobs yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.mediumGray)),
                  TextButton(
                    onPressed: () {}, // Navigate back to home or search
                    child: const Text('Browse Jobs'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: jobProvider.savedJobs.length,
              itemBuilder: (context, index) {
                final job = jobProvider.savedJobs[index];
                return JobListItem(job: job);
              },
            ),
    );
  }
}
