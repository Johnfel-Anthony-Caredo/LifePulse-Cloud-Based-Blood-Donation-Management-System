import 'package:amplify_flutter/amplify_flutter.dart';
import 'donor_model.dart';

enum AppointmentStatus {
  SCHEDULED,
  CONFIRMED,
  COMPLETED,
  CANCELLED,
  NO_SHOW,
}

class AppointmentModel {
  final String id;
  final String donorId;
  final String hospitalId;
  final String? bloodRequestId;
  final TemporalDateTime appointmentDate;
  final BloodType bloodType;
  final AppointmentStatus status;
  final String? notes;
  final bool reminderSent;
  final TemporalDateTime? confirmedAt;
  final TemporalDateTime? completedAt;
  final TemporalDateTime? cancelledAt;
  final String? cancellationReason;
  final TemporalDateTime? createdAt;
  final TemporalDateTime? updatedAt;

  // Optional related data (not from schema, for display)
  final String? donorName;
  final String? hospitalName;

  AppointmentModel({
    required this.id,
    required this.donorId,
    required this.hospitalId,
    this.bloodRequestId,
    required this.appointmentDate,
    required this.bloodType,
    required this.status,
    this.notes,
    required this.reminderSent,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
    this.donorName,
    this.hospitalName,
  });

  String get statusDisplay {
    switch (status) {
      case AppointmentStatus.SCHEDULED:
        return 'Scheduled';
      case AppointmentStatus.CONFIRMED:
        return 'Confirmed';
      case AppointmentStatus.COMPLETED:
        return 'Completed';
      case AppointmentStatus.CANCELLED:
        return 'Cancelled';
      case AppointmentStatus.NO_SHOW:
        return 'No Show';
    }
  }

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

  String get appointmentDateFormatted {
    final dt = DateTime.parse(appointmentDate.format());
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get isPast {
    return DateTime.parse(appointmentDate.format()).isBefore(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    final apptDate = DateTime.parse(appointmentDate.format());
    return apptDate.year == now.year &&
        apptDate.month == now.month &&
        apptDate.day == now.day;
  }

  static AppointmentStatus statusFromString(String value) {
    switch (value) {
      case 'SCHEDULED':
        return AppointmentStatus.SCHEDULED;
      case 'CONFIRMED':
        return AppointmentStatus.CONFIRMED;
      case 'COMPLETED':
        return AppointmentStatus.COMPLETED;
      case 'CANCELLED':
        return AppointmentStatus.CANCELLED;
      case 'NO_SHOW':
        return AppointmentStatus.NO_SHOW;
      default:
        return AppointmentStatus.SCHEDULED;
    }
  }

  static String statusToString(AppointmentStatus status) {
    return status.toString().split('.').last;
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      donorId: json['donorId'] as String,
      hospitalId: json['hospitalId'] as String,
      bloodRequestId: json['bloodRequestId'] as String?,
      appointmentDate: TemporalDateTime.fromString(json['appointmentDate'] as String),
      bloodType: _bloodTypeFromString(json['bloodType'] as String),
      status: statusFromString(json['status'] as String),
      notes: json['notes'] as String?,
      reminderSent: json['reminderSent'] as bool? ?? false,
      confirmedAt: json['confirmedAt'] != null
          ? TemporalDateTime.fromString(json['confirmedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? TemporalDateTime.fromString(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? TemporalDateTime.fromString(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
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
      'donorId': donorId,
      'hospitalId': hospitalId,
      if (bloodRequestId != null) 'bloodRequestId': bloodRequestId,
      'appointmentDate': appointmentDate.format(),
      'bloodType': DonorModel.bloodTypeToGraphQL(bloodType),
      'status': statusToString(status),
      if (notes != null) 'notes': notes,
      'reminderSent': reminderSent,
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.format(),
      if (completedAt != null) 'completedAt': completedAt!.format(),
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.format(),
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
    };
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

  AppointmentModel copyWith({
    String? id,
    String? donorId,
    String? hospitalId,
    String? bloodRequestId,
    TemporalDateTime? appointmentDate,
    BloodType? bloodType,
    AppointmentStatus? status,
    String? notes,
    bool? reminderSent,
    TemporalDateTime? confirmedAt,
    TemporalDateTime? completedAt,
    TemporalDateTime? cancelledAt,
    String? cancellationReason,
    TemporalDateTime? createdAt,
    TemporalDateTime? updatedAt,
    String? donorName,
    String? hospitalName,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      hospitalId: hospitalId ?? this.hospitalId,
      bloodRequestId: bloodRequestId ?? this.bloodRequestId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      bloodType: bloodType ?? this.bloodType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reminderSent: reminderSent ?? this.reminderSent,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      donorName: donorName ?? this.donorName,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }
}
