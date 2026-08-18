class VetModel {
  final String id;
  final String doctorName;
  final String clinicName;
  final String phoneNumber;
  final String email;
  final String address;
  final String website;
  final bool isAvailableForEmergency;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VetModel({
    required this.id,
    required this.doctorName,
    required this.clinicName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.website,
    required this.isAvailableForEmergency,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'clinicName': clinicName,
      'phoneNumber': phoneNumber,
      'whatsappNumber': phoneNumber,
      'email': email,
      'address': address,
      'website': website,
      'isEmergency': isAvailableForEmergency,
      'isAvailableForEmergency': isAvailableForEmergency,
      'notes': notes,
    };
  }

  factory VetModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VetModel(
      id: documentId,
      doctorName: map['doctorName'] ?? '',
      clinicName: map['clinicName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      website: map['website'] ?? '',
      isAvailableForEmergency: map['isAvailableForEmergency'] ?? map['isEmergency'] ?? false,
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as dynamic).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as dynamic).toDate() : null,
    );
  }

  VetModel copyWith({
    String? id,
    String? doctorName,
    String? clinicName,
    String? phoneNumber,
    String? email,
    String? address,
    String? website,
    bool? isAvailableForEmergency,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VetModel(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      isAvailableForEmergency:
          isAvailableForEmergency ?? this.isAvailableForEmergency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
