import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../core/theme.dart';

class JobFilterModal extends StatefulWidget {
  const JobFilterModal({super.key});

  @override
  State<JobFilterModal> createState() => _JobFilterModalState();
}

class _JobFilterModalState extends State<JobFilterModal> {
  String _jobType = 'All';
  String _workMode = 'All';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<JobProvider>(context, listen: false);
    _jobType = provider.selectedJobType;
    _workMode = provider.selectedWorkMode;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(36),
        topRight: Radius.circular(36),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(36),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Jobs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  TextButton(
                    onPressed: () => setState(() { _jobType = 'All'; _workMode = 'All'; }),
                    child: const Text('Reset', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFilterSection('Job Type', ['All', 'Full-time', 'Part-time', 'Contract'], _jobType, (val) => setState(() => _jobType = val!)),
              const SizedBox(height: 24),
              _buildFilterSection('Work Mode', ['All', 'Remote', 'On-site'], _workMode, (val) => setState(() => _workMode = val!)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final provider = Provider.of<JobProvider>(context, listen: false);
                  provider.loadJobs(jobType: _jobType, workMode: _workMode);
                  Navigator.pop(context);
                },
                child: const Text('APPLY FILTERS', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String current, Function(String?) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((opt) {
            final isSelected = current == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (selected) => onSelected(selected ? opt : 'All'),
              selectedColor: const Color(0xFF03A9F4).withOpacity(0.3),
              backgroundColor: Colors.white.withOpacity(0.5),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0288D1) : Colors.black54,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isSelected ? const BorderSide(color: Color(0xFF03A9F4), width: 1) : BorderSide.none),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}
