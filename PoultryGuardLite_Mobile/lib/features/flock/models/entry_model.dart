import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single weekly farm entry for a batch.
///
/// Firestore path: farms/{farmId}/batches/{batchId}/weekly_entries/{entryId}
class EntryModel {
  final String id;
  final String batchId;
  final String farmId;
  final String ownerId;
  final DateTime? entryDate;
  final int weekNumber;
  
  // Health & Consumption
  final double feedConsumedKg;
  final double waterConsumedLitres;
  final int mortalityCount;
  final double averageWeightKg;
  final double temperature;
  final double humidity;
  
  // Interventions
  final String vaccination;
  final String medicine;
  final DateTime? vaccinationDate;
  final DateTime? nextVaccinationDate;
  
  // Financial
  final double feedCost;
  final double medicineCost;
  final double labourCost;
  final double otherExpense;
  
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EntryModel({
    required this.id,
    required this.batchId,
    required this.farmId,
    required this.ownerId,
    this.entryDate,
    this.weekNumber = 0,
    required this.feedConsumedKg,
    required this.waterConsumedLitres,
    required this.mortalityCount,
    required this.averageWeightKg,
    required this.temperature,
    required this.humidity,
    required this.vaccination,
    required this.medicine,
    this.vaccinationDate,
    this.nextVaccinationDate,
    this.feedCost = 0.0,
    this.medicineCost = 0.0,
    this.labourCost = 0.0,
    this.otherExpense = 0.0,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'farmId': farmId,
      'ownerId': ownerId,
      'entryDate': entryDate != null ? Timestamp.fromDate(entryDate!) : null,
      'weekNumber': weekNumber,
      'feedConsumedKg': feedConsumedKg,
      'waterConsumedLitres': waterConsumedLitres,
      'mortalityCount': mortalityCount,
      'averageWeightKg': averageWeightKg,
      'temperature': temperature,
      'humidity': humidity,
      'vaccination': vaccination,
      'medicine': medicine,
      'vaccinationDate': vaccinationDate != null ? Timestamp.fromDate(vaccinationDate!) : null,
      'nextVaccinationDate': nextVaccinationDate != null ? Timestamp.fromDate(nextVaccinationDate!) : null,
      'feedCost': feedCost,
      'medicineCost': medicineCost,
      'labourCost': labourCost,
      'otherExpense': otherExpense,
      'notes': notes,
      // createdAt and updatedAt are handled by the repository
      // via FieldValue.serverTimestamp()
    };
  }

  factory EntryModel.fromMap(Map<String, dynamic> map, String id) {
    return EntryModel(
      id: id,
      batchId: map['batchId'] ?? '',
      farmId: map['farmId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      entryDate: (map['entryDate'] as Timestamp?)?.toDate(),
      weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 0,
      feedConsumedKg: (map['feedConsumedKg'] as num?)?.toDouble() ?? 0.0,
      waterConsumedLitres: (map['waterConsumedLitres'] as num?)?.toDouble() ?? 0.0,
      mortalityCount: (map['mortalityCount'] as num?)?.toInt() ?? 0,
      averageWeightKg: (map['averageWeightKg'] as num?)?.toDouble() ?? 0.0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      vaccination: map['vaccination'] ?? '',
      medicine: map['medicine'] ?? '',
      vaccinationDate: (map['vaccinationDate'] as Timestamp?)?.toDate(),
      nextVaccinationDate: (map['nextVaccinationDate'] as Timestamp?)?.toDate(),
      feedCost: (map['feedCost'] as num?)?.toDouble() ?? 0.0,
      medicineCost: (map['medicineCost'] as num?)?.toDouble() ?? 0.0,
      labourCost: (map['labourCost'] as num?)?.toDouble() ?? 0.0,
      otherExpense: (map['otherExpense'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  EntryModel copyWith({
    String? id,
    String? batchId,
    String? farmId,
    String? ownerId,
    DateTime? entryDate,
    int? weekNumber,
    double? feedConsumedKg,
    double? waterConsumedLitres,
    int? mortalityCount,
    double? averageWeightKg,
    double? temperature,
    double? humidity,
    String? vaccination,
    String? medicine,
    DateTime? vaccinationDate,
    DateTime? nextVaccinationDate,
    double? feedCost,
    double? medicineCost,
    double? labourCost,
    double? otherExpense,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EntryModel(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      farmId: farmId ?? this.farmId,
      ownerId: ownerId ?? this.ownerId,
      entryDate: entryDate ?? this.entryDate,
      weekNumber: weekNumber ?? this.weekNumber,
      feedConsumedKg: feedConsumedKg ?? this.feedConsumedKg,
      waterConsumedLitres: waterConsumedLitres ?? this.waterConsumedLitres,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      averageWeightKg: averageWeightKg ?? this.averageWeightKg,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      vaccination: vaccination ?? this.vaccination,
      medicine: medicine ?? this.medicine,
      vaccinationDate: vaccinationDate ?? this.vaccinationDate,
      nextVaccinationDate: nextVaccinationDate ?? this.nextVaccinationDate,
      feedCost: feedCost ?? this.feedCost,
      medicineCost: medicineCost ?? this.medicineCost,
      labourCost: labourCost ?? this.labourCost,
      otherExpense: otherExpense ?? this.otherExpense,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is EntryModel &&
      other.id == id &&
      other.batchId == batchId &&
      other.farmId == farmId &&
      other.ownerId == ownerId &&
      other.entryDate == entryDate &&
      other.weekNumber == weekNumber &&
      other.feedConsumedKg == feedConsumedKg &&
      other.waterConsumedLitres == waterConsumedLitres &&
      other.mortalityCount == mortalityCount &&
      other.averageWeightKg == averageWeightKg &&
      other.temperature == temperature &&
      other.humidity == humidity &&
      other.vaccination == vaccination &&
      other.medicine == medicine &&
      other.vaccinationDate == vaccinationDate &&
      other.nextVaccinationDate == nextVaccinationDate &&
      other.feedCost == feedCost &&
      other.medicineCost == medicineCost &&
      other.labourCost == labourCost &&
      other.otherExpense == otherExpense &&
      other.notes == notes &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      batchId.hashCode ^
      farmId.hashCode ^
      ownerId.hashCode ^
      entryDate.hashCode ^
      weekNumber.hashCode ^
      feedConsumedKg.hashCode ^
      waterConsumedLitres.hashCode ^
      mortalityCount.hashCode ^
      averageWeightKg.hashCode ^
      temperature.hashCode ^
      humidity.hashCode ^
      vaccination.hashCode ^
      medicine.hashCode ^
      vaccinationDate.hashCode ^
      nextVaccinationDate.hashCode ^
      feedCost.hashCode ^
      medicineCost.hashCode ^
      labourCost.hashCode ^
      otherExpense.hashCode ^
      notes.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}

