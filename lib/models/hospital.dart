import 'dart:convert';

class Hospital {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final String? email;
  final String? imageUrl;
  final bool is24Hours;
  final String? operatingHours;
  final Map<String, int> bloodInventory; // Blood type -> units available
  final HospitalUrgency urgency;

  Hospital({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    this.email,
    this.imageUrl,
    required this.is24Hours,
    this.operatingHours,
    required this.bloodInventory,
    required this.urgency,
  });

  // Calculate total blood units
  int get totalUnits {
    return bloodInventory.values.fold(0, (sum, units) => sum + units);
  }

  // Get list of critically low blood types (<= 5 units)
  List<String> get criticalBloodTypes {
    return bloodInventory.entries
        .where((entry) => entry.value <= 5)
        .map((entry) => entry.key)
        .toList();
  }

  // Get list of low blood types (6-15 units)
  List<String> get lowBloodTypes {
    return bloodInventory.entries
        .where((entry) => entry.value > 5 && entry.value <= 15)
        .map((entry) => entry.key)
        .toList();
  }

  // Check if hospital should be marked as critical
  bool get isCritical {
    // Critical if total units <= 50 OR any blood type <= 5
    return totalUnits <= 50 || criticalBloodTypes.isNotEmpty;
  }

  // Get urgency color
  String get urgencyColor {
    switch (urgency) {
      case HospitalUrgency.critical:
        return '#DC143C'; // Red
      case HospitalUrgency.low:
        return '#FF8C42'; // Orange
      case HospitalUrgency.medium:
        return '#FCD34D'; // Yellow
      case HospitalUrgency.good:
        return '#10B981'; // Green
    }
  }

  // Get urgency label
  String get urgencyLabel {
    switch (urgency) {
      case HospitalUrgency.critical:
        return 'CRITICAL';
      case HospitalUrgency.low:
        return 'LOW STOCK';
      case HospitalUrgency.medium:
        return 'MEDIUM';
      case HospitalUrgency.good:
        return 'WELL STOCKED';
    }
  }

  /// Convert Hospital to JSON for GraphQL mutations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phone': phone,
      if (email != null) 'email': email,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'is24Hours': is24Hours,
      if (operatingHours != null) 'operatingHours': operatingHours,
      'bloodInventory': jsonEncode(bloodInventory), // Convert Map to JSON string for AWSJSON
      'urgency': _urgencyToGraphQL(urgency),
      'urgencyColor': urgencyColor,
    };
  }

  /// Create Hospital from JSON response
  factory Hospital.fromJson(Map<String, dynamic> json) {
    // Parse bloodInventory from AWSJSON string or Map
    Map<String, int> inventory = {};
    final bloodInvRaw = json['bloodInventory'];
    if (bloodInvRaw is String) {
      // Parse JSON string
      final parsed = Map<String, dynamic>.from(
        const JsonDecoder().convert(bloodInvRaw)
      );
      inventory = parsed.map((key, value) => MapEntry(key, value as int));
    } else if (bloodInvRaw is Map) {
      inventory = Map<String, int>.from(bloodInvRaw);
    }

    return Hospital(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      imageUrl: json['imageUrl'] as String?,
      is24Hours: json['is24Hours'] as bool? ?? false,
      operatingHours: json['operatingHours'] as String?,
      bloodInventory: inventory,
      urgency: _urgencyFromGraphQL(json['urgency'] as String),
    );
  }

  /// Convert local enum to GraphQL enum string
  static String _urgencyToGraphQL(HospitalUrgency urgency) {
    switch (urgency) {
      case HospitalUrgency.critical:
        return 'CRITICAL';
      case HospitalUrgency.low:
        return 'LOW';
      case HospitalUrgency.medium:
        return 'MEDIUM';
      case HospitalUrgency.good:
        return 'WELL_STOCKED';
    }
  }

  /// Convert GraphQL enum string to local enum
  static HospitalUrgency _urgencyFromGraphQL(String urgency) {
    switch (urgency) {
      case 'CRITICAL':
        return HospitalUrgency.critical;
      case 'LOW':
        return HospitalUrgency.low;
      case 'MEDIUM':
        return HospitalUrgency.medium;
      case 'WELL_STOCKED':
        return HospitalUrgency.good;
      default:
        return HospitalUrgency.medium;
    }
  }

  /// Create a copy with updated fields
  Hospital copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? phone,
    String? email,
    String? imageUrl,
    bool? is24Hours,
    String? operatingHours,
    Map<String, int>? bloodInventory,
    HospitalUrgency? urgency,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      is24Hours: is24Hours ?? this.is24Hours,
      operatingHours: operatingHours ?? this.operatingHours,
      bloodInventory: bloodInventory ?? this.bloodInventory,
      urgency: urgency ?? this.urgency,
    );
  }
}

enum HospitalUrgency {
  critical, // < 20% of normal stock
  low,      // 20-40%
  medium,   // 40-70%
  good,     // > 70%
}

// Sample hospital data for Davao Del Norte
class HospitalData {
  static List<Hospital> getDavaoDelNorteHospitals() {
    return [
      // Tagum City Hospitals
      Hospital(
        id: 'h001',
        name: 'Davao del Norte Provincial Hospital',
        latitude: 7.4475,
        longitude: 125.8078,
        address: 'New Visayas, Panabo City, Davao del Norte',
        phone: '+63 84 823 1234',
        imageUrl: 'https://example.com/hospitals/davao-del-norte.jpg',
        is24Hours: true,
        bloodInventory: {
          'A+': 8,
          'A-': 3,
          'B+': 5,
          'B-': 2,
          'O+': 12,
          'O-': 4,
          'AB+': 6,
          'AB-': 1,
        },
        urgency: HospitalUrgency.critical,
      ),
      
      Hospital(
        id: 'h002',
        name: 'Tagum Doctors Hospital',
        latitude: 7.4479,
        longitude: 125.8078,
        address: 'Pioneer Ave, Tagum City, Davao del Norte',
        phone: '+63 84 655 8888',
        bloodInventory: {
          'A+': 45,
          'A-': 15,
          'B+': 38,
          'B-': 12,
          'O+': 52,
          'O-': 18,
          'AB+': 25,
          'AB-': 8,
        },
        is24Hours: true,

        urgency: HospitalUrgency.good,
      ),

      Hospital(
        id: 'h003',
        name: 'Metro Tagum Medical Center',
        latitude: 7.4525,
        longitude: 125.8100,
        address: 'Apokon Road, Tagum City, Davao del Norte',
        phone: '+63 84 400 2345',
        bloodInventory: {
          'A+': 18,
          'A-': 7,
          'B+': 15,
          'B-': 5,
          'O+': 22,
          'O-': 8,
          'AB+': 12,
          'AB-': 3,
        },
        is24Hours: true,

        urgency: HospitalUrgency.low,
      ),

      // Panabo City Hospitals
      Hospital(
        id: 'h004',
        name: 'Panabo Polymedic General Hospital',
        latitude: 7.3072,
        longitude: 125.6839,
        address: 'Km 3, National Highway, Panabo City',
        phone: '+63 84 628 9999',
        bloodInventory: {
          'A+': 32,
          'A-': 11,
          'B+': 28,
          'B-': 9,
          'O+': 38,
          'O-': 13,
          'AB+': 19,
          'AB-': 6,
        },
        is24Hours: true,

        urgency: HospitalUrgency.medium,
      ),

      Hospital(
        id: 'h005',
        name: 'Panabo Medical Specialists Hospital',
        latitude: 7.3125,
        longitude: 125.6850,
        address: 'San Francisco, Panabo City, Davao del Norte',
        phone: '+63 84 823 4567',
        bloodInventory: {
          'A+': 9,
          'A-': 4,
          'B+': 7,
          'B-': 2,
          'O+': 11,
          'O-': 5,
          'AB+': 8,
          'AB-': 2,
        },
        is24Hours: true,

        urgency: HospitalUrgency.critical,
      ),

      // Island Garden City of Samal Hospitals
      Hospital(
        id: 'h006',
        name: 'Samal Island Community Hospital',
        latitude: 7.0731,
        longitude: 125.7103,
        address: 'Peñaplata, Island Garden City of Samal',
        phone: '+63 84 233 5678',
        bloodInventory: {
          'A+': 15,
          'A-': 6,
          'B+': 12,
          'B-': 4,
          'O+': 18,
          'O-': 7,
          'AB+': 10,
          'AB-': 3,
        },
        is24Hours: true,

        urgency: HospitalUrgency.low,
      ),

      // Kapalong Hospitals
      Hospital(
        id: 'h007',
        name: 'Kapalong District Hospital',
        latitude: 7.6167,
        longitude: 125.5333,
        address: 'Poblacion, Kapalong, Davao del Norte',
        phone: '+63 84 311 2345',
        bloodInventory: {
          'A+': 22,
          'A-': 8,
          'B+': 19,
          'B-': 6,
          'O+': 26,
          'O-': 9,
          'AB+': 14,
          'AB-': 4,
        },
        is24Hours: true,

        urgency: HospitalUrgency.medium,
      ),

      // Asuncion Hospitals
      Hospital(
        id: 'h008',
        name: 'Asuncion Community Hospital',
        latitude: 7.6167,
        longitude: 125.5500,
        address: 'Poblacion, Asuncion, Davao del Norte',
        phone: '+63 84 322 1234',
        bloodInventory: {
          'A+': 6,
          'A-': 2,
          'B+': 4,
          'B-': 1,
          'O+': 8,
          'O-': 3,
          'AB+': 5,
          'AB-': 1,
        },
        is24Hours: true,

        urgency: HospitalUrgency.critical,
      ),

      // New Corella Hospitals
      Hospital(
        id: 'h009',
        name: 'New Corella District Hospital',
        latitude: 7.5833,
        longitude: 125.8167,
        address: 'Poblacion, New Corella, Davao del Norte',
        phone: '+63 84 288 3456',
        bloodInventory: {
          'A+': 28,
          'A-': 10,
          'B+': 24,
          'B-': 8,
          'O+': 32,
          'O-': 11,
          'AB+': 17,
          'AB-': 5,
        },
        is24Hours: true,

        urgency: HospitalUrgency.medium,
      ),

      // Sto. Tomas Hospitals
      Hospital(
        id: 'h010',
        name: 'Sto. Tomas Medical Center',
        latitude: 7.5333,
        longitude: 125.6500,
        address: 'Poblacion, Sto. Tomas, Davao del Norte',
        phone: '+63 84 277 1234',
        bloodInventory: {
          'A+': 41,
          'A-': 14,
          'B+': 36,
          'B-': 11,
          'O+': 48,
          'O-': 16,
          'AB+': 23,
          'AB-': 7,
        },
        is24Hours: true,

        urgency: HospitalUrgency.good,
      ),

      // =================================================================
      // ADDITIONAL HOSPITALS ACROSS MINDANAO (10 more cities)
      // =================================================================

      // 1. Davao City - Southern Mindanao Medical Center
      Hospital(
        id: 'h011',
        name: 'Southern Philippines Medical Center',
        latitude: 7.0731,
        longitude: 125.6128,
        address: 'J.P. Laurel Ave, Davao City',
        phone: '+63 82 227 2731',
        bloodInventory: {
          'A+': 15,
          'A-': 4,
          'B+': 12,
          'B-': 2,
          'O+': 18,
          'O-': 3,
          'AB+': 8,
          'AB-': 1,
        },
        is24Hours: true,

        urgency: HospitalUrgency.low,
      ),

      // 2. Cagayan de Oro City - Northern Mindanao Medical Center
      Hospital(
        id: 'h012',
        name: 'Northern Mindanao Medical Center',
        latitude: 8.4542,
        longitude: 124.6319,
        address: 'Lapasan, Cagayan de Oro City',
        phone: '+63 88 856 1334',
        bloodInventory: {
          'A+': 8,
          'A-': 2,
          'B+': 6,
          'B-': 1,
          'O+': 11,
          'O-': 2,
          'AB+': 4,
          'AB-': 0,
        },
        is24Hours: true,

        urgency: HospitalUrgency.critical,
      ),

      // 3. General Santos City - General Santos Medical Center
      Hospital(
        id: 'h013',
        name: 'General Santos Medical Center',
        latitude: 6.1164,
        longitude: 125.1716,
        address: 'City Heights, General Santos City',
        phone: '+63 83 552 5777',
        bloodInventory: {
          'A+': 22,
          'A-': 7,
          'B+': 19,
          'B-': 5,
          'O+': 28,
          'O-': 9,
          'AB+': 14,
          'AB-': 3,
        },
        is24Hours: true,

        urgency: HospitalUrgency.medium,
      ),

      // 4. Butuan City - Butuan Medical Center
      Hospital(
        id: 'h014',
        name: 'Butuan Medical Center',
        latitude: 8.9475,
        longitude: 125.5406,
        address: 'Montilla Blvd, Butuan City',
        phone: '+63 85 342 5555',
        bloodInventory: {
          'A+': 38,
          'A-': 12,
          'B+': 33,
          'B-': 9,
          'O+': 45,
          'O-': 15,
          'AB+': 21,
          'AB-': 6,
        },
        is24Hours: true,

        urgency: HospitalUrgency.good,
      ),

      // 5. Iligan City - Iligan Medical Center
      Hospital(
        id: 'h015',
        name: 'Iligan Medical Center',
        latitude: 8.2280,
        longitude: 124.2453,
        address: 'Quezon Ave, Iligan City',
        phone: '+63 63 221 4888',
        bloodInventory: {
          'A+': 18,
          'A-': 5,
          'B+': 15,
          'B-': 3,
          'O+': 23,
          'O-': 6,
          'AB+': 11,
          'AB-': 2,
        },
        is24Hours: true,

        urgency: HospitalUrgency.medium,
      ),

      // 6. Zamboanga City - Zamboanga City Medical Center
      Hospital(
        id: 'h016',
        name: 'Zamboanga City Medical Center',
        latitude: 6.9214,
        longitude: 122.0790,
        address: 'Dr. Evangelista St, Zamboanga City',
        phone: '+63 62 991 2931',
        bloodInventory: {
          'A+': 12,
          'A-': 3,
          'B+': 9,
          'B-': 2,
          'O+': 16,
          'O-': 4,
          'AB+': 7,
          'AB-': 1,
        },
        is24Hours: true,

        urgency: HospitalUrgency.low,
      ),

      // 7. Cotabato City - Cotabato Regional Medical Center
      Hospital(
        id: 'h017',
        name: 'Cotabato Regional Medical Center',
        latitude: 7.2231,
        longitude: 124.2452,
        address: 'Sinsuat Ave, Cotabato City',
        phone: '+63 64 421 1564',
        bloodInventory: {
          'A+': 6,
          'A-': 1,
          'B+': 5,
          'B-': 0,
          'O+': 9,
          'O-': 1,
          'AB+': 3,
          'AB-': 0,
        },
        is24Hours: true,

        urgency: HospitalUrgency.critical,
      ),

      // 8. Surigao City - Surigao Medical Center
      Hospital(
        id: 'h018',
        name: 'Surigao Medical Center',
        latitude: 9.7871,
        longitude: 125.4951,
        address: 'San Juan St, Surigao City',
        phone: '+63 86 826 1234',
        bloodInventory: {
          'A+': 31,
          'A-': 10,
          'B+': 27,
          'B-': 8,
          'O+': 37,
          'O-': 12,
          'AB+': 18,
          'AB-': 5,
        },
        is24Hours: true,

        urgency: HospitalUrgency.medium,
      ),

      // 9. Dipolog City - Dipolog Medical Center
      Hospital(
        id: 'h019',
        name: 'Dipolog Medical Center',
        latitude: 8.5800,
        longitude: 123.3400,
        address: 'Rizal Ave, Dipolog City',
        phone: '+63 65 212 3456',
        bloodInventory: {
          'A+': 44,
          'A-': 15,
          'B+': 39,
          'B-': 12,
          'O+': 52,
          'O-': 17,
          'AB+': 26,
          'AB-': 8,
        },
        is24Hours: true,

        urgency: HospitalUrgency.good,
      ),

      // 10. Koronadal City - Koronadal Medical Center
      Hospital(
        id: 'h020',
        name: 'Koronadal Medical Center',
        latitude: 6.5000,
        longitude: 124.8500,
        address: 'General Santos Drive, Koronadal City',
        phone: '+63 83 228 4567',
        bloodInventory: {
          'A+': 25,
          'A-': 8,
          'B+': 21,
          'B-': 6,
          'O+': 30,
          'O-': 10,
          'AB+': 15,
          'AB-': 4,
        },
        is24Hours: true,

        urgency: HospitalUrgency.medium,
      ),
    ];
  }

  // Get center coordinates for Davao del Norte
  static Map<String, double> getDavaoDelNorteCenter() {
    return {
      'latitude': 7.4479,  // Centered around Tagum City
      'longitude': 125.8078,
    };
  }

  // Get bounds for Davao del Norte
  static Map<String, Map<String, double>> getDavaoDelNorteBounds() {
    return {
      'southwest': {
        'latitude': 6.9500,   // Southern boundary
        'longitude': 125.4000, // Western boundary
      },
      'northeast': {
        'latitude': 7.8500,   // Northern boundary
        'longitude': 126.1000, // Eastern boundary
      },
    };
  }
}


