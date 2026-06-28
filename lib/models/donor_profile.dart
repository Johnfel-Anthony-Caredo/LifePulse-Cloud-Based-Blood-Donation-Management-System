import 'dart:convert';
import 'appointment.dart';

class DonorProfile {
  final String? name;
  final String? bloodType;
  final DateTime? lastDonation;
  final bool notificationsEnabled;
  final double radiusKm;
  final String? phone;
  final String? email;
  final List<Appointment> appointments;

  DonorProfile({
    this.name,
    this.bloodType,
    this.lastDonation,
    this.notificationsEnabled = true,
    this.radiusKm = 50.0,
    this.phone,
    this.email,
    this.appointments = const [],
  });

  // Check if donor is eligible to donate (3 months gap required)
  bool get isEligibleToDonate {
    if (lastDonation == null) return true;
    final daysSinceLastDonation = DateTime.now().difference(lastDonation!).inDays;
    return daysSinceLastDonation >= 90; // 3 months = 90 days
  }

  // Days until eligible
  int get daysUntilEligible {
    if (lastDonation == null) return 0;
    final daysSinceLastDonation = DateTime.now().difference(lastDonation!).inDays;
    final remaining = 90 - daysSinceLastDonation;
    return remaining > 0 ? remaining : 0;
  }

  // Weeks since last donation (for eligibility tracking)
  int get weeksSinceLastDonation {
    if (lastDonation == null) return 0;
    final daysSinceLastDonation = DateTime.now().difference(lastDonation!).inDays;
    return (daysSinceLastDonation / 7).floor();
  }

  // Progress percentage (0-100) for eligibility countdown
  double get eligibilityProgress {
    if (lastDonation == null) return 100.0;
    final daysSinceLastDonation = DateTime.now().difference(lastDonation!).inDays;
    if (daysSinceLastDonation >= 90) return 100.0;
    return (daysSinceLastDonation / 90) * 100;
  }

  // Get recovery message based on weeks since donation
  String get recoveryMessage {
    final weeks = weeksSinceLastDonation;
    if (weeks == 0) return '🩸 Rest well! Drink plenty of fluids today.';
    if (weeks <= 2) return '💧 Keep hydrating! Avoid heavy exercise.';
    if (weeks <= 4) return '💪 Eat iron-rich foods to rebuild your blood.';
    if (weeks <= 8) return '✨ Your body is recovering nicely!';
    if (weeks == 9) return '🎉 2 weeks until you can donate again!';
    if (weeks >= 12) return '🩸 You\'re ready to donate and save lives!';
    return '⏳ Almost ready! ${daysUntilEligible} days remaining.';
  }

  // Copy with method for updates
  DonorProfile copyWith({
    String? name,
    String? bloodType,
    DateTime? lastDonation,
    bool? notificationsEnabled,
    double? radiusKm,
    String? phone,
    String? email,
    List<Appointment>? appointments,
  }) {
    return DonorProfile(
      name: name ?? this.name,
      bloodType: bloodType ?? this.bloodType,
      lastDonation: lastDonation ?? this.lastDonation,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      radiusKm: radiusKm ?? this.radiusKm,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      appointments: appointments ?? this.appointments,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bloodType': bloodType,
      'lastDonation': lastDonation?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'radiusKm': radiusKm,
      'phone': phone,
      'email': email,
      'appointments': appointments.map((x) => x.toJson()).toList(),
    };
  }

  // Convert to JSON string for SharedPreferences
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create from JSON string
  factory DonorProfile.fromJsonString(String jsonString) {
    return DonorProfile.fromJson(jsonDecode(jsonString));
  }

  // Create from JSON
  factory DonorProfile.fromJson(Map<String, dynamic> json) {
    return DonorProfile(
      name: json['name'],
      bloodType: json['bloodType'],
      lastDonation: json['lastDonation'] != null
          ? DateTime.parse(json['lastDonation'])
          : null,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      radiusKm: json['radiusKm']?.toDouble() ?? 50.0,
      phone: json['phone'],
      email: json['email'],
      appointments: json['appointments'] != null
          ? (json['appointments'] as List)
              .map((x) => Appointment.fromJson(x))
              .toList()
          : [],
    );
  }
}
