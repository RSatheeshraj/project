import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../models/farm_model.dart';
import '../providers/farm_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/bird_stats_provider.dart';
import '../widgets/batch_card.dart';

class FarmDetailsScreen extends ConsumerStatefulWidget {
  const FarmDetailsScreen({super.key, required this.farm});

  final FarmModel farm;

  @override
  ConsumerState<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends ConsumerState<FarmDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            'Delete Farm?',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
              color: Theme.of(ctx).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this farm?',
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
                  'Deleting Farm...',
                  'Please wait...',
                );

                await ref
                    .read(farmControllerProvider.notifier)
                    .deleteFarm(widget.farm.id);

                if (!context.mounted) return;
                context.pop(); // close loading dialog

                final error = ref.read(farmControllerProvider).error;
                if (error != null) {
                  UiHelpers.showErrorDialog(context, error.toString());
                } else {
                  await UiHelpers.showSuccessDialog(
                    context,
                    'Farm Deleted Successfully',
                    '',
                  );
                  if (context.mounted) context.pop(); // go back to farms list
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

    // widget.farm is used ONLY as the stable farmId seed.
    // liveFarm carries the latest Firestore data for display.
    final farmAsync = ref.watch(farmStreamProvider(widget.farm.id));
    final liveFarm = farmAsync.valueOrNull ?? widget.farm;

    return Scaffold(
      appBar: AppBar(
        title: Text(liveFarm.name),

        actions: [
          if (_tabController.index == 1)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Search to be implemented later
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search coming soon!')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Batches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: OVERVIEW
          // liveFarm is derived from farmStreamProvider at the top of build().
          ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Consumer(builder: (context, ref, child) {
                final stats = ref.watch(farmStatsProvider(widget.farm.id));
                return Column(
                  children: [
                    _buildDetailRow(context, 'Initial Birds', stats.initialBirds.toString(), Icons.pets),
                    _buildDetailRow(context, 'Remaining Birds', stats.remainingBirds.toString(), Icons.check_circle_outline),
                    _buildDetailRow(context, 'Total Sold', stats.totalSold.toString(), Icons.sell),
                    _buildDetailRow(context, 'Total Mortality', stats.totalMortality.toString(), Icons.warning_amber),
                    _buildDetailRow(context, 'Active Batches', stats.activeBatches.toString(), Icons.layers),
                    const Divider(height: 32),
                  ],
                );
              }),
              _buildDetailRow(context, 'Type', liveFarm.type, Icons.category),
              _buildDetailRow(context, 'Owner', liveFarm.ownerName, Icons.person),
              _buildDetailRow(context, 'Phone', liveFarm.phone, Icons.phone),
              _buildDetailRow(context, 'Address', liveFarm.address, Icons.location_on),
              _buildDetailRow(context, 'Sheds', liveFarm.sheds.toString(), Icons.house_siding),
              _buildDetailRow(context, 'Capacity', liveFarm.capacity.toString(), Icons.group),

              if (liveFarm.notes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Notes',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(liveFarm.notes, style: tt.bodyMedium),
              ],

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                'Created: ${liveFarm.createdAt != null ? DateFormat.yMMMd().add_jm().format(liveFarm.createdAt!) : 'Unknown'}',
                style: tt.bodySmall?.copyWith(color: Theme.of(context).disabledColor),
              ),
              Text(
                'Last Updated: ${liveFarm.updatedAt != null ? DateFormat.yMMMd().add_jm().format(liveFarm.updatedAt!) : 'Unknown'}',
                style: tt.bodySmall?.copyWith(color: Theme.of(context).disabledColor),
              ),
            ],
          ),

          // TAB 2: BATCHES
          Consumer(
            builder: (context, ref, child) {
              final batchesAsync = ref.watch(
                batchesByFarmStreamProvider(widget.farm.id),
              );

              return batchesAsync.when(
                data: (batches) {
                  if (batches.isEmpty) {
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
                                Icons.inbox_rounded,
                                size: 80,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No batches found',
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This farm currently has no batches. Add your first batch to start tracking birds.',
                              style: tt.bodyLarge?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            FilledButton.icon(
                              onPressed: () => context.push(
                                AppRoutes.addBatch,
                                extra: widget.farm,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Batch'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: batches.length,
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return BatchCard(
                        batch: batch,
                        onTap: () {
                          context.push(
                            AppRoutes.batchDetails,
                            extra: {'farm': widget.farm, 'batch': batch},
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(AppRoutes.editFarm, extra: liveFarm);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Farm'),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                context.push(AppRoutes.addBatch, extra: liveFarm);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Batch'),
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
