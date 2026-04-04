import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/jobs/data/job_model.dart';

class EditJobScreen extends StatefulWidget {
  final Job job;
  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _salaryController;
  late TextEditingController _descriptionController;

  late String _jobType;
  late String _workMode;
  late String _category;

  final List<String> _categories = [
    'Software Engineering',
    'Data Science',
    'Design',
    'Marketing',
    'Finance',
    'Sales',
    'Other',
  ];

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
  ];
  final List<String> _workModes = ['On-site', 'Remote', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.job.title);
    _companyController = TextEditingController(text: widget.job.companyName);
    _phoneController = TextEditingController(
      text: widget.job.companyPhone ?? '',
    );
    _locationController = TextEditingController(text: widget.job.location);
    _salaryController = TextEditingController(text: widget.job.salary);
    _descriptionController = TextEditingController(
      text: widget.job.description,
    );

    _jobType = widget.job.jobType;
    _workMode = widget.job.location.contains('Remote') ? 'Remote' : 'On-site';
    _category = 'Software Engineering'; // Default since not in model yet
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      appBar: AppBar(
        title: const Text(
          'Edit Job',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                        _buildTextField(
                          controller: _locationController,
                          hint: 'Colombo, Sri Lanka',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('City/Area'),
                        _buildTextField(
                          controller: _salaryController,
                          hint: 'Rs 150,000 / month',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildInputLabel('Category'),
              _buildDropdown(
                _category,
                _categories,
                (v) => setState(() => _category = v!),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Type'),
                        _buildDropdown(
                          _jobType,
                          _jobTypes,
                          (v) => setState(() => _jobType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Mode'),
                        _buildDropdown(
                          _workMode,
                          _workModes,
                          (v) => setState(() => _workMode = v!),
                        ),
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

  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
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
            return DropdownMenuItem<String>(value: value, child: Text(value));
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        onPressed: jobProvider.isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  final updatedJob = Job(
                    id: widget.job.id,
                    title: _titleController.text,
                    companyName: _companyController.text,
                    logoUrl: widget.job.logoUrl,
                    location: _locationController.text,
                    salary: _salaryController.text,
                    description: _descriptionController.text,
                    responsibilities: widget.job.responsibilities,
                    requirements: widget.job.requirements,
                    jobType: _jobType,
                    postedAt: widget.job.postedAt,
                    applyUrl: widget.job.applyUrl,
                    postedBy: auth.userId,
                    companyPhone: _phoneController.text,
                  );

                  try {
                    await jobProvider.addJob(
                      updatedJob,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job updated successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update job: $e')),
                      );
                    }
                  }
                }
              },
        child: jobProvider.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Update Job',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}
