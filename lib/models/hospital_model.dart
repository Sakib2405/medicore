// lib/models/hospital_model.dart (Updated)
import 'package:cloud_firestore/cloud_firestore.dart';

class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int totalReviews;
  final String phoneNumber;
  final String website;
  final String type;
  final bool isOpen;
  final double distance;
  final List<String> services;
  final bool hasEmergency;
  final bool hasICU;
  final bool hasPharmacy;
  final bool hasAmbulance;
  final bool hasParking;
  final bool hasCafeteria;
  final Map<String, String> operatingHours;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.totalReviews,
    required this.phoneNumber,
    required this.website,
    required this.type,
    required this.isOpen,
    required this.distance,
    required this.services,
    required this.hasEmergency,
    required this.hasICU,
    required this.hasPharmacy,
    required this.hasAmbulance,
    required this.hasParking,
    required this.hasCafeteria,
    required this.operatingHours,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for Firestore
  factory Hospital.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final operatingHoursData =
        data['operatingHours'] as Map<String, dynamic>? ?? {};
    final operatingHours =
        operatingHoursData.map((key, value) => MapEntry(key, value.toString()));

    final servicesList = List<String>.from(data['services'] ?? []);

    return Hospital(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Hospital',
      address: data['address'] as String? ?? 'Address not available',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (data['totalReviews'] as int?) ?? 0,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      website: data['website'] as String? ?? '',
      type: data['type'] as String? ?? 'General Hospital',
      isOpen: data['isOpen'] as bool? ?? true,
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      services: servicesList,
      hasEmergency: data['hasEmergency'] as bool? ?? false,
      hasICU: data['hasICU'] as bool? ?? false,
      hasPharmacy: data['hasPharmacy'] as bool? ?? true,
      hasAmbulance: data['hasAmbulance'] as bool? ?? false,
      hasParking: data['hasParking'] as bool? ?? true,
      hasCafeteria: data['hasCafeteria'] as bool? ?? false,
      operatingHours: operatingHours,
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Utility methods and getters
  bool get isGeneralHospital => type.toLowerCase().contains('general');
  bool get isSpecializedHospital => type.toLowerCase().contains('special');
  bool get isClinic => type.toLowerCase().contains('clinic');

  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedDistance => '${distance.toStringAsFixed(1)} km';

  List<String> get availableServices {
    final available = <String>[];
    if (hasEmergency) available.add('Emergency');
    if (hasICU) available.add('ICU');
    if (hasPharmacy) available.add('Pharmacy');
    if (hasAmbulance) available.add('Ambulance');
    if (hasParking) available.add('Parking');
    if (hasCafeteria) available.add('Cafeteria');
    available.addAll(services);
    return available;
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalReviews': totalReviews,
      'phoneNumber': phoneNumber,
      'website': website,
      'type': type,
      'isOpen': isOpen,
      'distance': distance,
      'services': services,
      'hasEmergency': hasEmergency,
      'hasICU': hasICU,
      'hasPharmacy': hasPharmacy,
      'hasAmbulance': hasAmbulance,
      'hasParking': hasParking,
      'hasCafeteria': hasCafeteria,
      'operatingHours': operatingHours,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  String toString() {
    return 'Hospital(id: $id, name: $name, rating: $rating, distance: $distance km)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hospital && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
