import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/batch_model.dart';
import '../models/entry_model.dart';
import '../models/farm_model.dart';
import '../models/sales_model.dart';
import '../providers/entry_provider.dart';
import '../providers/sales_provider.dart';
import 'timeline_report_screen.dart';

/// A single timeline event synthesized from batch/entry/sale data.
class _TimelineEvent {
  const _TimelineEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.type = '',
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String type;
}

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({
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
    final salesAsync = ref.watch(
      salesStreamProvider((farmId: batch.farmId, batchId: batch.id)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        // Back button is automatic — GoRouter push navigation pops to Batch Details.
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Timeline PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TimelineReportScreen(farm: farm, batch: batch),
                ),
              );
            },
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) => salesAsync.when(
          data: (sales) => _TimelineBody(
            farm: farm,
            batch: batch,
            entries: entries,
            sales: sales,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Error loading sales: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Error loading entries: $err')),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    required this.farm,
    required this.batch,
    required this.entries,
    required this.sales,
  });

  final FarmModel farm;
  final BatchModel batch;
  final List<EntryModel> entries;
  final List<SalesModel> sales;

  List<_TimelineEvent> _buildEvents() {
    final events = <_TimelineEvent>[];

    // 1. Batch Arrival
    if (batch.arrivalDate != null) {
      events.add(_TimelineEvent(
        date: batch.arrivalDate!,
        title: 'Batch Arrived',
        subtitle: '${batch.totalBirds} birds • ${batch.breed} • ${batch.birdType}',
        icon: Icons.flight_land,
        color: Colors.blue,
        type: 'arrival',
      ));
    }

    // 2. Weekly Entries
    for (final entry in entries) {
      if (entry.entryDate == null) continue;

      // Determine what happened this entry
      final parts = <String>[];
      if (entry.mortalityCount > 0) {
        parts.add('Mortality: ${entry.mortalityCount}');
      }
      if (entry.vaccination.isNotEmpty) {
        parts.add('Vaccination: ${entry.vaccination}');
      }
      if (entry.medicine.isNotEmpty) {
        parts.add('Medicine: ${entry.medicine}');
      }
      if (entry.feedConsumedKg > 0) {
        parts.add('Feed: ${entry.feedConsumedKg.toStringAsFixed(1)} kg');
      }
      if (entry.averageWeightKg > 0) {
        parts.add('Avg Wt: ${entry.averageWeightKg.toStringAsFixed(2)} kg');
      }

      final subtitle = parts.isEmpty
          ? 'Week ${entry.weekNumber} entry recorded'
          : parts.join(' • ');

      final hasMortality = entry.mortalityCount > 0;
      final hasVaccination = entry.vaccination.isNotEmpty;

      events.add(_TimelineEvent(
        date: entry.entryDate!,
        title: 'Week ${entry.weekNumber} Entry',
        subtitle: subtitle,
        icon: hasMortality
            ? Icons.warning_amber
            : hasVaccination
                ? Icons.vaccines
                : Icons.edit_note,
        color: hasMortality
            ? Colors.orange
            : hasVaccination
                ? Colors.purple
                : Colors.teal,
        type: 'entry',
      ));
    }

    // 3. Sales Events
    for (final sale in sales) {
      final parts = <String>[
        '${sale.birdsSold} birds',
        '${sale.totalWeight.toStringAsFixed(1)} kg',
        'Rs. ${sale.totalRevenue.toStringAsFixed(2)}',
      ];
      if (sale.buyerName.isNotEmpty) parts.add('Buyer: ${sale.buyerName}');

      events.add(_TimelineEvent(
        date: sale.date,
        title: 'Sale',
        subtitle: parts.join(' • '),
        icon: Icons.sell,
        color: Colors.green,
        type: 'sale',
      ));
    }

    // 4. Expected Market Date (future marker)
    if (batch.expectedMarketDate != null) {
      events.add(_TimelineEvent(
        date: batch.expectedMarketDate!,
        title: 'Expected Market Date',
        subtitle: 'Target sale date for this batch',
        icon: Icons.shopping_cart,
        color: Colors.indigo,
        type: 'market',
      ));
    }

    // Sort chronologically oldest → newest
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy');

    final events = _buildEvents();

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
                    Icon(Icons.timeline, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Batch Timeline',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _infoRow(context, 'Farm', farm.name),
                _infoRow(context, 'Batch', batch.batchName),
                _infoRow(context, 'Status', batch.status.isEmpty ? '-' : batch.status),
                _infoRow(
                  context,
                  'Arrival Date',
                  batch.arrivalDate != null ? df.format(batch.arrivalDate!) : '-',
                ),
                _infoRow(context, 'Age', '${batch.ageInDays} days'),
                _infoRow(context, 'Events', events.length.toString()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Timeline Events ─────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.history, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Events (${events.length})',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (events.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.timeline, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text('No timeline events yet', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Events will appear as you add entries and sales.',
                    style: tt.bodyMedium?.copyWith(color: Theme.of(context).disabledColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(events.length, (index) {
            final event = events[index];
            final isLast = index == events.length - 1;
            return _TimelineEventTile(
              event: event,
              df: df,
              isLast: isLast,
            );
          }),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
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

// ── Timeline Event Tile ───────────────────────────────────────────────────────

class _TimelineEventTile extends StatelessWidget {
  const _TimelineEventTile({
    required this.event,
    required this.df,
    required this.isLast,
  });

  final _TimelineEvent event;
  final DateFormat df;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isToday = DateTime.now().isAfter(event.date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline spine ──────────────────────────────────────────────
          SizedBox(
            width: 48,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: event.color.withValues(alpha: isToday ? 1.0 : 0.3),
                  child: Icon(event.icon, size: 16, color: Colors.white),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Event card ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: event.color.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: event.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              df.format(event.date),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: event.color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle,
                        style: tt.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
