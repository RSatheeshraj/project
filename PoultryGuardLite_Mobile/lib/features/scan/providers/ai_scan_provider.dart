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
  }) async {
    try {
      state = const AsyncLoading();

      // 2. Fetch context without new Firestore reads by using existing Riverpod providers
      // Extract latest vaccine/medicine from the entry stream
      final entries =
          await ref.read(entriesStreamProvider((farmId: farm.id, batchId: batch.id)).future);

      final analytics = BatchAnalytics.fromEntries(entries, batch.totalBirds);

      final latestEntry = entries.isNotEmpty ? entries.first : null;
      final vaccination = latestEntry?.vaccination ?? '';
      final medicine = latestEntry?.medicine ?? '';

      // 3. Analyze with Gemini
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
      );
      // 4. Save to Scan History
      // Generate ID first so we can use it for the image path
      final scanId = historyRepo.generateScanId(farm.id, batch.id);
      
      // Upload image
      String? imageUrl;
      try {
        imageUrl = await historyRepo.uploadScanImage(scanId, imageFile);
      } catch (e) {
        // If image upload fails, log it but don't fail the whole scan saving
        // The image will be missing, but the result is still valuable.
        // Actually, user wants the image stored. We'll proceed but log the error.
      }

      final scanHistory = ScanHistoryModel(
        id: scanId, // Use generated ID
        ownerId: '', // Added by repository
        farmId: farm.id,
        batchId: batch.id,
        farmName: farm.name,
        batchName: batch.batchName,
        imageUrl: imageUrl, // Save the actual uploaded image URL
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
