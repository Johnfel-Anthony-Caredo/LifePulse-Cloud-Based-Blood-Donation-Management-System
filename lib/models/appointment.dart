import 'dart:convert';

enum AppointmentStatus { upcoming, completed, cancelled }

class Appointment {
  final String id;
  final String hospitalId;
  final String hospitalName;
  final DateTime date;
  final String timeSlot;
  final AppointmentStatus status;
  final String? notes;

  Appointment({
    required this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.date,
    required this.timeSlot,
    this.status = AppointmentStatus.upcoming,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      hospitalId: json['hospitalId'],
      hospitalName: json['hospitalName'],
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AppointmentStatus.upcoming,
      ),
      notes: json['notes'],
    );
  }
}
