import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/ai_scan_repository.dart';
import '../../../data/repositories/scan_history_repository.dart';
import '../../flock/models/batch_model.dart';
import '../../flock/models/farm_model.dart';
import '../../flock/providers/analytics_provider.dart';
import '../../flock/providers/entry_provider.dart';
import '../models/ai_scan_result_model.dart';
import '../models/scan_history_model.dart';
import '../models/trained_ai_result.dart';

final aiScanControllerProvider =
    StateNotifierProvider<AiScanController, AsyncValue<AiScanResultModel?>>((
      ref,
    ) {
      return AiScanController(
        ref: ref,
        aiRepo: ref.watch(aiScanRepositoryProvider),
        historyRepo: ref.watch(scanHistoryRepositoryProvider),
      );
    });

class AiScanController extends StateNotifier<AsyncValue<AiScanResultModel?>> {
  AiScanController({
    required this.ref,
    required this.aiRepo,
    required this.historyRepo,
  }) : super(const AsyncData(null));

  final Ref ref;
  final AiScanRepository aiRepo;
  final ScanHistoryRepository historyRepo;

  Future<AiScanResultModel?> startScan({
    required FarmModel farm,
    required BatchModel batch,
    required File imageFile,
    TrainedAiResult? trainedAiResult,
  }) async {
    try {
      state = const AsyncLoading();

      // Extract latest vaccine/medicine from the entry stream
      final entries =
          await ref.read(entriesStreamProvider((farmId: farm.id, batchId: batch.id)).future);

      final analytics = BatchAnalytics.fromEntries(entries, batch.totalBirds);

      final latestEntry = entries.isNotEmpty ? entries.first : null;
      final vaccination = latestEntry?.vaccination ?? '';
      final medicine = latestEntry?.medicine ?? '';

      // Analyze with Gemini
      final result = await aiRepo.analyzeImage(
        imageFile: imageFile,
        farmName: farm.name,
        batchName: batch.batchName,
        birdAge: batch.ageInDays,
        totalBirds: batch.totalBirds,
        avgWeight: analytics.latestAverageWeightKg,
        mortalityPercent: analytics.mortalityPercent,
        feedConsumed: analytics.totalFeedConsumedKg,
        waterConsumed: analytics.totalWaterConsumedLitres,
        temperature: analytics.latestTemperature,
        humidity: analytics.latestHumidity,
        vaccination: vaccination,
        medicine: medicine,
        trainedAiResult: trainedAiResult,
      );

      // Save to Scan History
      final scanId = historyRepo.generateScanId(farm.id, batch.id);
      
      String? imageUrl;
      try {
        imageUrl = await historyRepo.uploadScanImage(scanId, imageFile);
      } catch (e) {
        // Continue saving record even if image upload fails
      }

      final scanHistory = ScanHistoryModel(
        id: scanId,
        ownerId: '', // Added by repository
        farmId: farm.id,
        batchId: batch.id,
        farmName: farm.name,
        batchName: batch.batchName,
        imageUrl: imageUrl,
        result: result,
      );

      await historyRepo.addScanHistory(scanHistory);

      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
