import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/entry_repository.dart';
import '../models/entry_model.dart';

// ── Entry family parameter ────────────────────────────────────────────────────

/// Named record used as the family key for [entriesStreamProvider].
///
/// Dart 3 record types have structural equality, so Riverpod correctly
/// identifies two providers as the same when both [farmId] and [batchId] match.
typedef EntryParams = ({String farmId, String batchId});

// ── Stream provider ───────────────────────────────────────────────────────────

/// Streams all weekly entries for a specific batch, ordered by
/// [EntryModel.entryDate] descending (most recent first).
///
/// Backed by [EntryRepository.watchEntries] — ordered by `entryDate` using
/// a single-field Firestore index (auto-created). No composite index required.
final entriesStreamProvider =
    StreamProvider.family<List<EntryModel>, EntryParams>((ref, params) {
      return ref
          .watch(entryRepositoryProvider)
          .watchEntries(params.farmId, params.batchId);
    });

// ── Controller provider ───────────────────────────────────────────────────────

/// Provides [EntryController] for add, update, and delete operations.
final entryControllerProvider =
    StateNotifierProvider<EntryController, AsyncValue<void>>((ref) {
      return EntryController(ref.watch(entryRepositoryProvider));
    });

class EntryController extends StateNotifier<AsyncValue<void>> {
  EntryController(this._repository) : super(const AsyncData(null));

  final EntryRepository _repository;

  /// Adds a new weekly entry. Sets state to [AsyncLoading] while in progress,
  /// then [AsyncData] on success or [AsyncError] on failure.
  Future<void> addEntry(EntryModel entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.addEntry(entry));
  }

  /// Updates an existing weekly entry. Sets state to [AsyncLoading] while in
  /// progress, then [AsyncData] on success or [AsyncError] on failure.
  Future<void> updateEntry(EntryModel entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateEntry(entry));
  }

  /// Deletes a weekly entry by [entryId]. Sets state to [AsyncLoading] while
  /// in progress, then [AsyncData] on success or [AsyncError] on failure.
  Future<void> deleteEntry(
    String farmId,
    String batchId,
    String entryId,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteEntry(farmId, batchId, entryId),
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
