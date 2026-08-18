import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/scan_history_repository.dart';
import '../models/scan_history_model.dart';

final scanHistoryStreamProvider = StreamProvider<List<ScanHistoryModel>>((ref) {
  final repository = ref.watch(scanHistoryRepositoryProvider);
  return repository.watchScanHistory();
});

final batchScanHistoryStreamProvider = StreamProvider.family<List<ScanHistoryModel>, ({String farmId, String batchId})>((ref, args) {
  final repository = ref.watch(scanHistoryRepositoryProvider);
  return repository.watchBatchScanHistory(args.farmId, args.batchId);
});

