import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/batch_repository.dart';
import '../models/batch_model.dart';

// ── Stream providers ──────────────────────────────────────────────────────────

/// Streams all batches for a specific farm by [farmId].
///
/// Backed by [BatchRepository.watchBatches] — ordered by `createdAt` descending.
/// Uses a single-field Firestore index (auto-created). No composite index required.
final batchesByFarmStreamProvider =
    StreamProvider.family<List<BatchModel>, String>((ref, farmId) {
      return ref.watch(batchRepositoryProvider).watchBatches(farmId);
    });

/// Streams ALL batches across all farms for the current user.
///
/// Backed by [BatchRepository.watchAllUserBatches] — uses a collection group query.
/// Required for global dashboard statistics (active bird count, active batch count).
///
/// **Firebase Console**: A collection group index must exist on the `batches`
/// collection group for the `ownerId` field (Ascending scope).
final allBatchesStreamProvider = StreamProvider<List<BatchModel>>((ref) {
  return ref.watch(batchRepositoryProvider).watchAllUserBatches();
});

/// Derives a per-farm batch list from [allBatchesStreamProvider] in-memory.
///
/// This provider opens **zero additional Firestore listeners**. It simply
/// filters the already-live global batch stream by [farmId]. Use this in
/// list widgets (e.g. [FarmCard]) to avoid the N+1 Firestore listener problem.
final batchesByFarmFromCacheProvider =
    Provider.family<AsyncValue<List<BatchModel>>, String>((ref, farmId) {
      return ref
          .watch(allBatchesStreamProvider)
          .whenData(
            (batches) => batches.where((b) => b.farmId == farmId).toList(),
          );
    });

// Named-record type for [batchStreamProvider] family key.
/// Uniquely identifies a single batch by farm and batch ID.
typedef BatchParams = ({String farmId, String batchId});

/// Streams a single batch document identified by [BatchParams].
///
/// Backed by [BatchRepository.watchBatch]. Emits `null` if the document does
/// not exist. Used by [BatchDetailsScreen] so Current Birds, Status, and all
/// analytics always reflect the latest Firestore data instead of the stale
/// navigation-passed `widget.batch` object.
final batchStreamProvider =
    StreamProvider.family<BatchModel?, BatchParams>((ref, params) {
      return ref
          .watch(batchRepositoryProvider)
          .watchBatch(params.farmId, params.batchId);
    });

// ── Controller provider ───────────────────────────────────────────────────────

/// Provides [BatchController] for add, update, and delete operations.
final batchControllerProvider =
    StateNotifierProvider<BatchController, AsyncValue<void>>((ref) {
      return BatchController(ref.watch(batchRepositoryProvider));
    });

class BatchController extends StateNotifier<AsyncValue<void>> {
  BatchController(this._repository) : super(const AsyncData(null));

  final BatchRepository _repository;

  /// Adds a new batch. Sets state to [AsyncLoading] while in progress,
  /// then [AsyncData] on success or [AsyncError] on failure.
  Future<void> addBatch(BatchModel batch) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.addBatch(batch));
  }

  /// Updates an existing batch. Sets state to [AsyncLoading] while in progress,
  /// then [AsyncData] on success or [AsyncError] on failure.
  Future<void> updateBatch(BatchModel batch) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateBatch(batch));
  }

  /// Deletes a batch by [batchId] within [farmId].
  /// Sets state to [AsyncLoading] while in progress,
  /// then [AsyncData] on success or [AsyncError] on failure.
  Future<void> deleteBatch(String farmId, String batchId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteBatch(farmId, batchId),
    );
  }

  /// Resets the controller state to [AsyncData(null)].
  ///
  /// Call this after the UI has handled an [AsyncError] to prevent stale error
  /// state from persisting on the next operation.
  void reset() {
    state = const AsyncData(null);
  }
}
