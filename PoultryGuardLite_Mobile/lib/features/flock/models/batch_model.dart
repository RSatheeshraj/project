import 'package:cloud_firestore/cloud_firestore.dart';

class BatchModel {
  final String id;
  final String farmId;
  final String ownerId;
  final String batchName;
  final String birdType;
  final String breed;
  final int totalBirds;
  final int currentBirds;
  final String supplier;
  final DateTime? arrivalDate;
  final DateTime? expectedMarketDate;
  final String status;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BatchModel({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.batchName,
    required this.birdType,
    required this.breed,
    required this.totalBirds,
    required this.currentBirds,
    required this.supplier,
    this.arrivalDate,
    this.expectedMarketDate,
    required this.status,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  int get ageInDays {
    if (arrivalDate == null) return 0;
    final now = DateTime.now();
    return now.difference(arrivalDate!).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'farmId': farmId,
      'ownerId': ownerId,
      'batchName': batchName,
      'birdType': birdType,
      'breed': breed,
      'totalBirds': totalBirds,
      'currentBirds': currentBirds,
      'supplier': supplier,
      'arrivalDate': arrivalDate != null
          ? Timestamp.fromDate(arrivalDate!)
          : null,
      'expectedMarketDate': expectedMarketDate != null
          ? Timestamp.fromDate(expectedMarketDate!)
          : null,
      'status': status,
      'notes': notes,
    };
  }

  factory BatchModel.fromMap(Map<String, dynamic> map, String id) {
    return BatchModel(
      id: id,
      farmId: map['farmId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      batchName: map['batchName'] ?? '',
      birdType: map['birdType'] ?? '',
      breed: map['breed'] ?? '',
      totalBirds: map['totalBirds']?.toInt() ?? 0,
      currentBirds: map['currentBirds']?.toInt() ?? 0,
      supplier: map['supplier'] ?? '',
      arrivalDate: (map['arrivalDate'] as Timestamp?)?.toDate(),
      expectedMarketDate: (map['expectedMarketDate'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'Active',
      notes: map['notes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  BatchModel copyWith({
    String? id,
    String? farmId,
    String? ownerId,
    String? batchName,
    String? birdType,
    String? breed,
    int? totalBirds,
    int? currentBirds,
    String? supplier,
    DateTime? arrivalDate,
    DateTime? expectedMarketDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BatchModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      ownerId: ownerId ?? this.ownerId,
      batchName: batchName ?? this.batchName,
      birdType: birdType ?? this.birdType,
      breed: breed ?? this.breed,
      totalBirds: totalBirds ?? this.totalBirds,
      currentBirds: currentBirds ?? this.currentBirds,
      supplier: supplier ?? this.supplier,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      expectedMarketDate: expectedMarketDate ?? this.expectedMarketDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
