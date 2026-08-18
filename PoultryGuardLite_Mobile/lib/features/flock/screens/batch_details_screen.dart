import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/router.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/batch_model.dart';
import '../models/farm_model.dart';
import '../providers/analytics_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/bird_stats_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/sales_provider.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../widgets/batch_analytics_widget.dart';
import '../widgets/batch_status_badge.dart';
import '../widgets/entry_card.dart';
import '../models/entry_model.dart';

class BatchDetailsScreen extends ConsumerStatefulWidget {
  const BatchDetailsScreen({
    super.key,
    required this.farm,
    required this.batch,
  });

  final FarmModel farm;
  final BatchModel batch;

  @override
  ConsumerState<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends ConsumerState<BatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showAllEntries = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Batch?',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
              color: Theme.of(ctx).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this batch? All records associated with it will be lost.',
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
                  'Deleting Batch...',
                  'Please wait...',
                );

                await ref
                    .read(batchControllerProvider.notifier)
                    .deleteBatch(widget.farm.id, widget.batch.id);

                if (!context.mounted) return;
                context.pop(); // close loading dialog

                final error = ref.read(batchControllerProvider).error;
                if (error != null) {
                  UiHelpers.showErrorDialog(context, error.toString());
                } else {
                  await UiHelpers.showSuccessDialog(
                    context,
                    'Batch Deleted Successfully',
                    '',
                  );
                  if (context.mounted) context.pop(); // go back
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
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final df = DateFormat.yMMMd();

    // ── Live batch stream ────────────────────────────────────────────────────
    // widget.batch is used ONLY as a stable key seed here.
    // All displayed data comes from the live stream below.
    final batchAsync = ref.watch(
      batchStreamProvider((
        farmId: widget.batch.farmId,
        batchId: widget.batch.id,
      )),
    );

    // While loading, fall back to the navigation seed so the UI isn't blank.
    final liveBatch = batchAsync.valueOrNull ?? widget.batch;

    return Scaffold(
      appBar: AppBar(
        title: Text(liveBatch.batchName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Entries'),
            Tab(text: 'Sales'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: DETAILS ─────────────────────────────────────────────────
          ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildDetailRow(
                context,
                'Farm',
                widget.farm.name,
                Icons.house_siding,
              ),
              _buildDetailRow(context, 'Breed', liveBatch.breed, Icons.pets),
              _buildDetailRow(
                context,
                'Bird Type',
                liveBatch.birdType,
                Icons.category,
              ),
              _buildDetailRow(
                context,
                'Initial Birds',
                liveBatch.totalBirds.toString(),
                Icons.numbers,
              ),
              Consumer(builder: (context, ref, child) {
                final params = (farmId: liveBatch.farmId, batchId: liveBatch.id);
                final stats = ref.watch(batchStatsProvider(params));
                return Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Remaining Birds',
                      stats.remainingBirds.toString(),
                      Icons.pie_chart,
                    ),
                    _buildDetailRow(
                      context,
                      'Total Sold',
                      stats.totalSold.toString(),
                      Icons.sell,
                    ),
                    _buildDetailRow(
                      context,
                      'Total Mortality',
                      stats.totalMortality.toString(),
                      Icons.warning_amber,
                    ),
                  ],
                );
              }),
              _buildDetailRow(
                context,
                'Status',
                liveBatch.status,
                Icons.flag,
                showStatusBadge: true,
              ),
              _buildDetailRow(
                context,
                'Supplier',
                liveBatch.supplier,
                Icons.local_shipping,
              ),
              _buildDetailRow(
                context,
                'Arrival Date',
                liveBatch.arrivalDate != null
                    ? df.format(liveBatch.arrivalDate!)
                    : 'N/A',
                Icons.flight_land,
              ),
              _buildDetailRow(
                context,
                'Market Date',
                liveBatch.expectedMarketDate != null
                    ? df.format(liveBatch.expectedMarketDate!)
                    : 'N/A',
                Icons.shopping_cart,
              ),
              _buildDetailRow(
                context,
                'Age',
                '${liveBatch.ageInDays} Days',
                Icons.calendar_today,
              ),

              if (liveBatch.notes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Notes',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(liveBatch.notes, style: tt.bodyMedium),
              ],
              const SizedBox(height: 32),
              Text(
                'Quick Actions',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.medical_services, size: 18),
                    label: const Text('Veterinarian'),
                    onPressed: () => context.push(AppRoutes.vet),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Final Report'),
                    onPressed: () => context.push('/flocks/final-report', extra: {'farm': widget.farm, 'batch': liveBatch}),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.list_alt, size: 18),
                    label: const Text('Entries Report'),
                    onPressed: () => context.push('/flocks/entries-report', extra: {'farm': widget.farm, 'batch': liveBatch}),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('AI Scanner'),
                    onPressed: () => context.go(AppRoutes.scan),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.attach_money, size: 18),
                    label: const Text('Sales'),
                    onPressed: () {
                      _tabController.animateTo(2); // Sales tab
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.analytics, size: 18),
                    label: const Text('Analytics'),
                    onPressed: () {
                      _tabController.animateTo(3); // Analytics tab
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.health_and_safety, size: 18),
                    label: const Text('Health'),
                    onPressed: () => context.push(
                      AppRoutes.health,
                      extra: {'farm': widget.farm, 'batch': liveBatch},
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.timeline, size: 18),
                    label: const Text('Timeline'),
                    onPressed: () => context.push(
                      AppRoutes.timeline,
                      extra: {'farm': widget.farm, 'batch': liveBatch},
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── TAB 2: ENTRIES ─────────────────────────────────────────────────
          Consumer(
            builder: (context, ref, child) {
              final entriesAsync = ref.watch(
                entriesStreamProvider((
                  farmId: widget.batch.farmId,
                  batchId: widget.batch.id,
                )),
              );

              return entriesAsync.when(
                data: (entries) {
                  final events = <DateTime, List<EntryModel>>{};
                  for (final e in entries) {
                    if (e.entryDate != null) {
                      final date = DateTime(e.entryDate!.year, e.entryDate!.month, e.entryDate!.day);
                      events.putIfAbsent(date, () => []).add(e);
                    }
                  }

                  final selectedDateWithoutTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                  final selectedEntries = events[selectedDateWithoutTime] ?? [];
                  
                  // Calculate week number based on batch start date
                  int weekNumber = 1;
                  if (liveBatch.arrivalDate != null) {
                    final daysDiff = selectedDateWithoutTime.difference(DateTime(liveBatch.arrivalDate!.year, liveBatch.arrivalDate!.month, liveBatch.arrivalDate!.day)).inDays;
                    if (daysDiff >= 0) {
                      weekNumber = (daysDiff ~/ 7) + 1;
                    }
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Entries', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                  onPressed: () => context.push('/flocks/entries-report', extra: {'farm': widget.farm, 'batch': liveBatch}),
                                  tooltip: 'Entries Report PDF',
                                ),
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment<bool>(value: false, icon: Icon(Icons.calendar_month), label: Text('Calendar')),
                                    ButtonSegment<bool>(value: true, icon: Icon(Icons.list), label: Text('All')),
                                  ],
                                  selected: {_showAllEntries},
                                  onSelectionChanged: (Set<bool> newSelection) {
                                    setState(() {
                                      _showAllEntries = newSelection.first;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!_showAllEntries)
                        TableCalendar<EntryModel>(
                          firstDay: liveBatch.arrivalDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          lastDay: DateTime.now().add(const Duration(days: 365)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          eventLoader: (day) {
                            final d = DateTime(day.year, day.month, day.day);
                            return events[d] ?? [];
                          },
                          calendarStyle: CalendarStyle(
                            markerDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                          ),
                        ),
                      if (!_showAllEntries)
                        const Divider(),
                      Expanded(
                        child: _showAllEntries
                            ? (entries.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.list_alt, size: 64, color: Theme.of(context).disabledColor),
                                        const SizedBox(height: 16),
                                        Text('No entries recorded yet', style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 8),
                                        Text('Tap the + button below to add your first entry.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).disabledColor), textAlign: TextAlign.center),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: entries.length,
                                    itemBuilder: (context, index) {
                                      final entryItem = entries[index];
                                      return EntryCard(
                                        entry: entryItem,
                                        onTap: () {
                                          context.push(
                                            AppRoutes.entryDetails,
                                            extra: {
                                              'farm': widget.farm,
                                              'batch': liveBatch,
                                              'entry': entryItem,
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ))
                            : (selectedEntries.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.calendar_today, size: 48, color: Theme.of(context).disabledColor),
                                        const SizedBox(height: 12),
                                        Text('No entries on ${df.format(_selectedDay)}', style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 4),
                                        Text('Week $weekNumber  •  Tap + to add an entry', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).disabledColor)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: selectedEntries.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Entries for ${df.format(_selectedDay)} (Week $weekNumber)', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                              FilledButton.icon(
                                                onPressed: () => context.push(
                                                  AppRoutes.addEntry,
                                                  extra: {
                                                    'farm': widget.farm,
                                                    'batch': liveBatch,
                                                    'selectedDate': _selectedDay,
                                                    'weekNumber': weekNumber,
                                                  },
                                                ),
                                                icon: const Icon(Icons.add),
                                                label: const Text('Add Another'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      final entryItem = selectedEntries[index - 1];
                                      return EntryCard(
                                        entry: entryItem,
                                        onTap: () {
                                          context.push(
                                            AppRoutes.entryDetails,
                                            extra: {
                                              'farm': widget.farm,
                                              'batch': liveBatch,
                                              'entry': entryItem,
                                            },
                                          );
                                        },
                                      );
                                    },
                                  )),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Error loading entries: $err')),
              );
            },
          ),

          // ── TAB 3: SALES ─────────────────────────────────────────────────
          Consumer(
            builder: (context, ref, child) {
              final salesAsync = ref.watch(
                salesStreamProvider((
                  farmId: widget.batch.farmId,
                  batchId: widget.batch.id,
                )),
              );

              return salesAsync.when(
                data: (sales) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sales', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                              onPressed: () => context.push('/flocks/sales-report', extra: {'farm': widget.farm, 'batch': liveBatch}),
                              tooltip: 'Sales Report PDF',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: sales.isEmpty 
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.monetization_on, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                                    const SizedBox(height: 24),
                                    Text('No sales recorded', style: tt.headlineSmall),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: sales.length,
                                itemBuilder: (context, index) {
                                  final sale = sales[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text('Sale on ${df.format(sale.date)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${sale.birdsSold} birds • ${sale.totalWeight} kg'),
                                      trailing: Text(CurrencyFormatter.format(sale.totalRevenue), 
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                      onTap: () {
                                        context.push(
                                          AppRoutes.editSale,
                                          extra: {
                                            'farm': widget.farm,
                                            'batch': liveBatch,
                                            'sale': sale,
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading sales: $err')),
              );
            },
          ),

          // ── TAB 4: ANALYTICS ───────────────────────────────────────────────
          Consumer(
            builder: (context, ref, child) {
              final analyticsAsync = ref.watch(
                batchAnalyticsProvider((
                  farmId: widget.batch.farmId,
                  batchId: widget.batch.id,
                  totalBirds: liveBatch.totalBirds,
                )),
              );

              return analyticsAsync.when(
                data: (analytics) {
                  if (analytics.totalEntries == 0) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.analytics_rounded,
                                size: 80,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No data yet',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Analytics will appear here once you log your first weekly entry.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return BatchAnalyticsWidget(
                    analytics: analytics,
                    batch: liveBatch,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Error loading analytics: $err')),
              );
            },
          ),
        ],
      ),

      // FAB: Edit (Tab 0), Add Entry (Tab 1), Add Sale (Tab 2), hidden (Tab 3)
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(
                  AppRoutes.editBatch,
                  extra: {'farm': widget.farm, 'batch': liveBatch},
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Batch'),
            )
          : _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(
                  AppRoutes.addEntry,
                  extra: {'farm': widget.farm, 'batch': liveBatch},
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            )
          : _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(
                  AppRoutes.addSale,
                  extra: {'farm': widget.farm, 'batch': liveBatch},
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Sale'),
            )
          : null,
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool showStatusBadge = false,
  }) {
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
                Row(
                  children: [
                    if (showStatusBadge) ...[
                      BatchStatusBadge(statusText: value, isCircular: true),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      value.isEmpty ? 'N/A' : value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
