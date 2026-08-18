import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/vet_model.dart';
import '../providers/vet_provider.dart';

class AddEditVetScreen extends ConsumerStatefulWidget {
  const AddEditVetScreen({super.key, this.vet});
  
  final VetModel? vet;

  @override
  ConsumerState<AddEditVetScreen> createState() => _AddEditVetScreenState();
}

class _AddEditVetScreenState extends ConsumerState<AddEditVetScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _doctorNameController;
  late final TextEditingController _clinicNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _notesController;

  bool _isAvailableForEmergency = false;

  @override
  void initState() {
    super.initState();
    final vet = widget.vet;
    _doctorNameController = TextEditingController(text: vet?.doctorName ?? '');
    _clinicNameController = TextEditingController(text: vet?.clinicName ?? '');
    _phoneController = TextEditingController(text: vet?.phoneNumber ?? '');
    _emailController = TextEditingController(text: vet?.email ?? '');
    _addressController = TextEditingController(text: vet?.address ?? '');
    _websiteController = TextEditingController(text: vet?.website ?? '');
    _notesController = TextEditingController(text: vet?.notes ?? '');
    _isAvailableForEmergency = vet?.isAvailableForEmergency ?? false;
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVet() async {
    if (!_formKey.currentState!.validate()) return;

    final vet = VetModel(
      id: widget.vet?.id ?? '', // empty string for new creates
      doctorName: _doctorNameController.text.trim(),
      clinicName: _clinicNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      website: _websiteController.text.trim(),
      isAvailableForEmergency: _isAvailableForEmergency,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    UiHelpers.showLoadingDialog(context, 'Saving...', 'Please wait');

    final notifier = ref.read(vetControllerProvider.notifier);
    String? error;
    
    if (widget.vet == null) {
      error = await notifier.addVetProfile(vet);
    } else {
      error = await notifier.updateVetProfile(vet);
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

    if (error != null) {
      UiHelpers.showErrorDialog(context, error);
    } else {
      UiHelpers.showSuccessDialog(
        context,
        'Saved',
        'Veterinarian profile updated.',
      );
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vet == null ? 'Add Veterinarian' : 'Edit Veterinarian'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // Doctor Name
            TextFormField(
              controller: _doctorNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Doctor Name *',
                prefixIcon: Icon(Icons.person_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Doctor name is required' : null,
            ),
            const SizedBox(height: 14),

            // Clinic Name
            TextFormField(
              controller: _clinicNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Clinic Name *',
                prefixIcon: Icon(Icons.local_hospital_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Clinic name is required' : null,
            ),
            const SizedBox(height: 14),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                if (v.trim().length < 7) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Email (optional)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address (optional)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Address (optional)
            TextFormField(
              controller: _addressController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Clinic Address (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Website (optional)
            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                hintText: 'e.g. example.com',
                prefixIcon: Icon(Icons.language_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                final urlText = v.trim();
                final prefixed = urlText.startsWith('http://') ||
                        urlText.startsWith('https://')
                    ? urlText
                    : 'https://$urlText';
                final uri = Uri.tryParse(prefixed);
                if (uri == null || !uri.hasAuthority) {
                  return 'Enter a valid website URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Emergency Availability toggle
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isAvailableForEmergency
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      color: _isAvailableForEmergency
                          ? AppColors.healthy
                          : AppColors.critical,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Availability',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _isAvailableForEmergency
                                ? 'Available for emergencies'
                                : 'Not available for emergencies',
                            style: tt.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailableForEmergency,
                      onChanged: (v) => setState(() => _isAvailableForEmergency = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Notes (optional)
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveVet,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(widget.vet != null ? 'Update Profile' : 'Save Profile'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
