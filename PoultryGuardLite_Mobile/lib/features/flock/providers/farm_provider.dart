import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/farm_repository.dart';
import '../models/farm_model.dart';

// ── Stream provider ───────────────────────────────────────────────────────────

/// Streams all farms belonging to the current user.
///
/// Backed by [FarmRepository.watchFarms] — sorted in-memory by [FarmModel.createdAt]
/// descending. No composite Firestore index required.
final farmsStreamProvider = StreamProvider<List<FarmModel>>((ref) {
  return ref.watch(farmRepositoryProvider).watchFarms();
});

/// Streams a single farm document by [farmId].
///
/// Backed by [FarmRepository.watchFarm]. Emits `null` if the document
/// does not exist. Used by [FarmDetailsScreen] so the Overview tab always
/// reflects the latest Firestore data instead of the stale navigation object.
final farmStreamProvider = StreamProvider.family<FarmModel?, String>((ref, farmId) {
  return ref.watch(farmRepositoryProvider).watchFarm(farmId);
});

// ── Controller provider ───────────────────────────────────────────────────────

/// Provides [FarmController] for add, update, and delete operations.
final farmControllerProvider =
    StateNotifierProvider<FarmController, AsyncValue<void>>((ref) {
      return FarmController(ref.watch(farmRepositoryProvider));
    });

class FarmController extends StateNotifier<AsyncValue<void>> {
  FarmController(this._repository) : super(const AsyncData(null));

  final FarmRepository _repository;

  /// Adds a new farm. Sets state to [AsyncLoading] while in progress,
  /// then [AsyncData] on success or [AsyncError] on failure.
  Future<void> addFarm(FarmModel farm) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.addFarm(farm));
  }

  /// Updates an existing farm. Sets state to [AsyncLoading] while in progress,
  /// then [AsyncData] on success or [AsyncError] on failure.
  Future<void> updateFarm(FarmModel farm) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateFarm(farm));
  }

  /// Deletes a farm by [farmId]. Sets state to [AsyncLoading] while in progress,
  /// then [AsyncData] on success or [AsyncError] on failure.
  Future<void> deleteFarm(String farmId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteFarm(farmId));
  }

  /// Resets the controller state to [AsyncData(null)].
  ///
  /// Call this after the UI has handled an [AsyncError] to prevent stale error
  /// state from persisting on the next operation.
  void reset() {
    state = const AsyncData(null);
  }
}
