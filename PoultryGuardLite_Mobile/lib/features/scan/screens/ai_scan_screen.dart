import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../app/router.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../flock/models/batch_model.dart';
import '../../flock/models/farm_model.dart';
import '../../flock/providers/batch_provider.dart';
import '../../flock/providers/farm_provider.dart';
import '../providers/ai_scan_provider.dart';
import '../providers/scan_history_provider.dart';
import '../services/trained_ai_model_service.dart';
import '../widgets/gemini_api_loading_dialog.dart';
import '../widgets/trained_ai_popup_dialog.dart';
import 'ai_result_screen.dart';

class AiScanScreen extends ConsumerStatefulWidget {
  const AiScanScreen({super.key});

  @override
  ConsumerState<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends ConsumerState<AiScanScreen> {
  FarmModel? _selectedFarm;
  BatchModel? _selectedBatch;

  Future<void> _startScan() async {
    if (_selectedFarm == null || _selectedBatch == null) {
      UiHelpers.showErrorDialog(
        context,
        'Please select a Farm and Batch first.',
      );
      return;
    }

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => ctx.pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => ctx.pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile == null) return;
    final imageFile = File(pickedFile.path);

    // ── 1. TRAINED AI MODEL (Image Analysis) ──────────────────────────────────
    final trainedResult = await TrainedAiModelService().analyzeImage(imageFile);

    if (!mounted) return;

    // ── 2. POPUP MESSAGE (SUCCESS ✓ / FAILED ✗) ──────────────────────────────
    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => TrainedAiPopupDialog(
        result: trainedResult,
        onContinue: () => Navigator.of(dialogCtx).pop(true),
      ),
    );

    if (shouldProceed != true || !mounted) return;

    // ── 3. GEMINI API (ALWAYS RUN) ────────────────────────────────────────────
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const GeminiApiLoadingDialog(),
    );

    final result = await ref
        .read(aiScanControllerProvider.notifier)
        .startScan(
          farm: _selectedFarm!,
          batch: _selectedBatch!,
          imageFile: imageFile,
          trainedAiResult: trainedResult,
        );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
    }

    // ── 4. FINAL RESULT (SHOW TO FARMER) ──────────────────────────────────────
    if (result != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => AiResultScreen(
              result: result,
              imageFile: imageFile,
              imageUrl: null,
              farmName: _selectedFarm!.name,
              batchName: _selectedBatch!.batchName,
            ),
          ),
        );
      }
    } else {
      final state = ref.read(aiScanControllerProvider);
      if (state.hasError && mounted) {
        String errorMsg = state.error.toString();
        if (errorMsg.contains('app_check') || 
            errorMsg.contains('attestation failed') || 
            errorMsg.contains('403')) {
          errorMsg = 'App verification failed. Please restart the app or verify the development App Check configuration.';
        }
        UiHelpers.showErrorDialog(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final farmsAsync = ref.watch(farmsStreamProvider);
    final historyAsync = ref.watch(scanHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Disease Scan')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector Section
              Text(
                'Select Context',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              farmsAsync.when(
                data: (farms) {
                  if (farms.isEmpty) {
                    return const Text('Add a farm first to use AI Scan.');
                  }
                  return DropdownButtonFormField<FarmModel>(
                    decoration: const InputDecoration(labelText: 'Farm'),
                    initialValue: farms.any((f) => f.id == _selectedFarm?.id)
                        ? farms.firstWhere((f) => f.id == _selectedFarm!.id)
                        : null,
                    items: farms
                        .map(
                          (f) =>
                              DropdownMenuItem(value: f, child: Text(f.name)),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedFarm = val;
                        _selectedBatch = null;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              if (_selectedFarm != null)
                Consumer(
                  builder: (context, ref, child) {
                    final batchesAsync = ref.watch(
                      batchesByFarmStreamProvider(_selectedFarm!.id),
                    );
                    return batchesAsync.when(
                      data: (batches) {
                        if (batches.isEmpty) {
                          return const Text('No batches in this farm.');
                        }
                        return DropdownButtonFormField<BatchModel>(
                          decoration: const InputDecoration(labelText: 'Batch'),
                          initialValue: batches.any((b) => b.id == _selectedBatch?.id)
                              ? batches.firstWhere(
                                  (b) => b.id == _selectedBatch!.id)
                              : null,
                          items: batches
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b.batchName),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedBatch = val);
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    );
                  },
                ),

              const SizedBox(height: 48),

              // 2. Scan Trigger Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer,
                      ),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        size: 64,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Disease Detection', style: tt.headlineSmall),
                    const SizedBox(height: 12),
                    Text(
                      'Upload a photo of bird droppings or affected areas to detect potential diseases instantly using Gemini Vision AI. The selected flock context is automatically included.',
                      style: tt.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Start Disease Detection'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // 3. Scan History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Scans',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              historyAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No past scans yet.',
                          style: tt.bodyMedium?.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isCritical =
                          item.result.severity.toLowerCase() == 'high' ||
                          item.result.severity.toLowerCase() == 'critical';
                      return ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        tileColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.history, color: Colors.grey),
                                ),
                        ),
                        title: Text(
                          item.result.diseaseName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item.farmName} • ${item.batchName}\n${item.createdAt != null ? DateFormat("MMM d, yyyy").format(item.createdAt!) : ''}',
                          style: tt.bodySmall,
                        ),
                        trailing: Icon(
                          Icons.warning_amber_rounded,
                          color: isCritical
                              ? Theme.of(context).colorScheme.error
                              : Colors.orange,
                        ),
                        onTap: () {
                          context.push(AppRoutes.scanDetails, extra: item);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading history: $e'),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
