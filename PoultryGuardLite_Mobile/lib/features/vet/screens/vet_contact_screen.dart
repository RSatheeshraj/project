import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/vet_model.dart';
import '../providers/vet_provider.dart';

class VetContactScreen extends ConsumerStatefulWidget {
  const VetContactScreen({super.key});

  @override
  ConsumerState<VetContactScreen> createState() => _VetContactScreenState();
}

class _VetContactScreenState extends ConsumerState<VetContactScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isAvailableForEmergency = false;

  VetModel? _currentVet;

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

  void _populateForm(VetModel vet) {
    _doctorNameController.text = vet.doctorName;
    _clinicNameController.text = vet.clinicName;
    _phoneController.text = vet.phoneNumber;
    _emailController.text = vet.email;
    _addressController.text = vet.address;
    _websiteController.text = vet.website;
    _notesController.text = vet.notes;
    _isAvailableForEmergency = vet.isAvailableForEmergency;
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveVet() async {
    if (!_formKey.currentState!.validate()) return;

    final vet = VetModel(
      id: _currentVet?.id ?? '',
      doctorName: _doctorNameController.text.trim(),
      clinicName: _clinicNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      website: _websiteController.text.trim(),
      isAvailableForEmergency: _isAvailableForEmergency,
      notes: _notesController.text.trim(),
    );

    // Show loading — always dismissed in finally
    if (!mounted) return;
    UiHelpers.showLoadingDialog(context, 'Saving Vet Info...', 'Please wait');

    String? error;
    try {
      error = await ref
          .read(vetControllerProvider.notifier)
          .addVetProfile(vet);
    } finally {
      // Always close the loading dialog, even on error or widget disposal
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    if (error != null) {
      UiHelpers.showErrorDialog(context, error);
    } else {
      setState(() => _isEditing = false);
      UiHelpers.showSuccessDialog(
        context,
        'Saved',
        'Veterinarian profile updated.',
      );
    }
  }

  // ── Deep link helpers ─────────────────────────────────────────────────────

  Future<void> _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      UiHelpers.showErrorDialog(context, 'Unable to open the phone dialer.');
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      UiHelpers.showErrorDialog(context, 'Unable to open email application.');
    }
  }

  Future<void> _launchMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    // Use geo: URI so any installed maps app can handle it.
    final geoUri = Uri.parse('geo:0,0?q=$encoded');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }
    // Fallback: Google Maps search URL
    final mapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(mapsUrl)) {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      UiHelpers.showErrorDialog(context, 'Unable to open Maps application.');
    }
  }

  Future<void> _launchWebsite(String website) async {
    String url = website.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) UiHelpers.showErrorDialog(context, 'Invalid website URL.');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      UiHelpers.showErrorDialog(context, 'Unable to open browser.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vetAsync = ref.watch(vetsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarian'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () {
                if (_currentVet != null) _populateForm(_currentVet!);
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: vetAsync.when(
        data: (vets) {
          final vet = vets.isNotEmpty ? vets.first : null;
          _currentVet = vet;
          if (vet == null && !_isEditing) return _buildEmptyState();
          if (_isEditing) return _buildForm();
          return _buildProfile(vet!);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error loading profile: $e'),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 84,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.35),
            ),
            const SizedBox(height: 28),
            Text(
              'No Veterinarian Added',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Save your veterinarian\'s contact details for quick access during emergencies.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: () {
                _populateForm(const VetModel(
                  id: '',
                  doctorName: '',
                  clinicName: '',
                  phoneNumber: '',
                  email: '',
                  address: '',
                  website: '',
                  isAvailableForEmergency: false,
                  notes: '',
                ));
                setState(() => _isEditing = true);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Veterinarian'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile view ──────────────────────────────────────────────────────────

  Widget _buildProfile(VetModel vet) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Header card ──────────────────────────────────────────────────
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.medical_services,
                    size: 32,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vet.doctorName.isNotEmpty
                            ? vet.doctorName
                            : 'Doctor Name',
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (vet.clinicName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            vet.clinicName,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Emergency availability ─────────────────────────────────────
        _EmergencyStatusCard(isAvailable: vet.isAvailableForEmergency),

        const SizedBox(height: 20),

        // ── Section: Contact & Location ───────────────────────────────
        _SectionHeader(label: 'Contact & Location'),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              // Phone
              if (vet.phoneNumber.isNotEmpty) ...[
                _ContactActionTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: vet.phoneNumber,
                  actionLabel: 'Call',
                  actionIcon: Icons.call,
                  onAction: () => _launchTel(vet.phoneNumber),
                ),
              ],
              // Email
              if (vet.email.isNotEmpty) ...[
                if (vet.phoneNumber.isNotEmpty) const Divider(height: 1),
                _ContactActionTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: vet.email,
                  actionLabel: 'Email',
                  actionIcon: Icons.send,
                  onAction: () => _launchEmail(vet.email),
                ),
              ],
              // Address
              if (vet.address.isNotEmpty) ...[
                if (vet.phoneNumber.isNotEmpty || vet.email.isNotEmpty)
                  const Divider(height: 1),
                _ContactActionTile(
                  icon: Icons.location_on_outlined,
                  label: 'Clinic Address',
                  value: vet.address,
                  actionLabel: 'Maps',
                  actionIcon: Icons.map_outlined,
                  onAction: () => _launchMaps(vet.address),
                ),
              ],
              // Website
              if (vet.website.isNotEmpty) ...[
                if (vet.phoneNumber.isNotEmpty ||
                    vet.email.isNotEmpty ||
                    vet.address.isNotEmpty)
                  const Divider(height: 1),
                _ContactActionTile(
                  icon: Icons.language_outlined,
                  label: 'Website',
                  value: vet.website,
                  actionLabel: 'Open',
                  actionIcon: Icons.open_in_new,
                  onAction: () => _launchWebsite(vet.website),
                ),
              ],
              // Fallback if all fields empty
              if (vet.phoneNumber.isEmpty &&
                  vet.email.isEmpty &&
                  vet.address.isEmpty &&
                  vet.website.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No contact details provided.'),
                ),
            ],
          ),
        ),

        // ── Notes ────────────────────────────────────────────────────
        if (vet.notes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader(label: 'Notes'),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                vet.notes,
                style: tt.bodyMedium,
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),

        // ── Primary CTA ──────────────────────────────────────────────
        if (vet.phoneNumber.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _launchTel(vet.phoneNumber),
            icon: const Icon(Icons.call),
            label: const Text('Call Veterinarian'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
      ],
    );
  }

  // ── Edit form ─────────────────────────────────────────────────────────────

  Widget _buildForm() {
    final tt = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text(
            _currentVet == null ? 'Add Veterinarian' : 'Edit Veterinarian',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailableForEmergency,
                    onChanged: (v) =>
                        setState(() => _isAvailableForEmergency = v),
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
              if (_currentVet != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _saveVet,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _EmergencyStatusCard extends StatelessWidget {
  const _EmergencyStatusCard({required this.isAvailable});
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.healthy : AppColors.critical;
    final icon = isAvailable ? Icons.check_circle : Icons.cancel;
    final label = isAvailable
        ? 'Available for Emergency'
        : 'Not Available for Emergency';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ContactActionTile extends StatelessWidget {
  const _ContactActionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onAction,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 16),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
