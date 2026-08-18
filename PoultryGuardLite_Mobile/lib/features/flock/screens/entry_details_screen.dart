import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/entry_model.dart';
import '../models/farm_model.dart';
import '../providers/entry_provider.dart';

class EntryDetailsScreen extends ConsumerWidget {
  const EntryDetailsScreen({
    super.key,
    required this.farm,
    required this.batch,
    required this.entry,
  });

  final FarmModel farm;
  final BatchModel batch;
  final EntryModel entry;

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Entry?',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
              color: Theme.of(ctx).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this entry?',
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
              ),
              onPressed: () async {
                ctx.pop(); // close confirmation dialog

                UiHelpers.showLoadingDialog(
                  context,
                  'Deleting Entry...',
                  'Please wait...',
                );

                await ref
                    .read(entryControllerProvider.notifier)
                    .deleteEntry(farm.id, batch.id, entry.id);

                if (!context.mounted) return;
                context.pop(); // close loading dialog

                final error = ref.read(entryControllerProvider).error;
                if (error != null) {
                  UiHelpers.showErrorDialog(context, error.toString());
                } else {
                  await UiHelpers.showSuccessDialog(
                    context,
                    'Entry Deleted Successfully',
                    '',
                  );
                  if (context.mounted) context.pop(); // go back to batch
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final df = DateFormat.yMMMd();
    final dfFull = DateFormat.yMMMd().add_jm();

    final dateTitle = entry.entryDate != null
        ? df.format(entry.entryDate!)
        : 'Entry Details';

    return Scaffold(
      appBar: AppBar(
        title: Text(dateTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildDetailRow(
            context,
            'Entry Date',
            dateTitle,
            Icons.calendar_month_rounded,
          ),
          _buildDetailRow(
            context,
            'Farm',
            farm.name,
            Icons.house_siding_rounded,
          ),
          _buildDetailRow(
            context,
            'Batch',
            batch.batchName,
            Icons.layers_rounded,
          ),
          _buildDetailRow(
            context,
            'Feed Consumed',
            '${entry.feedConsumedKg} kg',
            Icons.restaurant_rounded,
          ),
          _buildDetailRow(
            context,
            'Water Consumed',
            '${entry.waterConsumedLitres} L',
            Icons.water_drop_rounded,
          ),
          _buildDetailRow(
            context,
            'Mortality Count',
            entry.mortalityCount.toString(),
            Icons.warning_amber_rounded,
          ),
          _buildDetailRow(
            context,
            'Average Weight',
            '${entry.averageWeightKg} kg',
            Icons.monitor_weight_rounded,
          ),
          _buildDetailRow(
            context,
            'Temperature',
            '${entry.temperature}°C',
            Icons.thermostat_rounded,
          ),
          _buildDetailRow(
            context,
            'Humidity',
            '${entry.humidity}%',
            Icons.water_outlined,
          ),

          if (entry.vaccination.isNotEmpty)
            _buildDetailRow(
              context,
              'Vaccination',
              entry.vaccination,
              Icons.vaccines_rounded,
            ),
          if (entry.medicine.isNotEmpty)
            _buildDetailRow(
              context,
              'Medicine',
              entry.medicine,
              Icons.medication_rounded,
            ),

          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Notes',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(entry.notes, style: tt.bodyMedium),
          ],

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Created: ${entry.createdAt != null ? dfFull.format(entry.createdAt!) : 'Unknown'}',
            style: tt.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          Text(
            'Last Updated: ${entry.updatedAt != null ? dfFull.format(entry.updatedAt!) : 'Unknown'}',
            style: tt.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            AppRoutes.editEntry,
            extra: {'farm': farm, 'batch': batch, 'entry': entry},
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit Entry'),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
