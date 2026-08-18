import 'package:cloud_firestore/cloud_firestore.dart';

import 'ai_scan_result_model.dart';

/// Represents a single AI disease scan record stored in Firestore.
///
/// Firestore path: `/scan_history/{scanId}`
class ScanHistoryModel {
  const ScanHistoryModel({
    required this.id,
    required this.ownerId,
    required this.farmId,
    required this.batchId,
    required this.farmName,
    required this.batchName,
    this.imageUrl,
    required this.result,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String farmId;
  final String batchId;
  final String farmName;
  final String batchName;
  final String? imageUrl;
  final AiScanResultModel result;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Serialization ─────────────────────────────────────────────────────────

  /// Serializes this model to a Firestore-compatible map.
  ///
  /// Server timestamps (`createdAt`, `updatedAt`) are intentionally excluded
  /// from this map — they are stamped by [ScanHistoryRepository] using
  /// [FieldValue.serverTimestamp()]. This keeps timestamp logic in the data
  /// layer and out of the model.
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'farmId': farmId,
      'batchId': batchId,
      'farmName': farmName,
      'batchName': batchName,
      'imageUrl': imageUrl,
      'result': result.toMap(),
    };
  }

  factory ScanHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return ScanHistoryModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      farmId: map['farmId'] as String? ?? '',
      batchId: map['batchId'] as String? ?? '',
      farmName: map['farmName'] as String? ?? 'Unknown Farm',
      batchName: map['batchName'] as String? ?? 'Unknown Batch',
      imageUrl: map['imageUrl'] as String?,
      result: AiScanResultModel.fromMap(
        map['result'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  ScanHistoryModel copyWith({
    String? id,
    String? ownerId,
    String? farmId,
    String? batchId,
    String? farmName,
    String? batchName,
    String? imageUrl,
    AiScanResultModel? result,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScanHistoryModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      farmName: farmName ?? this.farmName,
      batchName: batchName ?? this.batchName,
      imageUrl: imageUrl ?? this.imageUrl,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
