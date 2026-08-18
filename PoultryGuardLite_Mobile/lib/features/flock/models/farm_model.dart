import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModel {
  final String id;
  final String name;
  final String type;
  final String ownerName;
  final String phone;
  final String address;
  final int sheds;
  final int capacity;
  final String notes;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FarmModel({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.sheds,
    required this.capacity,
    required this.notes,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'sheds': sheds,
      'capacity': capacity,
      'notes': notes,
      'ownerId': ownerId,
      // Note: createdAt and updatedAt are handled by the repository using FieldValue.serverTimestamp()
    };
  }

  factory FarmModel.fromMap(Map<String, dynamic> map, String id) {
    return FarmModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      ownerName: map['ownerName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      sheds: map['sheds']?.toInt() ?? 0,
      capacity: map['capacity']?.toInt() ?? 0,
      notes: map['notes'] ?? '',
      ownerId: map['ownerId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  FarmModel copyWith({
    String? id,
    String? name,
    String? type,
    String? ownerName,
    String? phone,
    String? address,
    int? sheds,
    int? capacity,
    String? notes,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      sheds: sheds ?? this.sheds,
      capacity: capacity ?? this.capacity,
      notes: notes ?? this.notes,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
