import 'package:amplify_flutter/amplify_flutter.dart';

class DonationHistoryModel {
  final String id;
  final String donorId;
  final String hospitalId;
  final TemporalDate donationDate;
  final String bloodType;
  final int unitsGiven;
  final String? notes;
  final TemporalDateTime createdAt;
  final TemporalDateTime updatedAt;

  DonationHistoryModel({
    required this.id,
    required this.donorId,
    required this.hospitalId,
    required this.donationDate,
    required this.bloodType,
    required this.unitsGiven,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DonationHistoryModel.fromJson(Map<String, dynamic> json) {
    return DonationHistoryModel(
      id: json['id'] as String,
      donorId: json['donorId'] as String,
      hospitalId: json['hospitalId'] as String,
      donationDate: TemporalDate.fromString(json['donationDate'] as String),
      bloodType: json['bloodType'] as String,
      unitsGiven: json['unitsGiven'] as int,
      notes: json['notes'] as String?,
      createdAt: TemporalDateTime.fromString(json['createdAt'] as String),
      updatedAt: TemporalDateTime.fromString(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'hospitalId': hospitalId,
      'donationDate': donationDate.format(),
      'bloodType': bloodType,
      'unitsGiven': unitsGiven,
      'notes': notes,
      'createdAt': createdAt.format(),
      'updatedAt': updatedAt.format(),
    };
  }

  String get bloodTypeDisplay {
    final Map<String, String> typeMap = {
      'A_POSITIVE': 'A+',
      'A_NEGATIVE': 'A-',
      'B_POSITIVE': 'B+',
      'B_NEGATIVE': 'B-',
      'AB_POSITIVE': 'AB+',
      'AB_NEGATIVE': 'AB-',
      'O_POSITIVE': 'O+',
      'O_NEGATIVE': 'O-',
    };
    return typeMap[bloodType] ?? bloodType;
  }

  String get donationDateFormatted {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final date = DateTime.parse(donationDate.format());
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
