import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.userName);
    _emailController = TextEditingController(text: auth.userEmail);
    _phoneController = TextEditingController(text: auth.phoneNumber);
    _experienceController = TextEditingController(text: auth.experience);
    _bioController = TextEditingController(
      text: auth.bio ?? (auth.isRecruiter ? auth.companyDescription : null),
    );
    _locationController = TextEditingController(text: auth.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Widget _buildVerificationBadge({
    required String title,
    required bool isVerified,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isVerified
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVerified
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
              size: 14,
              color: isVerified ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isVerified ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneVerificationDialog(AuthProvider auth) {
    final phoneController = TextEditingController(text: _phoneController.text);
    final otpController = TextEditingController();
    bool codeSent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(codeSent ? 'Enter OTP' : 'Verify Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!codeSent) ...[
                const Text(
                  'Enter your phone number with country code to receive a verification code.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+94 ...',
                  ),
                ),
              ] else ...[
                Text(
                  'Enter the 6-digit code sent to ${phoneController.text}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    counterText: '',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (auth.isLoading) return;
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (!codeSent) {
                        if (phoneController.text.isNotEmpty) {
                          final success = await auth.sendPhoneOtp(
                            phoneController.text,
                          );
                          if (success) {
                            setDialogState(() => codeSent = true);
                          }
                        }
                      } else {
                        if (otpController.text.length == 6) {
                          final verified = await auth.verifyPhoneOtp(
                            otpController.text,
                          );
                          if (verified && context.mounted) {
                            _phoneController.text = phoneController.text;
                            Navigator.pop(context);
                            setState(() {});
                          }
                        }
                      }
                    },
              child: auth.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(codeSent ? 'Verify' : 'Send Code'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isRecruiter = auth.isRecruiter;
    final isExternal = auth.isExternalProvider;

    final nameLabel = isRecruiter ? 'Company Name' : 'Name';
    final experienceLabel = isRecruiter
        ? 'Industry / Sector'
        : 'Current Role / Experience';
    final bioLabel = isRecruiter ? 'Company Description' : 'Bio';

    return Scaffold(
      appBar: AppBar(
        title: Text(isRecruiter ? 'Edit Company Profile' : 'Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: nameLabel,
                prefixIcon: const Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              readOnly: isExternal,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_rounded),
                helperText: null,
                suffixIcon: Transform.scale(
                  scale: 0.8,
                  child: _buildVerificationBadge(
                    title:
                        (isExternal ||
                            (auth.isEmailVerified &&
                                _emailController.text == auth.userEmail))
                        ? 'Verified'
                        : 'Verify',
                    isVerified:
                        isExternal ||
                        (auth.isEmailVerified &&
                            _emailController.text == auth.userEmail),
                    onTap:
                        (isExternal ||
                            (auth.isEmailVerified &&
                                _emailController.text == auth.userEmail))
                        ? () {}
                        : () {
                            auth.sendEmailVerification(
                              newEmail: _emailController.text,
                            );
                          },
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: isExternal ? null : (val) => setState(() {}),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone_rounded),
                suffixIcon: Transform.scale(
                  scale: 0.8,
                  child: _buildVerificationBadge(
                    title:
                        (auth.isPhoneVerified &&
                            _phoneController.text == auth.phoneNumber)
                        ? 'Verified'
                        : 'Verify',
                    isVerified:
                        (auth.isPhoneVerified &&
                        _phoneController.text == auth.phoneNumber),
                    onTap: () {
                      _showPhoneVerificationDialog(auth);
                    },
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: experienceLabel,
                prefixIcon: const Icon(Icons.work_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                prefixIcon: const Icon(Icons.location_on_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: bioLabel,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              if (_nameController.text.isEmpty) {
                auth.showNotification('Name cannot be empty.', isError: true);
                return;
              }

              await auth.reloadUser();

              final emailChanged =
                  _emailController.text.trim() != (auth.userEmail ?? '');
              final phoneChanged =
                  _phoneController.text.trim() != (auth.phoneNumber ?? '');

              if (emailChanged && !auth.isEmailVerified) {
                auth.showNotification(
                  'Please verify your new email before saving.',
                  isError: true,
                );
                return;
              }

              if (phoneChanged && !auth.isPhoneVerified) {
                auth.showNotification(
                  'Please verify your new phone number before saving.',
                  isError: true,
                );
                return;
              }

              await auth.updateUserDetails(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                bio: _bioController.text.trim(),
                experience: _experienceController.text.trim(),
                location: _locationController.text.trim(),
              );

              if (context.mounted) {
                final jobProvider = Provider.of<JobProvider>(
                  context,
                  listen: false,
                );
                await jobProvider.loadJobs(
                  location: _locationController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: auth.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
