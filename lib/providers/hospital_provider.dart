// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:medicore/models/hospital_model.dart';

class HospitalProvider with ChangeNotifier {
  List<Hospital> _hospitals = [];
  List<Hospital> _filteredHospitals = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _locationError;
  Position? _currentPosition;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  // Search radius in metres — 60 km covers semi-rural and rural areas well
  static const int _searchRadiusMetres = 60000;

  List<Hospital> get hospitals => _filteredHospitals;
  List<Hospital> get allHospitals => _hospitals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get locationError => _locationError;
  Position? get currentPosition => _currentPosition;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get usingDefaultLocation => _locationError != null;

  static const List<String> _filterOptions = [
    'all', 'general', 'specialized', 'clinic', 'emergency', 'icu',
  ];
  List<String> get filterOptions => _filterOptions;

  Future<void> fetchNearbyHospitals() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _getCurrentLocation();

      final lat = _currentPosition!.latitude;
      final lon = _currentPosition!.longitude;

      // Overpass API — fetch hospitals/clinics within 60 km
      // timeout:60 matches our http timeout; we query nodes, ways, and relations
      final query = '''
[out:json][timeout:60];
(
  node["amenity"="hospital"](around:$_searchRadiusMetres,$lat,$lon);
  node["amenity"="clinic"](around:$_searchRadiusMetres,$lat,$lon);
  node["amenity"="doctors"](around:$_searchRadiusMetres,$lat,$lon);
  node["healthcare"="hospital"](around:$_searchRadiusMetres,$lat,$lon);
  node["healthcare"="clinic"](around:$_searchRadiusMetres,$lat,$lon);
  way["amenity"="hospital"](around:$_searchRadiusMetres,$lat,$lon);
  way["amenity"="clinic"](around:$_searchRadiusMetres,$lat,$lon);
  way["healthcare"="hospital"](around:$_searchRadiusMetres,$lat,$lon);
  relation["amenity"="hospital"](around:$_searchRadiusMetres,$lat,$lon);
);
out center tags;
''';

      final uri = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http
          .post(uri, body: {'data': query})
          .timeout(const Duration(seconds: 65));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>;

        final seen = <String>{};
        final parsed = <Hospital>[];
        for (final e in elements) {
          final h = _parseElement(e);
          if (h != null && seen.add('${h.latitude}_${h.longitude}')) {
            parsed.add(h);
          }
        }
        _hospitals = parsed;
      } else {
        _errorMessage =
            'Server error (${response.statusCode}). Try again later.';
      }

      await _calculateDistances();
      _applyFilters();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          'Failed to load hospitals. Check your internet connection.';
      notifyListeners();
      print('Error fetching hospitals: $e');
    }
  }

  Hospital? _parseElement(dynamic e) {
    try {
      final tags = e['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String? ?? tags['name:en'] as String?;
      if (name == null || name.isEmpty) return null;

      // nodes have lat/lon directly; ways have a center object
      final double lat = (e['lat'] as num?)?.toDouble() ??
          (e['center']?['lat'] as num?)?.toDouble() ??
          0;
      final double lon = (e['lon'] as num?)?.toDouble() ??
          (e['center']?['lon'] as num?)?.toDouble() ??
          0;
      if (lat == 0 && lon == 0) return null;

      final amenity = tags['amenity'] as String? ?? 'hospital';
      final type = amenity == 'hospital'
          ? 'General Hospital'
          : amenity == 'clinic'
              ? 'Clinic'
              : 'Medical Center';

      final phone = tags['phone'] as String? ??
          tags['contact:phone'] as String? ?? '';
      final website = tags['website'] as String? ??
          tags['contact:website'] as String? ?? '';
      final emergency = tags['emergency'] == 'yes';

      return Hospital(
        id: '${e['id']}',
        name: name,
        address: _buildAddress(tags),
        latitude: lat,
        longitude: lon,
        rating: 4.0,
        totalReviews: 0,
        phoneNumber: phone,
        website: website,
        type: type,
        isOpen: true,
        distance: 0,
        services: _buildServices(tags),
        hasEmergency: emergency,
        hasICU: tags['icu'] == 'yes',
        hasPharmacy: tags['pharmacy'] == 'yes',
        hasAmbulance: tags['amenity'] == 'hospital',
        hasParking: tags['parking'] != null,
        hasCafeteria: false,
        operatingHours: const {},
        imageUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[
      if (tags['addr:housenumber'] != null) tags['addr:housenumber'] as String,
      if (tags['addr:street'] != null) tags['addr:street'] as String,
      if (tags['addr:city'] != null) tags['addr:city'] as String,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Nearby';
  }

  List<String> _buildServices(Map<String, dynamic> tags) {
    final services = <String>[];
    if (tags['emergency'] == 'yes') services.add('Emergency');
    if (tags['icu'] == 'yes') services.add('ICU');
    if (tags['pharmacy'] == 'yes') services.add('Pharmacy');
    final speciality = tags['healthcare:speciality'] as String?;
    if (speciality != null) {
      services.addAll(speciality.split(';').map((s) => s.trim()));
    }
    if (services.isEmpty) services.add('General Medicine');
    return services;
  }

  Future<void> _getCurrentLocation() async {
    _locationError = null;
    try {
      // Check if location services are on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'location_service_disabled';
        _setDefaultPosition();
        return;
      }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _locationError = 'permission_denied_forever';
        _setDefaultPosition();
        return;
      }
      if (permission == LocationPermission.denied) {
        _locationError = 'permission_denied';
        _setDefaultPosition();
        return;
      }

      // Try last-known position first for speed, then get fresh position
      Position? pos;
      try {
        pos = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // Always get a fresh GPS fix (medium accuracy is fast enough)
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('getCurrentPosition failed, using last known: $e');
      }

      if (pos != null) {
        _currentPosition = pos;
      } else {
        _locationError = 'location_unavailable';
        _setDefaultPosition();
      }
    } catch (e) {
      print('Error getting location: $e');
      _locationError = 'location_unavailable';
      _setDefaultPosition();
    }
  }

  void _setDefaultPosition() {
    // Default to Dhaka, Bangladesh
    _currentPosition = Position(
      latitude: 23.8103,
      longitude: 90.4125,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<void> _calculateDistances() async {
    if (_currentPosition == null) return;
    for (int i = 0; i < _hospitals.length; i++) {
      final h = _hospitals[i];
      final d = _haversine(
        _currentPosition!.latitude, _currentPosition!.longitude,
        h.latitude, h.longitude,
      );
      _hospitals[i] = h.copyWith(distance: d);
    }
    _hospitals.sort((a, b) => a.distance.compareTo(b.distance));
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return double.parse((r * 2 * atan2(sqrt(a), sqrt(1 - a))).toStringAsFixed(1));
  }

  double _rad(double deg) => deg * (pi / 180);

  void searchHospitals(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void filterHospitals(String filter) {
    _selectedFilter = filter;
    _applyFilters();
  }

  void _applyFilters() {
    List<Hospital> filtered = _hospitals;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((h) =>
        h.name.toLowerCase().contains(_searchQuery) ||
        h.address.toLowerCase().contains(_searchQuery) ||
        h.type.toLowerCase().contains(_searchQuery)).toList();
    }
    if (_selectedFilter != 'all') {
      filtered = filtered.where((h) {
        switch (_selectedFilter) {
          case 'general': return h.isGeneralHospital;
          case 'specialized': return h.isSpecializedHospital;
          case 'clinic': return h.isClinic;
          case 'emergency': return h.hasEmergency;
          case 'icu': return h.hasICU;
          default: return true;
        }
      }).toList();
    }
    _filteredHospitals = filtered;
    notifyListeners();
  }

  List<Hospital> get topRatedHospitals =>
      _hospitals.where((h) => h.rating >= 4.0).toList();
  List<Hospital> get emergencyHospitals =>
      _hospitals.where((h) => h.hasEmergency).toList();
  List<Hospital> get nearestHospitals =>
      _hospitals.where((h) => h.distance <= 60.0).toList();

  Hospital? getHospitalById(String id) {
    try { return _hospitals.firstWhere((h) => h.id == id); } catch (_) { return null; }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedFilter = 'all';
    _applyFilters();
  }

  Future<void> refreshHospitals() => fetchNearbyHospitals();
  void clearError() { _errorMessage = null; notifyListeners(); }
}

extension _HospitalCopy on Hospital {
  Hospital copyWith({
    String? id, String? name, String? address,
    double? latitude, double? longitude,
    double? rating, int? totalReviews,
    String? phoneNumber, String? website, String? type,
    bool? isOpen, double? distance, List<String>? services,
    bool? hasEmergency, bool? hasICU, bool? hasPharmacy,
    bool? hasAmbulance, bool? hasParking, bool? hasCafeteria,
    Map<String, String>? operatingHours, String? imageUrl,
    DateTime? createdAt, DateTime? updatedAt,
  }) => Hospital(
    id: id ?? this.id, name: name ?? this.name,
    address: address ?? this.address,
    latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude,
    rating: rating ?? this.rating, totalReviews: totalReviews ?? this.totalReviews,
    phoneNumber: phoneNumber ?? this.phoneNumber, website: website ?? this.website,
    type: type ?? this.type, isOpen: isOpen ?? this.isOpen,
    distance: distance ?? this.distance, services: services ?? this.services,
    hasEmergency: hasEmergency ?? this.hasEmergency, hasICU: hasICU ?? this.hasICU,
    hasPharmacy: hasPharmacy ?? this.hasPharmacy, hasAmbulance: hasAmbulance ?? this.hasAmbulance,
    hasParking: hasParking ?? this.hasParking, hasCafeteria: hasCafeteria ?? this.hasCafeteria,
    operatingHours: operatingHours ?? this.operatingHours,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}
