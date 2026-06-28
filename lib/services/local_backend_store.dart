import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appointment_model.dart';
import '../models/blood_request_model.dart' as blood_request;
import '../models/donation_history_model.dart';
import '../models/donor_model.dart';
import '../models/hospital.dart';
import '../models/notification_model.dart';

class LocalBackendStore {
  static final LocalBackendStore instance = LocalBackendStore._();
  static const String _storageKey = 'dugo.local_backend.v1';

  LocalBackendStore._() {
    _seed();
  }

  final List<Hospital> hospitals = [];
  final List<DonorModel> donors = [];
  final List<AppointmentModel> appointments = [];
  final List<blood_request.BloodRequestModel> bloodRequests = [];
  final List<DonationHistoryModel> donationHistory = [];
  final List<NotificationModel> notifications = [];

  String currentUserId = 'local-admin';
  String currentEmail = 'admin@lifepulse.local';
  String currentName = 'LifePulse Admin';

  int _idCounter = 1000;
  bool _loadedFromDisk = false;

  Future<void> ensureLoaded() async {
    if (_loadedFromDisk) return;
    _loadedFromDisk = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      await persist();
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _restoreFromJson(decoded);
    } catch (error) {
      safePrint('Local backend restore failed, using seeded data: $error');
      _resetInMemory();
      await persist();
    }
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_toJson()));
  }

  Future<void> resetPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    _resetInMemory();
    _loadedFromDisk = true;
    await persist();
  }

  void _resetInMemory() {
    hospitals.clear();
    donors.clear();
    appointments.clear();
    bloodRequests.clear();
    donationHistory.clear();
    notifications.clear();
    currentUserId = 'local-admin';
    currentEmail = 'admin@lifepulse.local';
    currentName = 'LifePulse Admin';
    _idCounter = 1000;
    _seed();
  }

  String nextId(String prefix) {
    _idCounter += 1;
    return '$prefix-$_idCounter';
  }

  TemporalDateTime now() => TemporalDateTime(DateTime.now());

  void signIn({
    required String email,
    String? name,
  }) {
    currentEmail = email;
    currentName = name ?? _nameFromEmail(email);
    final matchingDonor = donors.where((donor) => donor.email == email);
    currentUserId = matchingDonor.isNotEmpty
        ? matchingDonor.first.userId
        : email.toLowerCase().contains('donor')
            ? 'local-user-${email.hashCode.abs()}'
            : 'local-admin';
  }

  void signOut() {
    currentUserId = 'local-admin';
    currentEmail = 'admin@lifepulse.local';
    currentName = 'LifePulse Admin';
  }

  DonorModel createOrUpdateDonorProfile({
    required String email,
    required String name,
    required String bloodType,
    String? phone,
  }) {
    final existing = donors.where((donor) => donor.email == email);
    if (existing.isNotEmpty) {
      currentUserId = existing.first.userId;
      return existing.first;
    }

    final donor = DonorModel(
      id: nextId('donor'),
      userId: currentUserId.startsWith('local-user')
          ? currentUserId
          : 'local-user-${email.hashCode.abs()}',
      name: name,
      email: email,
      phone: phone,
      bloodType: bloodTypeFromDisplay(bloodType),
      isEligible: true,
      notificationsEnabled: true,
      radiusKm: 10,
      createdAt: now(),
      updatedAt: now(),
    );
    donors.add(donor);
    currentUserId = donor.userId;
    return donor;
  }

  Map<String, dynamic> _toJson() {
    return {
      'version': 1,
      'idCounter': _idCounter,
      'currentUserId': currentUserId,
      'currentEmail': currentEmail,
      'currentName': currentName,
      'hospitals': hospitals.map((item) => item.toJson()).toList(),
      'donors': donors.map(_donorToJson).toList(),
      'appointments': appointments.map(_appointmentToJson).toList(),
      'bloodRequests': bloodRequests.map(_bloodRequestToJson).toList(),
      'donationHistory': donationHistory.map((item) => item.toJson()).toList(),
      'notifications': notifications.map((item) => item.toJson()).toList(),
    };
  }

  void _restoreFromJson(Map<String, dynamic> json) {
    hospitals
      ..clear()
      ..addAll(_decodeList(json['hospitals'], Hospital.fromJson));

    donors
      ..clear()
      ..addAll(_decodeList(json['donors'], DonorModel.fromJson));

    appointments
      ..clear()
      ..addAll(_decodeList(json['appointments'], AppointmentModel.fromJson));

    bloodRequests
      ..clear()
      ..addAll(_decodeList(
        json['bloodRequests'],
        blood_request.BloodRequestModel.fromJson,
      ));

    donationHistory
      ..clear()
      ..addAll(_decodeList(
        json['donationHistory'],
        DonationHistoryModel.fromJson,
      ));

    notifications
      ..clear()
      ..addAll(_decodeList(json['notifications'], NotificationModel.fromJson));

    if (hospitals.isEmpty) {
      _seed();
    }

    currentUserId = json['currentUserId'] as String? ?? 'local-admin';
    currentEmail = json['currentEmail'] as String? ?? 'admin@lifepulse.local';
    currentName = json['currentName'] as String? ?? 'LifePulse Admin';
    _idCounter = json['idCounter'] as int? ?? _nextCounterFromData();
  }

  List<T> _decodeList<T>(
    dynamic raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final items = raw is List ? raw : const [];
    return items
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  int _nextCounterFromData() {
    final ids = [
      ...hospitals.map((item) => item.id),
      ...donors.map((item) => item.id),
      ...appointments.map((item) => item.id),
      ...bloodRequests.map((item) => item.id),
      ...donationHistory.map((item) => item.id),
      ...notifications.map((item) => item.id),
    ];

    var maxId = 1000;
    for (final id in ids) {
      final match = RegExp(r'(\d+)$').firstMatch(id);
      if (match == null) continue;
      final value = int.tryParse(match.group(1)!);
      if (value != null && value > maxId) maxId = value;
    }
    return maxId;
  }

  Map<String, dynamic> _donorToJson(DonorModel donor) {
    return {
      ...donor.toJson(),
      if (donor.createdAt != null) 'createdAt': donor.createdAt!.format(),
      if (donor.updatedAt != null) 'updatedAt': donor.updatedAt!.format(),
    };
  }

  Map<String, dynamic> _appointmentToJson(AppointmentModel appointment) {
    return {
      ...appointment.toJson(),
      if (appointment.confirmedAt != null)
        'confirmedAt': appointment.confirmedAt!.format(),
      if (appointment.completedAt != null)
        'completedAt': appointment.completedAt!.format(),
      if (appointment.cancelledAt != null)
        'cancelledAt': appointment.cancelledAt!.format(),
      if (appointment.createdAt != null)
        'createdAt': appointment.createdAt!.format(),
      if (appointment.updatedAt != null)
        'updatedAt': appointment.updatedAt!.format(),
      if (appointment.donorName != null) 'donorName': appointment.donorName,
      if (appointment.hospitalName != null)
        'hospitalName': appointment.hospitalName,
    };
  }

  Map<String, dynamic> _bloodRequestToJson(
    blood_request.BloodRequestModel request,
  ) {
    return {
      ...request.toJson(),
      if (request.createdAt != null) 'createdAt': request.createdAt!.format(),
      if (request.updatedAt != null) 'updatedAt': request.updatedAt!.format(),
    };
  }

  BloodType bloodTypeFromDisplay(String value) {
    switch (value) {
      case 'A+':
      case 'A_POSITIVE':
        return BloodType.A_POSITIVE;
      case 'A-':
      case 'A_NEGATIVE':
        return BloodType.A_NEGATIVE;
      case 'B+':
      case 'B_POSITIVE':
        return BloodType.B_POSITIVE;
      case 'B-':
      case 'B_NEGATIVE':
        return BloodType.B_NEGATIVE;
      case 'O-':
      case 'O_NEGATIVE':
        return BloodType.O_NEGATIVE;
      case 'AB+':
      case 'AB_POSITIVE':
        return BloodType.AB_POSITIVE;
      case 'AB-':
      case 'AB_NEGATIVE':
        return BloodType.AB_NEGATIVE;
      case 'O+':
      case 'O_POSITIVE':
      default:
        return BloodType.O_POSITIVE;
    }
  }

  void _seed() {
    if (hospitals.isNotEmpty) return;

    hospitals.addAll(HospitalData.getDavaoDelNorteHospitals());

    donors.addAll([
      DonorModel(
        id: 'donor-001',
        userId: 'local-user-donor-001',
        name: 'Maria Santos',
        email: 'donor@lifepulse.local',
        phone: '+63 917 555 0101',
        bloodType: BloodType.O_POSITIVE,
        lastDonation: TemporalDate.fromString('2026-04-15'),
        isEligible: true,
        notificationsEnabled: true,
        radiusKm: 12,
        createdAt: now(),
        updatedAt: now(),
      ),
      DonorModel(
        id: 'donor-002',
        userId: 'local-user-donor-002',
        name: 'Juan Dela Cruz',
        email: 'juan@example.com',
        phone: '+63 918 555 0134',
        bloodType: BloodType.A_POSITIVE,
        isEligible: true,
        notificationsEnabled: true,
        radiusKm: 8,
        createdAt: now(),
        updatedAt: now(),
      ),
      DonorModel(
        id: 'donor-003',
        userId: 'local-user-donor-003',
        name: 'Ana Reyes',
        email: 'ana@example.com',
        phone: '+63 919 555 0199',
        bloodType: BloodType.AB_NEGATIVE,
        lastDonation: TemporalDate.fromString('2026-05-10'),
        isEligible: false,
        notificationsEnabled: true,
        radiusKm: 15,
        createdAt: now(),
        updatedAt: now(),
      ),
    ]);

    bloodRequests.addAll([
      blood_request.BloodRequestModel(
        id: 'request-001',
        hospitalId: 'h001',
        bloodType: BloodType.O_NEGATIVE,
        unitsNeeded: 4,
        urgency: blood_request.HospitalUrgency.CRITICAL,
        patientName: 'Emergency Case',
        contactPerson: 'Blood Bank Desk',
        contactPhone: '+63 84 823 1234',
        status: blood_request.RequestStatus.PENDING,
        notes: 'Local demo request seeded while AWS is offline.',
        expiresAt:
            TemporalDateTime(DateTime.now().add(const Duration(days: 2))),
        createdBy: 'local-admin',
        createdAt: now(),
        updatedAt: now(),
      ),
      blood_request.BloodRequestModel(
        id: 'request-002',
        hospitalId: 'h005',
        bloodType: BloodType.A_NEGATIVE,
        unitsNeeded: 2,
        urgency: blood_request.HospitalUrgency.HIGH,
        patientName: 'Scheduled Surgery',
        status: blood_request.RequestStatus.PENDING,
        createdBy: 'local-admin',
        createdAt: now(),
        updatedAt: now(),
      ),
    ]);

    appointments.addAll([
      AppointmentModel(
        id: 'appointment-001',
        donorId: 'donor-001',
        hospitalId: 'h001',
        appointmentDate: TemporalDateTime(
          DateTime.now().add(const Duration(days: 1, hours: 2)),
        ),
        bloodType: BloodType.O_POSITIVE,
        status: AppointmentStatus.SCHEDULED,
        notes: 'Demo appointment for urgent O+ support.',
        reminderSent: false,
        createdAt: now(),
        updatedAt: now(),
      ),
      AppointmentModel(
        id: 'appointment-002',
        donorId: 'donor-001',
        hospitalId: 'h005',
        appointmentDate: TemporalDateTime(
          DateTime.now().add(const Duration(days: 5, hours: 3)),
        ),
        bloodType: BloodType.O_POSITIVE,
        status: AppointmentStatus.CONFIRMED,
        notes: 'Confirmed by Panabo Medical Specialists Hospital.',
        reminderSent: false,
        confirmedAt: now(),
        createdAt: now(),
        updatedAt: now(),
      ),
      AppointmentModel(
        id: 'appointment-003',
        donorId: 'donor-001',
        hospitalId: 'h003',
        appointmentDate: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
        bloodType: BloodType.O_POSITIVE,
        status: AppointmentStatus.COMPLETED,
        notes: 'Completed local demo visit.',
        reminderSent: true,
        completedAt: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
        createdAt: now(),
        updatedAt: now(),
      ),
      AppointmentModel(
        id: 'appointment-004',
        donorId: 'donor-001',
        hospitalId: 'h011',
        appointmentDate: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
        bloodType: BloodType.O_POSITIVE,
        status: AppointmentStatus.CANCELLED,
        notes: 'Cancelled because the donor rescheduled.',
        reminderSent: false,
        cancelledAt: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 4)),
        ),
        cancellationReason: 'Rescheduled by donor',
        createdAt: now(),
        updatedAt: now(),
      ),
    ]);

    notifications.addAll([
      NotificationModel(
        id: 'notification-001',
        userId: 'local-user-donor-001',
        type: NotificationType.BLOOD_REQUEST,
        priority: NotificationPriority.URGENT,
        title: 'Urgent O- blood request nearby',
        message: 'Davao del Norte Provincial Hospital needs O- donors.',
        isRead: false,
        createdAt: now(),
        updatedAt: now(),
      ),
      NotificationModel(
        id: 'notification-002',
        userId: 'local-user-donor-001',
        type: NotificationType.APPOINTMENT_REMINDER,
        priority: NotificationPriority.HIGH,
        title: 'Appointment reminder',
        message: 'Your donation appointment is coming up tomorrow.',
        isRead: false,
        createdAt: TemporalDateTime(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
        updatedAt: now(),
      ),
      NotificationModel(
        id: 'notification-003',
        userId: 'local-user-donor-001',
        type: NotificationType.ELIGIBILITY_RESTORED,
        priority: NotificationPriority.MEDIUM,
        title: 'You are eligible to donate again',
        message:
            'Your recovery window has cleared. Nearby hospitals can now match with you.',
        isRead: true,
        readAt: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        createdAt: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
        updatedAt: now(),
      ),
      NotificationModel(
        id: 'notification-004',
        userId: 'local-user-donor-001',
        type: NotificationType.CAMPAIGN,
        priority: NotificationPriority.LOW,
        title: 'Weekend donor drive',
        message:
            'Tagum Doctors Hospital is hosting a donor drive this weekend.',
        isRead: true,
        readAt: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
        createdAt: TemporalDateTime(
          DateTime.now().subtract(const Duration(days: 4)),
        ),
        updatedAt: now(),
      ),
    ]);

    donationHistory.addAll([
      DonationHistoryModel(
        id: 'history-001',
        donorId: 'donor-001',
        hospitalId: 'h002',
        donationDate: TemporalDate.fromString('2026-04-15'),
        bloodType: 'O_POSITIVE',
        unitsGiven: 1,
        notes: 'Seed donation history',
        createdAt: now(),
        updatedAt: now(),
      ),
      DonationHistoryModel(
        id: 'history-002',
        donorId: 'donor-001',
        hospitalId: 'h003',
        donationDate: TemporalDate.fromString('2026-02-02'),
        bloodType: 'O_POSITIVE',
        unitsGiven: 1,
        notes: 'Follow-up donation for local demo data',
        createdAt: now(),
        updatedAt: now(),
      ),
      DonationHistoryModel(
        id: 'history-003',
        donorId: 'donor-001',
        hospitalId: 'h011',
        donationDate: TemporalDate.fromString('2025-11-20'),
        bloodType: 'O_POSITIVE',
        unitsGiven: 1,
        notes: 'Previous donation record',
        createdAt: now(),
        updatedAt: now(),
      ),
    ]);
  }

  String _nameFromEmail(String email) {
    final localPart = email.split('@').first.replaceAll('.', ' ');
    return localPart
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
