import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/sales_repository.dart';
import '../models/sales_model.dart';

final salesStreamProvider =
    StreamProvider.family<List<SalesModel>, ({String farmId, String batchId})>((ref, args) {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.watchSales(args.farmId, args.batchId);
});

final salesControllerProvider = StateNotifierProvider<SalesController, AsyncValue<void>>((ref) {
  return SalesController(ref);
});

class SalesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SalesController(this._ref) : super(const AsyncData(null));

  Future<void> addOrUpdateSale({
    required String farmId,
    required String batchId,
    required SalesModel sale,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(salesRepositoryProvider);
      await repo.addOrUpdateSale(farmId, batchId, sale);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteSale(String farmId, String batchId, String saleId) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(salesRepositoryProvider);
      await repo.deleteSale(farmId, batchId, saleId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
