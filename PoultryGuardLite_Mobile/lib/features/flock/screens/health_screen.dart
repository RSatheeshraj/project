import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/batch_model.dart';
import '../models/entry_model.dart';
import '../models/farm_model.dart';
import '../providers/entry_provider.dart';
import 'health_report_screen.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({
    super.key,
    required this.farm,
    required this.batch,
  });

  final FarmModel farm;
  final BatchModel batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(
      entriesStreamProvider((farmId: batch.farmId, batchId: batch.id)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        // Back button is automatic — GoRouter push navigation pops to Batch Details.
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Health PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HealthReportScreen(farm: farm, batch: batch),
                ),
              );
            },
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) =>
            _HealthBody(farm: farm, batch: batch, entries: entries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading health data: $err')),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _HealthBody extends StatelessWidget {
  const _HealthBody({
    required this.farm,
    required this.batch,
    required this.entries,
  });

  final FarmModel farm;
  final BatchModel batch;
  final List<EntryModel> entries;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy');

    // Sort entries newest first for display
    final sorted = List<EntryModel>.from(entries)
      ..sort((a, b) => (b.entryDate ?? DateTime.now())
          .compareTo(a.entryDate ?? DateTime.now()));

    // Summary stats
    final totalMortality = entries.fold(0, (s, e) => s + e.mortalityCount);
    final mortalityRate = batch.totalBirds > 0
        ? (totalMortality / batch.totalBirds * 100).toStringAsFixed(1)
        : '0.0';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Batch Info Card ─────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Batch Overview',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _row(context, 'Farm', farm.name),
                _row(context, 'Batch', batch.batchName),
                _row(context, 'Bird Type',
                    batch.birdType.isEmpty ? '-' : batch.birdType),
                _row(context, 'Breed',
                    batch.breed.isEmpty ? '-' : batch.breed),
                _row(context, 'Status',
                    batch.status.isEmpty ? '-' : batch.status),
                _row(
                  context,
                  'Arrival Date',
                  batch.arrivalDate != null
                      ? df.format(batch.arrivalDate!)
                      : '-',
                ),
                _row(context, 'Age', '${batch.ageInDays} days'),
                _row(
                    context, 'Initial Birds', batch.totalBirds.toString()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Health Summary Card ─────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.summarize, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Health Summary',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Total Mortality',
                        value: totalMortality.toString(),
                        icon: Icons.warning_amber,
                        color:
                            totalMortality == 0 ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Mortality Rate',
                        value: '$mortalityRate%',
                        icon: Icons.percent,
                        color: double.parse(mortalityRate) < 2
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Records',
                        value: entries.length.toString(),
                        icon: Icons.receipt_long,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Health Records ──────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.history, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Health Records (${entries.length})',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (sorted.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text('No health records yet', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Health data will appear here once you add weekly entries.',
                    style: tt.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...sorted.map((entry) => _HealthEntryCard(entry: entry, df: df)),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).disabledColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Tile ─────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Health Entry Card ─────────────────────────────────────────────────────────

class _HealthEntryCard extends StatelessWidget {
  const _HealthEntryCard({required this.entry, required this.df});

  final EntryModel entry;
  final DateFormat df;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final hasMortality = entry.mortalityCount > 0;
    final hasVaccination = entry.vaccination.isNotEmpty;
    final hasMedicine = entry.medicine.isNotEmpty;
    final hasNotes = entry.notes.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasMortality
            ? BorderSide(color: Colors.orange.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: hasMortality
              ? Colors.orange.withValues(alpha: 0.15)
              : cs.primary.withValues(alpha: 0.15),
          child: Icon(
            hasMortality ? Icons.warning_amber : Icons.check_circle_outline,
            color: hasMortality ? Colors.orange : cs.primary,
            size: 20,
          ),
        ),
        title: Text(
          entry.entryDate != null ? df.format(entry.entryDate!) : 'No Date',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Week ${entry.weekNumber}  •  Mortality: ${entry.mortalityCount}',
          style: tt.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _detailRow(
                  context,
                  'Temperature',
                  entry.temperature > 0
                      ? '${entry.temperature.toStringAsFixed(1)} \u00b0C'
                      : '-',
                ),
                _detailRow(
                  context,
                  'Humidity',
                  entry.humidity > 0
                      ? '${entry.humidity.toStringAsFixed(1)} %'
                      : '-',
                ),
                _detailRow(
                    context, 'Mortality', entry.mortalityCount.toString()),
                if (hasVaccination) ...[
                  _detailRow(context, 'Vaccination', entry.vaccination),
                  if (entry.vaccinationDate != null)
                    _detailRow(context, 'Vacc. Date',
                        df.format(entry.vaccinationDate!)),
                  if (entry.nextVaccinationDate != null)
                    _detailRow(context, 'Next Vacc.',
                        df.format(entry.nextVaccinationDate!)),
                ],
                if (hasMedicine) ...[
                  _detailRow(context, 'Medicine', entry.medicine),
                  if (entry.medicineCost > 0)
                    _detailRow(context, 'Medicine Cost',
                        'Rs. ${entry.medicineCost.toStringAsFixed(2)}'),
                ],
                if (hasNotes) _detailRow(context, 'Notes', entry.notes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).disabledColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
