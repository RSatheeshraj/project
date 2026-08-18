import 'package:cloud_firestore/cloud_firestore.dart';

class SalesModel {
  final String id;
  final String ownerId;
  final DateTime date;
  final int birdsSold;
  final double totalWeight;
  final double totalRevenue;
  final double averageWeight;
  final double pricePerKg;
  final String invoiceNumber;
  final String buyerName;
  final String notes;

  const SalesModel({
    required this.id,
    this.ownerId = '',
    required this.date,
    required this.birdsSold,
    required this.totalWeight,
    required this.totalRevenue,
    this.averageWeight = 0.0,
    this.pricePerKg = 0.0,
    this.invoiceNumber = '',
    required this.buyerName,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'date': Timestamp.fromDate(date),
      'birdsSold': birdsSold,
      'totalWeight': totalWeight,
      'totalRevenue': totalRevenue,
      'averageWeight': averageWeight,
      'pricePerKg': pricePerKg,
      'invoiceNumber': invoiceNumber,
      'buyerName': buyerName,
      'notes': notes,
    };
  }

  factory SalesModel.fromMap(Map<String, dynamic> map, String id) {
    return SalesModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      birdsSold: map['birdsSold']?.toInt() ?? 0,
      totalWeight: (map['totalWeight'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averageWeight: (map['averageWeight'] as num?)?.toDouble() ?? 0.0,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      invoiceNumber: map['invoiceNumber'] ?? '',
      buyerName: map['buyerName'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  SalesModel copyWith({
    String? id,
    String? ownerId,
    DateTime? date,
    int? birdsSold,
    double? totalWeight,
    double? totalRevenue,
    double? averageWeight,
    double? pricePerKg,
    String? invoiceNumber,
    String? buyerName,
    String? notes,
  }) {
    return SalesModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      date: date ?? this.date,
      birdsSold: birdsSold ?? this.birdsSold,
      totalWeight: totalWeight ?? this.totalWeight,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageWeight: averageWeight ?? this.averageWeight,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      buyerName: buyerName ?? this.buyerName,
      notes: notes ?? this.notes,
    );
  }
}
