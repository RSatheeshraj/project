import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/vet_repository.dart';
import '../models/vet_model.dart';

// ── Stream: all vet profiles ─────────────────────────────────────────────────

final vetsStreamProvider = StreamProvider.autoDispose<List<VetModel>>((ref) {
  return ref.watch(vetRepositoryProvider).watchVeterinarians();
});

// ── Controller ───────────────────────────────────────────────────────────────

final vetControllerProvider =
    StateNotifierProvider.autoDispose<VetController, bool>((ref) {
  return VetController(ref.watch(vetRepositoryProvider));
});

/// [state] is [true] while a write operation is in progress, [false] otherwise.
class VetController extends StateNotifier<bool> {
  VetController(this._repository) : super(false);

  final VetRepository _repository;

  /// Adds a new vet profile. Returns null on success, or error string.
  Future<String?> addVetProfile(VetModel vet) async {
    if (state) return null;
    state = true;
    try {
      await _repository.addVeterinarian(vet);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      if (mounted) state = false;
    }
  }

  /// Updates an existing vet profile. Returns null on success, or error string.
  Future<String?> updateVetProfile(VetModel vet) async {
    if (state) return null;
    state = true;
    try {
      await _repository.updateVeterinarian(vet);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      if (mounted) state = false;
    }
  }

  /// Deletes a vet profile by ID. Returns null on success, or error string.
  Future<String?> deleteVetProfile(String vetId) async {
    if (state) return null;
    state = true;
    try {
      await _repository.deleteVeterinarian(vetId);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      if (mounted) state = false;
    }
  }

  /// Manually trigger migration if needed (e.g. on directory load)
  Future<void> migrateLegacyVetIfNeeded() async {
    try {
      await _repository.migrateLegacyVetIfNeeded();
    } catch (_) {
      // Silently fail migration, it will retry next time
    }
  }
}

