import 'package:amplify_flutter/amplify_flutter.dart';
import 'donor_model.dart';

enum HospitalUrgency {
  CRITICAL,
  HIGH,
  MEDIUM,
  LOW,
  WELL_STOCKED,
}

enum RequestStatus {
  PENDING,
  FULFILLED,
  CANCELLED,
}

class BloodRequestModel {
  final String id;
  final String hospitalId;
  final BloodType bloodType;
  final int unitsNeeded;
  final HospitalUrgency urgency;
  final String patientName;
  final String? contactPerson;
  final String? contactPhone;
  final RequestStatus status;
  final String? notes;
  final TemporalDateTime? expiresAt;
  final TemporalDateTime? fulfilledAt;
  final String? createdBy;
  final TemporalDateTime? createdAt;
  final TemporalDateTime? updatedAt;

  // Optional related data (not from schema, for display)
  final String? hospitalName;

  BloodRequestModel({
    required this.id,
    required this.hospitalId,
    required this.bloodType,
    required this.unitsNeeded,
    required this.urgency,
    required this.patientName,
    this.contactPerson,
    this.contactPhone,
    required this.status,
    this.notes,
    this.expiresAt,
    this.fulfilledAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.hospitalName,
  });

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

  String get urgencyDisplay {
    switch (urgency) {
      case HospitalUrgency.CRITICAL:
        return 'Critical';
      case HospitalUrgency.HIGH:
        return 'High';
      case HospitalUrgency.MEDIUM:
        return 'Medium';
      case HospitalUrgency.LOW:
        return 'Low';
      case HospitalUrgency.WELL_STOCKED:
        return 'Well Stocked';
    }
  }

  String get statusDisplay {
    switch (status) {
      case RequestStatus.PENDING:
        return 'Pending';
      case RequestStatus.FULFILLED:
        return 'Fulfilled';
      case RequestStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  String get createdAtFormatted {
    if (createdAt == null) return 'N/A';
    final dt = DateTime.parse(createdAt!.format());
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.parse(expiresAt!.format()).isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final expiry = DateTime.parse(expiresAt!.format());
    final now = DateTime.now();
    final hoursUntilExpiry = expiry.difference(now).inHours;
    return hoursUntilExpiry > 0 && hoursUntilExpiry <= 24;
  }

  static HospitalUrgency urgencyFromString(String value) {
    switch (value) {
      case 'CRITICAL':
        return HospitalUrgency.CRITICAL;
      case 'HIGH':
        return HospitalUrgency.HIGH;
      case 'MEDIUM':
        return HospitalUrgency.MEDIUM;
      case 'LOW':
        return HospitalUrgency.LOW;
      case 'WELL_STOCKED':
        return HospitalUrgency.WELL_STOCKED;
      default:
        return HospitalUrgency.MEDIUM;
    }
  }

  static String urgencyToString(HospitalUrgency urgency) {
    return urgency.toString().split('.').last;
  }

  static RequestStatus statusFromString(String value) {
    switch (value) {
      case 'PENDING':
        return RequestStatus.PENDING;
      case 'FULFILLED':
        return RequestStatus.FULFILLED;
      case 'CANCELLED':
        return RequestStatus.CANCELLED;
      default:
        return RequestStatus.PENDING;
    }
  }

  static String statusToString(RequestStatus status) {
    return status.toString().split('.').last;
  }

  static BloodType _bloodTypeFromString(String value) {
    switch (value) {
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

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    return BloodRequestModel(
      id: json['id'] as String,
      hospitalId: json['hospitalId'] as String,
      bloodType: _bloodTypeFromString(json['bloodType'] as String),
      unitsNeeded: json['unitsNeeded'] as int,
      urgency: urgencyFromString(json['urgency'] as String),
      patientName: json['patientName'] as String,
      contactPerson: json['contactPerson'] as String?,
      contactPhone: json['contactPhone'] as String?,
      status: statusFromString(json['status'] as String),
      notes: json['notes'] as String?,
      expiresAt: json['expiresAt'] != null
          ? TemporalDateTime.fromString(json['expiresAt'] as String)
          : null,
      fulfilledAt: json['fulfilledAt'] != null
          ? TemporalDateTime.fromString(json['fulfilledAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? TemporalDateTime.fromString(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? TemporalDateTime.fromString(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospitalId': hospitalId,
      'bloodType': DonorModel.bloodTypeToGraphQL(bloodType),
      'unitsNeeded': unitsNeeded,
      'urgency': urgencyToString(urgency),
      'patientName': patientName,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (contactPhone != null) 'contactPhone': contactPhone,
      'status': statusToString(status),
      if (notes != null) 'notes': notes,
      if (expiresAt != null) 'expiresAt': expiresAt!.format(),
      if (fulfilledAt != null) 'fulfilledAt': fulfilledAt!.format(),
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  BloodRequestModel copyWith({
    String? id,
    String? hospitalId,
    BloodType? bloodType,
    int? unitsNeeded,
    HospitalUrgency? urgency,
    String? patientName,
    String? contactPerson,
    String? contactPhone,
    RequestStatus? status,
    String? notes,
    TemporalDateTime? expiresAt,
    TemporalDateTime? fulfilledAt,
    String? createdBy,
    TemporalDateTime? createdAt,
    TemporalDateTime? updatedAt,
    String? hospitalName,
  }) {
    return BloodRequestModel(
      id: id ?? this.id,
      hospitalId: hospitalId ?? this.hospitalId,
      bloodType: bloodType ?? this.bloodType,
      unitsNeeded: unitsNeeded ?? this.unitsNeeded,
      urgency: urgency ?? this.urgency,
      patientName: patientName ?? this.patientName,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      expiresAt: expiresAt ?? this.expiresAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }
}
