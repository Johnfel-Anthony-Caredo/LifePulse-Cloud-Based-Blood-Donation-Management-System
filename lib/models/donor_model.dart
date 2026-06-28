import 'package:amplify_flutter/amplify_flutter.dart';

enum BloodType {
  A_POSITIVE,
  A_NEGATIVE,
  B_POSITIVE,
  B_NEGATIVE,
  O_POSITIVE,
  O_NEGATIVE,
  AB_POSITIVE,
  AB_NEGATIVE,
}

class DonorModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final BloodType bloodType;
  final TemporalDate? lastDonation;
  final bool isEligible;
  final bool notificationsEnabled;
  final double? radiusKm;
  final TemporalDateTime? createdAt;
  final TemporalDateTime? updatedAt;

  DonorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.bloodType,
    this.lastDonation,
    required this.isEligible,
    required this.notificationsEnabled,
    this.radiusKm,
    this.createdAt,
    this.updatedAt,
  });

  /// Blood type display string
  String get bloodTypeDisplay {
    switch (bloodType) {
      case BloodType.A_POSITIVE:
        return 'A+';
      case BloodType.A_NEGATIVE:
        return 'A-';
      case BloodType.B_POSITIVE:
        return 'B+';
      case BloodType.B_NEGATIVE:
        return 'B-';
      case BloodType.O_POSITIVE:
        return 'O+';
      case BloodType.O_NEGATIVE:
        return 'O-';
      case BloodType.AB_POSITIVE:
        return 'AB+';
      case BloodType.AB_NEGATIVE:
        return 'AB-';
    }
  }

  /// Status based on eligibility
  String get status => isEligible ? 'Eligible' : 'Not Eligible';

  /// Last donation formatted
  String get lastDonationFormatted {
    if (lastDonation == null) return 'Never donated';
    final date = DateTime.parse(lastDonation!.format());
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  /// Convert to JSON for GraphQL mutations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'bloodType': _bloodTypeToGraphQL(bloodType),
      if (lastDonation != null) 'lastDonation': lastDonation!.format(),
      'isEligible': isEligible,
      'notificationsEnabled': notificationsEnabled,
      if (radiusKm != null) 'radiusKm': radiusKm,
    };
  }

  /// Create from JSON response
  factory DonorModel.fromJson(Map<String, dynamic> json) {
    return DonorModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      bloodType: _bloodTypeFromGraphQL(json['bloodType'] as String),
      lastDonation: json['lastDonation'] != null 
          ? TemporalDate.fromString(json['lastDonation'] as String)
          : null,
      isEligible: json['isEligible'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      radiusKm: json['radiusKm'] != null 
          ? (json['radiusKm'] as num).toDouble()
          : null,
      createdAt: json['createdAt'] != null
          ? TemporalDateTime.fromString(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? TemporalDateTime.fromString(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert local enum to GraphQL enum string (public for use in services)
  static String bloodTypeToGraphQL(BloodType type) {
    switch (type) {
      case BloodType.A_POSITIVE:
        return 'A_POSITIVE';
      case BloodType.A_NEGATIVE:
        return 'A_NEGATIVE';
      case BloodType.B_POSITIVE:
        return 'B_POSITIVE';
      case BloodType.B_NEGATIVE:
        return 'B_NEGATIVE';
      case BloodType.O_POSITIVE:
        return 'O_POSITIVE';
      case BloodType.O_NEGATIVE:
        return 'O_NEGATIVE';
      case BloodType.AB_POSITIVE:
        return 'AB_POSITIVE';
      case BloodType.AB_NEGATIVE:
        return 'AB_NEGATIVE';
    }
  }

  /// Private alias for backward compatibility
  static String _bloodTypeToGraphQL(BloodType type) => bloodTypeToGraphQL(type);

  /// Convert GraphQL enum string to local enum
  static BloodType _bloodTypeFromGraphQL(String type) {
    switch (type) {
      case 'A_POSITIVE':
        return BloodType.A_POSITIVE;
      case 'A_NEGATIVE':
        return BloodType.A_NEGATIVE;
      case 'B_POSITIVE':
        return BloodType.B_POSITIVE;
      case 'B_NEGATIVE':
        return BloodType.B_NEGATIVE;
      case 'O_POSITIVE':
        return BloodType.O_POSITIVE;
      case 'O_NEGATIVE':
        return BloodType.O_NEGATIVE;
      case 'AB_POSITIVE':
        return BloodType.AB_POSITIVE;
      case 'AB_NEGATIVE':
        return BloodType.AB_NEGATIVE;
      default:
        return BloodType.O_POSITIVE;
    }
  }

  /// Copy with updated fields
  DonorModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    BloodType? bloodType,
    TemporalDate? lastDonation,
    bool? isEligible,
    bool? notificationsEnabled,
    double? radiusKm,
  }) {
    return DonorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodType: bloodType ?? this.bloodType,
      lastDonation: lastDonation ?? this.lastDonation,
      isEligible: isEligible ?? this.isEligible,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      radiusKm: radiusKm ?? this.radiusKm,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static const classType = 'Donor';
}

class DonorModelModelIdentifier {
  final String id;

  const DonorModelModelIdentifier({required this.id});
}
