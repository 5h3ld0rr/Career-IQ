import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../core/theme.dart';
import '../../models/job.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _jobType = 'Full-time';
  String _workMode = 'On-site';
  String _category = 'Software Engineering';

  final List<String> _categories = [
    'Software Engineering',
    'Data Science',
    'Design',
    'Marketing',
    'Finance',
    'Sales',
    'Other'
  ];

  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Contract', 'Internship'];
  final List<String> _workModes = ['On-site', 'Remote', 'Hybrid'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      appBar: AppBar(
        title: const Text('Post a New Job', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('Job Title'),
              _buildTextField(
                controller: _titleController,
                hint: 'Full Stack Developer',
                validator: (v) => v!.isEmpty ? 'required' : null,
              ),
              
              const SizedBox(height: 20),
              _buildInputLabel('Company Name'),
              _buildTextField(
                controller: _companyController,
                hint: 'e.g. Google Mobile Service',
                validator: (v) => v!.isEmpty ? 'required' : null,
              ),

              const SizedBox(height: 20),
              _buildInputLabel('Company Telephone Number'),
              _buildTextField(
                controller: _phoneController,
                hint: 'e.g. +94 77 123 4567',
                validator: (v) => v!.isEmpty ? 'required' : null,
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Location'),
                        _buildTextField(controller: _locationController, hint: 'Colombo, Sri Lanka'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Salary (Monthly)'),
                        _buildTextField(controller: _salaryController, hint: 'Rs 150,000 / month'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildInputLabel('Category'),
              _buildDropdown(_category, _categories, (v) => setState(() => _category = v!)),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Type'),
                        _buildDropdown(_jobType, _jobTypes, (v) => setState(() => _jobType = v!)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Mode'),
                        _buildDropdown(_workMode, _workModes, (v) => setState(() => _workMode = v!)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildInputLabel('Job Description'),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Describe why this job is great...',
                maxLines: 5,
              ),

              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final jobProvider = Provider.of<JobProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        onPressed: jobProvider.isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  final newJob = Job(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text,
                    companyName: _companyController.text,
                    logoUrl: 'https://via.placeholder.com/150',
                    location: _locationController.text,
                    salary: _salaryController.text,
                    description: _descriptionController.text,
                    responsibilities: [_descriptionController.text], // Simplified for now
                    requirements: ['Requirement 1'], // Default placeholder
                    jobType: _jobType,
                    postedAt: DateTime.now(),
                    applyUrl: '', // Default placeholder
                    postedBy: auth.userId,
                    companyPhone: _phoneController.text,
                  );

                  try {
                    await jobProvider.addJob(newJob);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Job posted successfully!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to post job: $e')),
                      );
                    }
                  }
                }
              },
        child: jobProvider.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Post Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
