import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/vet_model.dart';
import '../providers/vet_provider.dart';

class VeterinarianDirectoryScreen extends ConsumerStatefulWidget {
  const VeterinarianDirectoryScreen({super.key});

  @override
  ConsumerState<VeterinarianDirectoryScreen> createState() => _VeterinarianDirectoryScreenState();
}

class _VeterinarianDirectoryScreenState extends ConsumerState<VeterinarianDirectoryScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger migration check once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vetControllerProvider.notifier).migrateLegacyVetIfNeeded();
    });
  }

  Future<void> _deleteVet(VetModel vet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Veterinarian?'),
        content: Text('Are you sure you want to remove ${vet.doctorName}?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => ctx.pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    UiHelpers.showLoadingDialog(context, 'Deleting...', 'Please wait');

    final error = await ref.read(vetControllerProvider.notifier).deleteVetProfile(vet.id);
    
    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (error != null && mounted) {
      UiHelpers.showErrorDialog(context, error);
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
    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      UiHelpers.showErrorDialog(context, 'No email app is available on this device.');
    }
  }

  Future<void> _launchMaps(String address) async {
    if (address.trim().isEmpty) {
      if (mounted) UiHelpers.showErrorDialog(context, 'Location is not available for this veterinarian.');
      return;
    }
    final encoded = Uri.encodeComponent(address);
    // As per user instructions, if only address exists, use Google Maps HTTPS URL as the primary target.
    final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    
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

  @override
  Widget build(BuildContext context) {
    final vetsAsync = ref.watch(vetsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarians'),
      ),
      body: vetsAsync.when(
        data: (vets) {
          if (vets.isEmpty) return _buildEmptyState();
          return _buildVetList(vets);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading veterinarians: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vet/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Veterinarian'),
      ),
    );
  }

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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 28),
            Text(
              'No Veterinarians Added',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Widget _buildVetList(List<VetModel> vets) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: vets.length,
      itemBuilder: (context, index) {
        final vet = vets[index];
        return _buildVetCard(vet);
      },
    );
  }

  Widget _buildVetCard(VetModel vet) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isAvailable = vet.isAvailableForEmergency;
    final statusColor = isAvailable ? AppColors.healthy : AppColors.critical;
    final statusIcon = isAvailable ? Icons.check_circle : Icons.cancel;
    final statusLabel = isAvailable ? 'Available for Emergency' : 'Not Available';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.medical_services, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vet.doctorName,
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (vet.clinicName.isNotEmpty)
                        Text(
                          vet.clinicName,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      const SizedBox(height: 8),
                      // Status badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: tt.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions (Edit/Delete)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/vet/edit', extra: vet);
                    } else if (value == 'delete') {
                      _deleteVet(vet);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
          
          if (vet.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                vet.notes,
                style: tt.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
          const Divider(height: 1),
          
          // Action Buttons Bar
          Material(
            color: cs.surfaceContainerLowest,
            child: Row(
              children: [
                if (vet.phoneNumber.isNotEmpty)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _launchTel(vet.phoneNumber),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call'),
                    ),
                  ),
                if (vet.email.isNotEmpty)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _launchEmail(vet.email),
                      icon: const Icon(Icons.email, size: 18),
                      label: const Text('Email'),
                    ),
                  ),
                if (vet.address.isNotEmpty)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _launchMaps(vet.address),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Map'),
                    ),
                  ),
                if (vet.website.isNotEmpty)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _launchWebsite(vet.website),
                      icon: const Icon(Icons.language, size: 18),
                      label: const Text('Web'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
