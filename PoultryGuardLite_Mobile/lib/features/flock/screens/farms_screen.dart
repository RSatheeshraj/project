import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../providers/farm_provider.dart';
import '../widgets/farm_card.dart';

class FarmsScreen extends ConsumerWidget {
  const FarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final farmsAsync = ref.watch(farmsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Farms')),
      body: farmsAsync.when(
        data: (farms) {
          if (farms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.house_siding_rounded,
                      size: 64,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text('No Farms Yet', style: tt.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first farm to start monitoring your flocks.',
                      style: tt.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: farms.length,
            itemBuilder: (context, index) {
              final farm = farms[index];
              return FarmCard(
                farm: farm,
                onTap: () {
                  context.push(AppRoutes.farmDetails, extra: farm);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading farms: $err',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.addFarm);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Farm'),
      ),
    );
  }
}
